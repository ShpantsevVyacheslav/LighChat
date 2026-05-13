import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lighchat_mobile/core/app_logger.dart';

import '../../../l10n/app_localizations.dart';
import '../../../platform/native_nav_bar/nav_bar_config.dart';
import '../../../platform/native_nav_bar/native_nav_bar_facade.dart';
import '../../../platform/native_nav_bar/native_nav_route_observer.dart';
import 'chat_avatar.dart';

class ChatHeader extends StatefulWidget {
  const ChatHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.avatarUrl,
    required this.onBack,
    required this.showCalls,
    required this.onThreadsTap,
    this.threadsUnreadCount = 0,
    required this.onSearchTap,
    required this.onVideoCallTap,
    required this.onAudioCallTap,
    this.onProfileTap,
    this.searchActive = false,
    this.searchController,
    this.searchFocusNode,
    this.onSearchClose,
    this.scheduledCount = 0,
    this.onScheduledTap,
    this.disappearingMessagesEnabled = false,
    this.stickersPanelOpen = false,
  });

  /// При открытой шторке стикеров скрываем native header целиком,
  /// чтобы он не перекрывал стикер-композер и список паков. Без
  /// этого пилюлю было «прибито» сверху, под ней закрепительная и
  /// search-фильд стикеров уезжали в недоступную zone.
  final bool stickersPanelOpen;

  final String title;
  final String subtitle;
  final String? avatarUrl;
  final VoidCallback onBack;
  final bool showCalls;
  final VoidCallback onThreadsTap;

  /// Сумма непрочитанных по веткам (`conversations.unreadThreadCounts[currentUser]`).
  final int threadsUnreadCount;
  final VoidCallback onSearchTap;
  final VoidCallback onVideoCallTap;
  final VoidCallback onAudioCallTap;
  final VoidCallback? onProfileTap;

  /// Режим поиска по сообщениям (как шапка веб-чата).
  final bool searchActive;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final VoidCallback? onSearchClose;

  /// Количество запланированных сообщений текущего пользователя в этом чате.
  /// Иконка-будильник в шапке появляется только если > 0.
  final int scheduledCount;
  final VoidCallback? onScheduledTap;

  /// Включён ли в чате таймер исчезающих сообщений
  /// (`conversations.disappearingMessageTtlSec` > 0). Тогда рядом с названием
  /// показываем иконку-пламя (паттерн как в Telegram).
  final bool disappearingMessagesEnabled;

  @override
  State<ChatHeader> createState() => _ChatHeaderState();
}

class _ChatHeaderState extends State<ChatHeader> with RouteAware {
  StreamSubscription<NavBarEvent>? _nativeEvents;
  bool _firstPushDone = false;
  bool _routeSubscribed = false;
  bool get _native => NativeNavBarFacade.instance.isSupported;

  static const _actionSearch = 'chat_search';
  static const _actionVideo = 'chat_video';
  static const _actionAudio = 'chat_audio';
  static const _actionThreads = 'chat_threads';
  static const _actionScheduled = 'chat_scheduled';
  // Специальный id — native сторона шлёт его при тапе на avatar / title /
  // subtitle (custom titleView). Маппится на widget.onProfileTap.
  static const _actionTitleTap = '_chat_title_tap';

