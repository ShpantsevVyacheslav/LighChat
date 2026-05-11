import 'dart:async';
import 'dart:collection';

/// Приоритет загрузки в [MediaLoadScheduler]: чем выше, тем раньше получит
/// свободный слот. Видимые на экране тайлы — [high]; всё остальное — [low].
enum MediaLoadPriority { low, normal, high }

/// Талон на слот сетевой/тяжёлой загрузки. Возвращается из
/// [MediaLoadScheduler.enqueue]. Лимит параллелизма (по умолчанию 3) призван
/// не дать чату из 20+ медиа-сообщений одновременно запустить 20 сетевых
/// запросов и завесить UI.
abstract class MediaLoadTicket {
  /// Завершится, когда диспетчер выдал слот. Если талон отменён до выдачи
  /// слота — future завершается ошибкой [MediaLoadCancelled].
  Future<void> get granted;

  /// `true` после того, как слот выдан (между [granted] и [release]).
  bool get isGranted;

  /// `true` после явного [cancel] или [release].
  bool get isClosed;

  /// Поднять/опустить приоритет, пока талон в очереди. После выдачи слота
  /// вызов игнорируется (нельзя «приостановить» уже запущенную загрузку).
  void bumpPriority(MediaLoadPriority priority);

  /// Освободить слот по завершению работы. Идемпотентно.
  void release();

  /// Снять с очереди, если слот ещё не выдан. Если уже выдан — освобождает
  /// слот (как [release]). Идемпотентно.
  void cancel();
}

/// Ошибка, которой завершается [MediaLoadTicket.granted], если талон отменён
/// до получения слота. Вызывающий должен трактовать её как «загрузку не надо
/// стартовать» (тайл уехал из cache extent / пользователь отменил вручную).
class MediaLoadCancelled implements Exception {
  const MediaLoadCancelled();
  @override
  String toString() => 'MediaLoadCancelled';
}

/// Глобальный лимитер параллелизма загрузок медиа. Хранит N=[maxConcurrent]
/// «активных» талонов и очередь ожидающих, отсортированную по приоритету.
/// Подключается:
///   - в [ChatCachedNetworkImage] (картинки);
///   - в [VideoUrlFirstFrameCache] (первый кадр видео);
///   - в [MessageVideoAttachment] (сам VideoPlayerController).
///
/// При `bumpPriority(high)` ожидающий талон поднимается в начало очереди —
/// так визуально видимые тайлы дотягиваются раньше прокрученных мимо.
class MediaLoadScheduler {
  MediaLoadScheduler({this.maxConcurrent = 3});

  final int maxConcurrent;
  int _running = 0;
  final Queue<_Ticket> _pending = Queue<_Ticket>();

  static final MediaLoadScheduler instance = MediaLoadScheduler();

  MediaLoadTicket enqueue({
    MediaLoadPriority priority = MediaLoadPriority.low,
  }) {
    final t = _Ticket._(this, priority);
    if (_running < maxConcurrent) {
      _running++;
      t._markGranted();
      return t;
    }
    _pending.add(t);
    _resort();
    return t;
  }

  void _resort() {
    if (_pending.length < 2) return;
    final sorted = _pending.toList()
      ..sort((a, b) {
        final byPrio = b.priority.index.compareTo(a.priority.index);
        if (byPrio != 0) return byPrio;
        return a._seq.compareTo(b._seq);
      });
    _pending
      ..clear()
      ..addAll(sorted);
  }

  void _release(_Ticket t) {
    if (!t._wasRunning) return;
    t._wasRunning = false;
    _running--;
    while (_pending.isNotEmpty && _running < maxConcurrent) {
      final next = _pending.removeFirst();
      _running++;
      next._markGranted();
    }
  }

  void _drop(_Ticket t) {
    _pending.remove(t);
  }
}

int _seqGen = 0;

class _Ticket implements MediaLoadTicket {
  _Ticket._(this._scheduler, this._priority)
      : _seq = _seqGen++,
        _completer = Completer<void>();

  final MediaLoadScheduler _scheduler;
  final Completer<void> _completer;
  final int _seq;
  MediaLoadPriority _priority;
  bool _granted = false;
  bool _wasRunning = false;
  bool _closed = false;

  MediaLoadPriority get priority => _priority;

  @override
  Future<void> get granted => _completer.future;

  @override
  bool get isGranted => _granted;

  @override
  bool get isClosed => _closed;

  void _markGranted() {
    _granted = true;
    _wasRunning = true;
    if (!_completer.isCompleted) _completer.complete();
  }

  @override
  void bumpPriority(MediaLoadPriority priority) {
    if (_closed || _granted) return;
    if (_priority == priority) return;
    _priority = priority;
    _scheduler._resort();
  }

  @override
  void release() {
    if (_closed) return;
    _closed = true;
    if (_granted) {
      _scheduler._release(this);
    } else {
      _scheduler._drop(this);
      if (!_completer.isCompleted) {
        _completer.completeError(const MediaLoadCancelled());
      }
    }
  }

  @override
  void cancel() => release();
}
