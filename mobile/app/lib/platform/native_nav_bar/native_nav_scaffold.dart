import 'dart:async';

import 'package:flutter/material.dart';

import 'nav_bar_config.dart';
import 'native_nav_bar_facade.dart';

/// Drop-in replacement for `Scaffold(appBar: AppBar(...), bottomNavigationBar: ...)`.
///
/// On iOS / macOS pushes config via [NativeNavBarFacade] — the actual bars
/// are rendered by UIKit / AppKit. On Android / Windows / Linux / Web falls
/// back to a Material `Scaffold` that maps the same config into `AppBar` /
/// `BottomNavigationBar`.
class NativeNavScaffold extends StatefulWidget {
  const NativeNavScaffold({
    super.key,
    required this.top,
    required this.body,
    this.bottom,
    this.search,
    this.selection,
    this.backgroundColor,
    this.extendBodyBehindBars = false,
    this.onEvent,
    this.onBack,
    this.onTabChanged,
    this.onAction,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onSearchCancelled,
    this.materialBottomBarBuilder,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  final NavBarTopConfig top;
  final NavBarBottomConfig? bottom;
  final NavBarSearchConfig? search;
  final NavBarSelectionConfig? selection;
  final Widget body;
  final Color? backgroundColor;

  /// When `true`, Flutter content draws under the bars (transparent style).
  /// Default: content is laid out inside SafeArea / between bars.
  final bool extendBodyBehindBars;

  /// Raw event callback (fired for every event from native bar).
  final void Function(NavBarEvent event)? onEvent;
  final VoidCallback? onBack;
  final void Function(String tabId)? onTabChanged;
  final void Function(String actionId)? onAction;
  final void Function(String value)? onSearchChanged;
  final void Function(String value)? onSearchSubmitted;
  final VoidCallback? onSearchCancelled;

  /// Optional builder for the Material-fallback bottom bar
  /// (Android / Windows / Linux). When `null` and [bottom] is set,
  /// a default `BottomNavigationBar` is built from the config.
  final Widget Function(
    BuildContext context,
    NavBarBottomConfig config,
    void Function(String tabId) onTap,
  )? materialBottomBarBuilder;

  /// Optional floating-action-button rendered by the underlying Material
  /// `Scaffold` on both native and fallback paths.
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  State<NativeNavScaffold> createState() => _NativeNavScaffoldState();
}

class _NativeNavScaffoldState extends State<NativeNavScaffold> {
  StreamSubscription<NavBarEvent>? _sub;
  bool get _native => NativeNavBarFacade.instance.isSupported;

  @override
  void initState() {
    super.initState();
    if (_native) {
      _sub = NativeNavBarFacade.instance.events.listen(_handleEvent);
      WidgetsBinding.instance.addPostFrameCallback((_) => _push());
    }
  }

  @override
  void didUpdateWidget(covariant NativeNavScaffold old) {
    super.didUpdateWidget(old);
    if (_native) _push();
  }

  @override
  void dispose() {
    _sub?.cancel();
    if (_native) {
      // Best-effort cleanup so a popped screen doesn't leave its bar visible
      // before the next screen pushes its own config.
      // The next screen's initState will overwrite this on the same frame.
      unawaited(NativeNavBarFacade.instance.hideAll());
    }
    super.dispose();
  }

  void _push() {
    final f = NativeNavBarFacade.instance;
    unawaited(f.setTopBar(widget.top));
    unawaited(
      f.setBottomBar(widget.bottom ?? const NavBarBottomConfig.hidden()),
    );
    unawaited(
      f.setSearchMode(widget.search ?? const NavBarSearchConfig.inactive()),
    );
    unawaited(
      f.setSelectionMode(
        widget.selection ?? const NavBarSelectionConfig.inactive(),
      ),
    );
  }

  void _handleEvent(NavBarEvent event) {
    if (!mounted) return;
    widget.onEvent?.call(event);
    switch (event) {
      case NavBarLeadingTap():
        widget.onBack?.call();
      case NavBarTabChange(:final id):
        widget.onTabChanged?.call(id);
      case NavBarActionTap(:final id):
        widget.onAction?.call(id);
      case NavBarSearchChange(:final value):
        widget.onSearchChanged?.call(value);
      case NavBarSearchSubmit(:final value):
        widget.onSearchSubmitted?.call(value);
      case NavBarSearchCancel():
        widget.onSearchCancelled?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_native) {
      // Native nav bar — overlay поверх FlutterView'а; host VC оставляет
      // `additionalSafeAreaInsets.top = 0`, чтобы chat мог рисовать
      // messages ПОД bar'ом с Liquid Glass blur. Поэтому для обычных
      // экранов (settings, features tour, auth, ...) Scaffold body
      // уехал бы в зону под bar'ом.
      //
      // Считаем явно: статус-бар занимает `MediaQuery.padding.top` сверху,
      // плюс наша native bar pill занимает `topBarOverlayPadding` ниже.
      // Складываем и подмешиваем как top-padding ListView'у/контейнеру.
      // Bottom: home indicator → MediaQuery.padding.bottom, плюс
      // tab bar overlay если виден.
      final mq = MediaQuery.of(context);
      final topPad = widget.top.visible
          ? mq.padding.top +
              NativeNavBarFacade.instance.topBarOverlayPadding
          : mq.padding.top;
      final bottomPad = (widget.bottom?.visible ?? false)
          ? NativeNavBarFacade.instance.bottomBarOverlayPadding
          : 0.0;
      final Widget body = widget.extendBodyBehindBars
          ? widget.body
          : MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
              child: Padding(
                padding: EdgeInsets.only(top: topPad, bottom: bottomPad),
                child: widget.body,
              ),
            );
      return Scaffold(
        backgroundColor: widget.backgroundColor,
        body: body,
        floatingActionButton: widget.floatingActionButton,
        floatingActionButtonLocation: widget.floatingActionButtonLocation,
      );
    }
    return _materialFallback(context);
  }

  Widget _materialFallback(BuildContext context) {
    final top = widget.top;
    final selection = widget.selection;

    PreferredSizeWidget? appBar;
    if (top.visible || (selection?.active ?? false)) {
      appBar = AppBar(
        title: Text(
          (selection?.active ?? false)
              ? '${selection!.count}'
              : top.title.title,
        ),
        leading: _materialLeading(top),
        actions: [
          if (selection?.active ?? false)
            ...selection!.actions.map(_materialActionButton)
          else
            ...top.trailing.map(_materialActionButton),
        ],
      );
    }

    Widget? bottomBar;
    final bottom = widget.bottom;
    if (bottom != null && bottom.visible && bottom.items.isNotEmpty) {
      bottomBar = widget.materialBottomBarBuilder?.call(
            context,
            bottom,
            (id) => widget.onTabChanged?.call(id),
          ) ??
          _defaultMaterialBottomBar(bottom);
    }

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      extendBodyBehindAppBar: widget.extendBodyBehindBars,
      extendBody: widget.extendBodyBehindBars,
      appBar: appBar,
      body: widget.body,
      bottomNavigationBar: bottomBar,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }

  Widget? _materialLeading(NavBarTopConfig top) {
    switch (top.leading.type) {
      case NavBarLeadingType.none:
        return null;
      case NavBarLeadingType.back:
        return IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onBack?.call(),
        );
      case NavBarLeadingType.close:
        return IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => widget.onBack?.call(),
        );
      case NavBarLeadingType.menu:
        return IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () =>
              widget.onEvent?.call(NavBarLeadingTap(top.leading.id)),
        );
    }
  }

  Widget _materialActionButton(NavBarAction action) {
    return IconButton(
      tooltip: action.title,
      onPressed: action.enabled
          ? () => widget.onAction?.call(action.id)
          : null,
      icon: Icon(_materialIconFromSymbol(action.icon.symbol)),
    );
  }

  Widget _defaultMaterialBottomBar(NavBarBottomConfig bottom) {
    final selectedIndex = bottom.items.indexWhere(
      (t) => t.id == bottom.selectedId,
    );
    return BottomNavigationBar(
      currentIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onTap: (i) => widget.onTabChanged?.call(bottom.items[i].id),
      type: BottomNavigationBarType.fixed,
      items: bottom.items
          .map(
            (t) => BottomNavigationBarItem(
              icon: Icon(_materialIconFromSymbol(t.icon.symbol)),
              label: t.label,
            ),
          )
          .toList(),
    );
  }
}