  @override
  void initState() {
    super.initState();
    if (_native) {
      _nativeEvents =
          NativeNavBarFacade.instance.events.listen(_onNativeEvent);
      widget.searchController?.addListener(_syncSearchValue);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_native && !_firstPushDone) {
      _firstPushDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Первый push: chat_screen только что mount'нулся — точно вершина.
        if (mounted) _pushNativeTopBar(force: true);
      });
    }
    if (_native && !_routeSubscribed) {
      final route = ModalRoute.of(context);
      if (route is ModalRoute<Object?>) {
        nativeNavRouteObserver.subscribe(this, route);
        _routeSubscribed = true;
      }
    }
  }

  @override
  void didUpdateWidget(covariant ChatHeader old) {
    super.didUpdateWidget(old);
    if (_native) {
      if (old.searchController != widget.searchController) {
        old.searchController?.removeListener(_syncSearchValue);
        widget.searchController?.addListener(_syncSearchValue);
      }
      _pushNativeTopBar();
    }
  }

  @override
  void dispose() {
    widget.searchController?.removeListener(_syncSearchValue);
    _nativeEvents?.cancel();
    if (_native) {
      if (_routeSubscribed) {
        nativeNavRouteObserver.unsubscribe(this);
      }
      // Search-режим всегда чистим, иначе UISearchBar мог остаться в
      // titleView от прошлого экрана. Top bar hide делает observer на
      // переходе — здесь не дублируем, иначе hide прилетит после
      // initState нового экрана (race с анимацией transition).
      unawaited(
        NativeNavBarFacade.instance.setSearchMode(
          const NavBarSearchConfig.inactive(),
        ),
      );
    }
    super.dispose();
  }

  // RouteAware: при возврате на chat_screen пушим конфиг заново.
  // Hide при push'е другого экрана сверху делает observer.

  @override
  void didPopNext() {
    // didPopNext означает, что верхний экран pop'нулся — мы точно
    // владельцы. Pump-им конфиг без isCurrent-guard'а (он бы отсёк push
    // во время незавершённой transition-анимации).
    if (_native) _pushNativeTopBar(force: true);
  }

  void _pushNativeTopBar({bool force = false}) {
    // Без force пушим только когда chat_screen реально вершина стека.
    //   * route == null  — экран уже popped, ещё не успел дисповнуться
    //     (back-транзишен ~300ms); если push'нуть здесь, шапка чата
    //     вспыхнет на списке диалогов.
    //   * isCurrent == false — поверх открыт threads / profile / settings.
    // initState / didPopNext знают, что владеют шапкой → force=true,
    // минуя guard (route.isCurrent может ещё быть false во время transition).
    if (!force) {
      final route = ModalRoute.of(context);
      if (route?.isCurrent != true) {
        appLogger.d(
          '[chat-header] skip push: route.isCurrent=${route?.isCurrent}',
        );
        return;
      }
    }
    appLogger.d(
      '[chat-header] push title="${widget.title}" '
      'avatarUrl=${widget.avatarUrl == null ? "<null>" : "<set,len=${widget.avatarUrl!.length}>"} '
      'searchActive=${widget.searchActive} force=$force',
    );

    final l10n = AppLocalizations.of(context);
    // Компактный набор трейлинг-actions: показываем только реально
    // активные (threads/scheduled — только при наличии). Иначе шапка
    // переполняется и avatar+title не помещается.
    // Порядок: search, threads, audio, video, scheduled (по запросу).
    // Threads (обсуждения) теперь сразу после поиска — самая частая
    // вторичная команда после поиска.
    final actions = <NavBarAction>[
      NavBarAction(
        id: _actionSearch,
        icon: const NavBarIcon('magnifyingglass'),
        title: l10n?.chat_header_tooltip_search,
      ),
      NavBarAction(
        id: _actionThreads,
        icon: const NavBarIcon('bubble.left.and.bubble.right'),
        badge: widget.threadsUnreadCount > 0
            ? widget.threadsUnreadCount.toString()
            : null,
        title: l10n?.chat_header_tooltip_threads,
      ),
      if (widget.showCalls)
        NavBarAction(
          id: _actionAudio,
          icon: const NavBarIcon('phone.fill'),
          title: l10n?.chat_header_tooltip_audio_call,
        ),
      if (widget.showCalls)
        NavBarAction(
          id: _actionVideo,
          icon: const NavBarIcon('video.fill'),
          title: l10n?.chat_header_tooltip_video_call,
        ),
      if (widget.scheduledCount > 0 && widget.onScheduledTap != null)
        NavBarAction(
          id: _actionScheduled,
          icon: const NavBarIcon('clock'),
          badge: widget.scheduledCount.toString(),
          title: l10n?.chat_header_tooltip_scheduled,
        ),
    ];

    final initial = widget.title.isNotEmpty
        ? widget.title.characters.first.toUpperCase()
        : null;

    // При открытой шторке стикеров полностью прячем native шапку чата.
    // Stickers panel — модальная UX-зона: показ search-фильтра стикеров,
    // фрейм списка паков. Если native pill висит сверху, он перекрывает
    // search-input и мешает.
    final config = widget.stickersPanelOpen
        ? const NavBarTopConfig.hidden()
        : NavBarTopConfig(
            title: NavBarTitle(
              title: widget.title,
              subtitle: widget.subtitle.isEmpty ? null : widget.subtitle,
              avatarUrl: widget.avatarUrl,
              avatarFallbackInitial: initial,
            ),
            leading: const NavBarLeading.back(id: 'chat_back'),
            trailing: actions,
          );

    unawaited(NativeNavBarFacade.instance.setTopBar(config));
    unawaited(
      NativeNavBarFacade.instance.setSearchMode(
        widget.searchActive
            ? NavBarSearchConfig(
                active: true,
                placeholder: l10n?.chat_header_search_hint ?? '',
                value: widget.searchController?.text ?? '',
              )
            : const NavBarSearchConfig.inactive(),
      ),
    );
  }

  void _syncSearchValue() {
    if (!_native) return;
    if (!widget.searchActive) return;
    // Тот же guard, что и в _pushNativeTopBar — не дёргаем search при
    // ребилдах когда chat_screen не вершина.
    final route = ModalRoute.of(context);
    if (route?.isCurrent != true) return;
    final l10n = AppLocalizations.of(context);
    unawaited(
      NativeNavBarFacade.instance.setSearchMode(
        NavBarSearchConfig(
          active: true,
          placeholder: l10n?.chat_header_search_hint ?? '',
          value: widget.searchController?.text ?? '',
        ),
      ),
    );
  }

  void _onNativeEvent(NavBarEvent event) {
    if (!mounted) return;
    switch (event) {
      case NavBarLeadingTap(:final id):
        if (id == 'chat_back') widget.onBack();
      case NavBarActionTap(:final id):
        switch (id) {
          case _actionSearch:
            widget.onSearchTap();
          case _actionVideo:
            widget.onVideoCallTap();
          case _actionAudio:
            widget.onAudioCallTap();
          case _actionThreads:
            widget.onThreadsTap();
          case _actionScheduled:
            widget.onScheduledTap?.call();
          case _actionTitleTap:
            widget.onProfileTap?.call();
        }
      case NavBarSearchChange(:final value):
        final controller = widget.searchController;
        if (controller != null && controller.text != value) {
          controller.text = value;
        }
      case NavBarSearchCancel():
        widget.onSearchClose?.call();
      case NavBarSearchSubmit():
      case NavBarTabChange():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_native) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final fg = Colors.white.withValues(alpha: 0.96);

    final searchActive = widget.searchActive;
    final searchController = widget.searchController;
    final searchFocusNode = widget.searchFocusNode;
    final onSearchClose = widget.onSearchClose;
    final onBack = widget.onBack;
    final onProfileTap = widget.onProfileTap;
    final title = widget.title;
    final subtitle = widget.subtitle;
    final avatarUrl = widget.avatarUrl;
    final disappearingMessagesEnabled = widget.disappearingMessagesEnabled;
    final threadsUnreadCount = widget.threadsUnreadCount;
    final onThreadsTap = widget.onThreadsTap;
    final onSearchTap = widget.onSearchTap;
    final scheduledCount = widget.scheduledCount;
    final onScheduledTap = widget.onScheduledTap;
    final showCalls = widget.showCalls;
    final onVideoCallTap = widget.onVideoCallTap;
    final onAudioCallTap = widget.onAudioCallTap;

    if (searchActive &&
        searchController != null &&
        searchFocusNode != null &&
        onSearchClose != null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.partner_profile_tooltip_back,
              onPressed: onSearchClose,
              color: fg,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: searchController,
                builder: (context, _) {
                  final q = searchController.text;
                  return TextField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    cursorColor: fg,
                    decoration: InputDecoration(
                      hintText: l10n.chat_header_search_hint,
                      hintStyle: TextStyle(color: fg.withValues(alpha: 0.50)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      isDense: true,
                      suffixIcon: q.isNotEmpty
                          ? IconButton(
                              tooltip: l10n.thread_search_tooltip_clear,
                              onPressed: searchController.clear,
                              icon: Icon(
                                Icons.close_rounded,
                                color: fg.withValues(alpha: 0.7),
                                size: 19,
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    Widget iconButton({
      required IconData icon,
      required VoidCallback onTap,
      required String tooltip,
    }) {
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: IconButton(
            tooltip: tooltip,
            onPressed: onTap,
            iconSize: 18,
            color: fg,
            padding: EdgeInsets.zero,
            icon: Icon(icon),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.partner_profile_tooltip_back,
            onPressed: onBack,
            color: fg,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          GestureDetector(
            onTap: onProfileTap,
            behavior: HitTestBehavior.opaque,
            child: ChatAvatar(title: title, radius: 17, avatarUrl: avatarUrl),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onProfileTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: fg,
                          ),
                        ),
                      ),
                      if (disappearingMessagesEnabled) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 15,
                          color: const Color(0xFFFFB454),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: fg.withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Badge.count(
              count: threadsUnreadCount,
              isLabelVisible: threadsUnreadCount > 0,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: IconButton(
                  tooltip: l10n.chat_header_tooltip_threads,
                  onPressed: onThreadsTap,
                  iconSize: 17,
                  color: fg,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.forum_outlined),
                ),
              ),
            ),
          ),
          iconButton(
            tooltip: l10n.chat_header_tooltip_search,
            onTap: onSearchTap,
            icon: Icons.search_rounded,
          ),
          if (scheduledCount > 0 && onScheduledTap != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Badge.count(
                count: scheduledCount,
                isLabelVisible: scheduledCount > 0,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: IconButton(
                    tooltip: l10n.chat_header_tooltip_scheduled,
                    onPressed: onScheduledTap,
                    iconSize: 17,
                    color: fg,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.schedule_send_rounded),
                  ),
                ),
              ),
            ),
          if (showCalls) ...[
            iconButton(
              tooltip: l10n.chat_header_tooltip_video_call,
              onTap: onVideoCallTap,
              icon: Icons.videocam_outlined,
            ),
            iconButton(
              tooltip: l10n.chat_header_tooltip_audio_call,
              onTap: onAudioCallTap,
              icon: Icons.call_outlined,
            ),
          ],
        ],
      ),
    );
  }
}
