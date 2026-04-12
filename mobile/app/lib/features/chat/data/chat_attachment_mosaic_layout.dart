import 'package:lighchat_models/lighchat_models.dart';

/// Сжатый диапазон соотношений сторон, чтобы не ломать сетку при экзотических EXIF.
double mosaicAttachmentAspectRatio(ChatAttachment a) {
  final w = a.width;
  final h = a.height;
  if (w == null || h == null || w <= 0 || h <= 0) return 1.0;
  return (w / h).clamp(0.28, 3.5);
}

/// Структура рядов: каждый ряд — индексы в срезе [0..n) отображаемых вложений (n ≤ 9).
List<List<int>> mosaicRowIndices(int displayedCount) {
  final n = displayedCount;
  if (n <= 0) return const <List<int>>[];
  if (n == 1) return const <List<int>>[<int>[0]];
  if (n == 2) return const <List<int>>[<int>[0, 1]];
  if (n == 3) return const <List<int>>[<int>[0], <int>[1, 2]];
  if (n == 4) return const <List<int>>[<int>[0, 1], <int>[2, 3]];
  if (n == 5) return const <List<int>>[<int>[0, 1, 2], <int>[3, 4]];
  if (n == 6) return const <List<int>>[<int>[0, 1, 2], <int>[3, 4, 5]];
  if (n == 7) return const <List<int>>[<int>[0, 1, 2], <int>[3, 4], <int>[5, 6]];
  if (n == 8) return const <List<int>>[<int>[0, 1, 2], <int>[3, 4, 5], <int>[6, 7]];
  return const <List<int>>[<int>[0, 1, 2], <int>[3, 4, 5], <int>[6, 7, 8]];
}

/// Высота ряда с [cellCount] равными по ширине ячейками; одна высота на ряд (как Telegram).
double mosaicEqualCellRowHeight({
  required double rowMaxWidth,
  required int cellCount,
  required List<double> aspectRatios,
  required double gap,
  double minH = 56,
  double maxH = 240,
}) {
  if (cellCount <= 0) return minH;
  final w = (rowMaxWidth - (cellCount - 1) * gap) / cellCount;
  var h = 0.0;
  for (final r in aspectRatios) {
    final need = w / r;
    if (need > h) h = need;
  }
  if (h < minH) return minH;
  if (h > maxH) return maxH;
  return h;
}

/// Два вложения в один ряд: ширины пропорциональны aspect ratio, общая высота одна.
({double height, double w0, double w1}) mosaicTwoImageSizes({
  required double maxWidth,
  required double r0,
  required double r1,
  required double gap,
  double minH = 72,
  double maxH = 220,
}) {
  final inner = maxWidth - gap;
  var height = inner / (r0 + r1);
  if (height < minH) height = minH;
  if (height > maxH) height = maxH;
  var w0 = height * r0;
  var w1 = height * r1;
  final sum = w0 + w1;
  if (sum > inner + 1e-6) {
    final s = inner / sum;
    w0 *= s;
    w1 *= s;
  }
  return (height: height, w0: w0, w1: w1);
}

/// Одна плитка на всю ширину (верхний ряд при n=3).
double mosaicFullWidthRowHeight({
  required double maxWidth,
  required double aspectRatio,
  double minH = 72,
  double maxH = 220,
}) {
  return (maxWidth / aspectRatio).clamp(minH, maxH);
}