/// Best-effort mapping SF Symbol → Material Icon for the Android fallback.
/// Add cases here when new icons are introduced on the native side.
IconData _materialIconFromSymbol(String symbol) {
  switch (symbol) {
    case 'arrow.left':
      return Icons.arrow_back;
    case 'xmark':
      return Icons.close;
    case 'line.3.horizontal':
      return Icons.menu;
    case 'magnifyingglass':
      return Icons.search;
    case 'phone.fill':
      return Icons.call;
    case 'video.fill':
      return Icons.videocam;
    case 'bubble.left.and.bubble.right':
      return Icons.forum_outlined;
    case 'clock':
      return Icons.schedule;
    case 'eye.slash':
      return Icons.visibility_off_outlined;
    case 'trash':
      return Icons.delete_outline;
    case 'arrowshape.turn.up.right':
      return Icons.forward;
    case 'ellipsis':
      return Icons.more_vert;
    case 'bell.slash':
      return Icons.notifications_off_outlined;
    case 'pin.fill':
      return Icons.push_pin_outlined;
    case 'bubble.left':
      return Icons.chat_bubble_outline;
    case 'person.2.fill':
      return Icons.people_outline;
    case 'phone.connection':
      return Icons.call_outlined;
    case 'video.bubble':
      return Icons.video_call_outlined;
    case 'person.crop.circle':
      return Icons.account_circle_outlined;
    case 'plus':
      return Icons.add;
    case 'doc.on.doc':
      return Icons.copy;
    case 'safari':
      return Icons.open_in_browser;
    default:
      return Icons.circle_outlined;
  }
}
