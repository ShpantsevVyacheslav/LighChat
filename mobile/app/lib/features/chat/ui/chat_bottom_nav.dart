import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/bottom_nav_icon_settings.dart';
import 'chat_avatar.dart';

enum ChatBottomNavTab { chats, contacts, meetings, calls }

class ChatBottomNav extends StatefulWidget {
  const ChatBottomNav({
    super.key,
    required this.activeTab,
    required this.onChatsTap,
    required this.onContactsTap,
    required this.onProfileTap,
    this.onMeetingsTap,
    this.onCallsTap,
    this.avatarUrl,
    this.userTitle,
    this.bottomNavAppearance = 'colorful',
    this.bottomNavIconNames = const <String, String>{},
    this.bottomNavIconGlobalStyle = const BottomNavIconVisualStyle(),
    this.bottomNavIconStyles = const <String, BottomNavIconVisualStyle>{},
  });

  final ChatBottomNavTab activeTab;
  final VoidCallback onChatsTap;
  final VoidCallback onContactsTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onMeetingsTap;
  final VoidCallback? onCallsTap;
  final String? avatarUrl;
  final String? userTitle;

  final String bottomNavAppearance;
  final Map<String, String> bottomNavIconNames;
  final BottomNavIconVisualStyle bottomNavIconGlobalStyle;
  final Map<String, BottomNavIconVisualStyle> bottomNavIconStyles;

  @override
  State<ChatBottomNav> createState() => _ChatBottomNavState();
}

class _ChatBottomNavState extends State<ChatBottomNav>
    with SingleTickerProviderStateMixin {
  static const int _slotCount = 5;
  static const double _barHeight = 64;
  static const double _pillYMargin = 5;
  static const double _dragThresholdPx = 10;

  AnimationController? _pillAnim;
  CurvedAnimation? _pillCurved;
  Animation<double>? _pillAnimValue;
  VoidCallback? _pillAnimListener;
  double _pillCenterX = 0;
  double _lastBarWidth = 0;
  bool _pillLayoutReady = false;

  double? _pointerDownX;
  double _dragTravel = 0;
  bool _gestureDragging = false;

  @override
  void dispose() {
    _stopPillAnimation();
    super.dispose();
  }

  void _stopPillAnimation() {
    if (_pillAnimListener != null && _pillAnimValue != null) {
      _pillAnimValue!.removeListener(_pillAnimListener!);
    }
    _pillAnimListener = null;
    _pillAnimValue = null;
    _pillAnim?.stop();
    _pillCurved?.dispose();
    _pillCurved = null;
    _pillAnim?.dispose();
    _pillAnim = null;
  }

  void _runPillAnimation(double from, double to) {
    _stopPillAnimation();
    final c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pillAnim = c;
    final curved = CurvedAnimation(parent: c, curve: Curves.easeOutCubic);
    _pillCurved = curved;
    final t = Tween<double>(begin: from, end: to).animate(curved);
    _pillAnimValue = t;
    _pillAnimListener = () {
      if (!mounted) return;
      setState(() => _pillCenterX = t.value);
    };
    t.addListener(_pillAnimListener!);
    c.forward().whenComplete(() {
      if (_pillAnim != c) return;
      if (_pillAnimListener != null && _pillAnimValue != null) {
        _pillAnimValue!.removeListener(_pillAnimListener!);
      }
      _pillAnimListener = null;
      _pillAnimValue = null;
      _pillCurved?.dispose();
      _pillCurved = null;
      c.dispose();
      _pillAnim = null;
    });
  }

  int _tabToPillIndex(ChatBottomNavTab t) {
    switch (t) {
      case ChatBottomNavTab.chats:
        return 0;
      case ChatBottomNavTab.contacts:
        return 1;
      case ChatBottomNavTab.calls:
        return 2;
      case ChatBottomNavTab.meetings:
        return 3;
    }
  }

  double _slotWidth(double barW) => barW / _slotCount;

  double _pillWidth(double barW) => _slotWidth(barW) * 0.74;

  double _centerForSlotIndex(int i, double barW) {
    final sw = _slotWidth(barW);
    return sw * (i + 0.5);
  }

  double _clampCenter(double cx, double barW) {
    final hw = _pillWidth(barW) / 2;
    return cx.clamp(hw, barW - hw);
  }

  bool _pillMotionActive() {
    final anim = _pillAnim;
    return _gestureDragging || (anim != null && anim.isAnimating);
  }

  /// Лёгкое увеличение только в движении (в покое — почти как у Telegram).
  double _pillScale() {
    if (_gestureDragging) return 1.10;
    final anim = _pillAnim;
    if (anim != null && anim.isAnimating) return 1.06;
    return 1.0;
  }

  /// Размытие сильнее только при перетаскивании / анимации смены вкладки.
  double _pillBlurSigma() => _pillMotionActive() ? 20.0 : 5.5;

  void _syncPillToActiveTab(double barW, {bool animate = true}) {
    if (barW <= 0 || !mounted) return;
    final target = _centerForSlotIndex(_tabToPillIndex(widget.activeTab), barW);
    final clamped = _clampCenter(target, barW);
    if (!_pillLayoutReady) {
      if (!mounted) return;
      setState(() {
        _pillCenterX = clamped;
        _pillLayoutReady = true;
      });
      return;
    }
    if ((_pillCenterX - clamped).abs() < 0.5) return;
    if (animate && !_gestureDragging) {
      final from = _pillCenterX;
      _runPillAnimation(from, clamped);
    } else {
      setState(() => _pillCenterX = clamped);
    }
  }

  @override
  void didUpdateWidget(ChatBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeTab != widget.activeTab &&
        !_gestureDragging &&
        _lastBarWidth > 0) {
      _syncPillToActiveTab(_lastBarWidth, animate: true);
    }
  }

  void _onPointerDown(PointerDownEvent e) {
    _pointerDownX = e.localPosition.dx;
    _dragTravel = 0;
    _gestureDragging = false;
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_pointerDownX == null || _lastBarWidth <= 0) return;
    _dragTravel += e.delta.dx.abs();
    if (!_gestureDragging && _dragTravel > _dragThresholdPx) {
      setState(() => _gestureDragging = true);
    }
    if (_gestureDragging) {
      setState(() {
        _pillCenterX = _clampCenter(_pillCenterX + e.delta.dx, _lastBarWidth);
      });
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    if (_lastBarWidth <= 0) {
      _pointerDownX = null;
      return;
    }
    if (_gestureDragging) {
      final sw = _slotWidth(_lastBarWidth);
      final idx = (_pillCenterX / sw).round().clamp(0, _slotCount - 1);
      final target = _clampCenter(_centerForSlotIndex(idx, _lastBarWidth), _lastBarWidth);
      setState(() {
        _pillCenterX = target;
        _gestureDragging = false;
      });
      _invokeSlot(idx);
    }
    _pointerDownX = null;
    _dragTravel = 0;
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _pointerDownX = null;
    _dragTravel = 0;
    if (_gestureDragging && _lastBarWidth > 0) {
      _syncPillToActiveTab(_lastBarWidth, animate: true);
    }
    setState(() => _gestureDragging = false);
  }

  void _invokeSlot(int index) {
    switch (index) {
      case 0:
        widget.onChatsTap();
        break;
      case 1:
        widget.onContactsTap();
        break;
      case 2:
        widget.onCallsTap?.call();
        break;
      case 3:
        widget.onMeetingsTap?.call();
        break;
      case 4:
        widget.onProfileTap();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bottomNavAppearance == 'minimal') {
      return _ChatBottomNavClassic(
        activeTab: widget.activeTab,
        onChatsTap: widget.onChatsTap,
        onContactsTap: widget.onContactsTap,
        onProfileTap: widget.onProfileTap,
        onMeetingsTap: widget.onMeetingsTap,
        onCallsTap: widget.onCallsTap,
        avatarUrl: widget.avatarUrl,
        userTitle: widget.userTitle,
        bottomNavAppearance: widget.bottomNavAppearance,
        bottomNavIconNames: widget.bottomNavIconNames,
        bottomNavIconGlobalStyle: widget.bottomNavIconGlobalStyle,
        bottomNavIconStyles: widget.bottomNavIconStyles,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final barTint = dark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);
    final barBorder = dark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.08);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            if (w > 0 && w != _lastBarWidth) {
              _lastBarWidth = w;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _syncPillToActiveTab(w, animate: false);
              });
            }

            final motion = _pillMotionActive();
            final baseW = w > 0 ? _pillWidth(w) : 0.0;
            final baseH = _barHeight - _pillYMargin * 2;
            final scale = w > 0 ? _pillScale() : 1.0;
            final blurSigma = w > 0 ? _pillBlurSigma() : 5.5;
            final pw = baseW * scale;
            final ph = baseH * scale;
            final pillLeft = w > 0
                ? (_pillCenterX - pw / 2).clamp(0.0, w - pw)
                : 0.0;
            final pillTopRaw = _pillYMargin - (ph - baseH) / 2;
            final topClamped = w > 0 && ph <= _barHeight
                ? pillTopRaw.clamp(0.0, _barHeight - ph)
                : _pillYMargin;

            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: barTint,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: barBorder, width: 1),
                  ),
                  child: SizedBox(
                    height: _barHeight,
                    width: w,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Пилюля‑«стекло» рисуется ПОД иконками, чтобы активная
                        // иконка оставалась чёткой, а blur применялся только
                        // к содержимому, находящемуся за баром (Telegram‑эффект).
                        if (w > 0 && _pillLayoutReady)
                          Positioned(
                            left: pillLeft,
                            top: topClamped,
                            width: pw,
                            height: ph,
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: blurSigma,
                                    sigmaY: blurSigma,
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: motion
                                            ? <Color>[
                                                Colors.white.withValues(
                                                  alpha: dark ? 0.11 : 0.09,
                                                ),
                                                const Color(
                                                  0xFF4DB8FF,
                                                ).withValues(
                                                  alpha: dark ? 0.10 : 0.07,
                                                ),
                                                Colors.white.withValues(
                                                  alpha: dark ? 0.05 : 0.04,
                                                ),
                                              ]
                                            : <Color>[
                                                Colors.white.withValues(
                                                  alpha: dark ? 0.045 : 0.035,
                                                ),
                                                const Color(
                                                  0xFF4DB8FF,
                                                ).withValues(
                                                  alpha: dark ? 0.035 : 0.028,
                                                ),
                                                Colors.white.withValues(
                                                  alpha: dark ? 0.02 : 0.016,
                                                ),
                                              ],
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: motion
                                              ? (dark ? 0.38 : 0.42)
                                              : (dark ? 0.22 : 0.26),
                                        ),
                                        width: 1,
                                      ),
                                      boxShadow: motion
                                          ? <BoxShadow>[
                                              BoxShadow(
                                                color: Colors.white.withValues(
                                                  alpha: dark ? 0.12 : 0.18,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, -2),
                                              ),
                                            ]
                                          : const <BoxShadow>[],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Иконки — ПОВЕРХ стеклянной пилюли, остаются чёткими.
                        Row(
                          children: [
                            Expanded(
                              child: _LiquidNavSlot(
                                active:
                                    widget.activeTab == ChatBottomNavTab.chats,
                                href: '/dashboard/chat',
                                fallbackIcon:
                                    Icons.chat_bubble_outline_rounded,
                                iconNames: widget.bottomNavIconNames,
                                globalStyle:
                                    widget.bottomNavIconGlobalStyle,
                                localStyle: widget
                                    .bottomNavIconStyles['/dashboard/chat'],
                                onTap: widget.onChatsTap,
                              ),
                            ),
                            Expanded(
                              child: _LiquidNavSlot(
                                active: widget.activeTab ==
                                    ChatBottomNavTab.contacts,
                                href: '/dashboard/contacts',
                                fallbackIcon: Icons.group_outlined,
                                iconNames: widget.bottomNavIconNames,
                                globalStyle:
                                    widget.bottomNavIconGlobalStyle,
                                localStyle: widget.bottomNavIconStyles[
                                    '/dashboard/contacts'],
                                onTap: widget.onContactsTap,
                              ),
                            ),
                            Expanded(
                              child: _LiquidNavSlot(
                                active:
                                    widget.activeTab == ChatBottomNavTab.calls,
                                href: '/dashboard/calls',
                                fallbackIcon: Icons.call_outlined,
                                iconNames: widget.bottomNavIconNames,
                                globalStyle:
                                    widget.bottomNavIconGlobalStyle,
                                localStyle: widget
                                    .bottomNavIconStyles['/dashboard/calls'],
                                onTap: widget.onCallsTap,
                              ),
                            ),
                            Expanded(
                              child: _LiquidNavSlot(
                                active: widget.activeTab ==
                                    ChatBottomNavTab.meetings,
                                href: '/dashboard/meetings',
                                fallbackIcon: Icons.videocam_outlined,
                                iconNames: widget.bottomNavIconNames,
                                globalStyle:
                                    widget.bottomNavIconGlobalStyle,
                                localStyle: widget.bottomNavIconStyles[
                                    '/dashboard/meetings'],
                                onTap: widget.onMeetingsTap,
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: _ProfileAvatarButton(
                                  onTap: widget.onProfileTap,
                                  avatarUrl: widget.avatarUrl,
                                  title: widget.userTitle ?? 'U',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Слот иконки в «liquid» баре: без заливки плитки — только иконка поверх стекла.
class _LiquidNavSlot extends StatelessWidget {
  const _LiquidNavSlot({
    required this.active,
    required this.href,
    required this.fallbackIcon,
    required this.iconNames,
    required this.globalStyle,
    required this.localStyle,
    required this.onTap,
  });

  final bool active;
  final String href;
  final IconData fallbackIcon;
  final Map<String, String> iconNames;
  final BottomNavIconVisualStyle globalStyle;
  final BottomNavIconVisualStyle? localStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final visual = mergeBottomNavIconVisualStyles(globalStyle, localStyle);
    final resolvedName = resolveBottomNavIconName(href, iconNames);
    final iconData = iconDataForBottomNavName(resolvedName, fallbackIcon);
    final customIconColor = parseColorFromHex(visual.iconColor);
    final iconSize = (visual.size ?? 24.0).clamp(18.0, 30.0);
    final strokeWidth = (visual.strokeWidth ?? (active ? 2.35 : 2.0)).clamp(
      1.0,
      3.0,
    );
    final iconWeight = 200 + ((strokeWidth - 1.0) / 2.0 * 500.0);
    final defaultColor = active
        ? Colors.white
        : (dark
              ? Colors.white.withValues(alpha: 0.52)
              : Colors.black.withValues(alpha: 0.45));
    final iconColor = customIconColor ?? defaultColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.expand(
          child: Center(
            child: Icon(
              iconData,
              color: iconColor,
              size: iconSize,
              weight: iconWeight,
            ),
          ),
        ),
      ),
    );
  }
}

/// Прежний вид нижней навигации для `bottomNavAppearance == 'minimal'`.
class _ChatBottomNavClassic extends StatelessWidget {
  const _ChatBottomNavClassic({
    required this.activeTab,
    required this.onChatsTap,
    required this.onContactsTap,
    required this.onProfileTap,
    required this.onMeetingsTap,
    required this.onCallsTap,
    required this.avatarUrl,
    required this.userTitle,
    required this.bottomNavAppearance,
    required this.bottomNavIconNames,
    required this.bottomNavIconGlobalStyle,
    required this.bottomNavIconStyles,
  });

  final ChatBottomNavTab activeTab;
  final VoidCallback onChatsTap;
  final VoidCallback onContactsTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onMeetingsTap;
  final VoidCallback? onCallsTap;
  final String? avatarUrl;
  final String? userTitle;
  final String bottomNavAppearance;
  final Map<String, String> bottomNavIconNames;
  final BottomNavIconVisualStyle bottomNavIconGlobalStyle;
  final Map<String, BottomNavIconVisualStyle> bottomNavIconStyles;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 72,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavTile(
                href: '/dashboard/chat',
                fallbackIcon: Icons.chat_bubble_outline_rounded,
                active: activeTab == ChatBottomNavTab.chats,
                onTap: onChatsTap,
                appearance: bottomNavAppearance,
                iconNames: bottomNavIconNames,
                globalStyle: bottomNavIconGlobalStyle,
                localStyle: bottomNavIconStyles['/dashboard/chat'],
              ),
              _NavTile(
                href: '/dashboard/contacts',
                fallbackIcon: Icons.group_outlined,
                active: activeTab == ChatBottomNavTab.contacts,
                onTap: onContactsTap,
                appearance: bottomNavAppearance,
                iconNames: bottomNavIconNames,
                globalStyle: bottomNavIconGlobalStyle,
                localStyle: bottomNavIconStyles['/dashboard/contacts'],
              ),
              _NavTile(
                href: '/dashboard/calls',
                fallbackIcon: Icons.call_outlined,
                active: activeTab == ChatBottomNavTab.calls,
                onTap: onCallsTap,
                appearance: bottomNavAppearance,
                iconNames: bottomNavIconNames,
                globalStyle: bottomNavIconGlobalStyle,
                localStyle: bottomNavIconStyles['/dashboard/calls'],
              ),
              _NavTile(
                href: '/dashboard/meetings',
                fallbackIcon: Icons.videocam_outlined,
                active: activeTab == ChatBottomNavTab.meetings,
                onTap: onMeetingsTap,
                appearance: bottomNavAppearance,
                iconNames: bottomNavIconNames,
                globalStyle: bottomNavIconGlobalStyle,
                localStyle: bottomNavIconStyles['/dashboard/meetings'],
              ),
              _ProfileAvatarButton(
                onTap: onProfileTap,
                avatarUrl: avatarUrl,
                title: userTitle ?? 'U',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton({
    required this.onTap,
    required this.avatarUrl,
    required this.title,
  });

  final VoidCallback onTap;
  final String? avatarUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: dark
                  ? const Color(0xFF3C6AE2)
                  : const Color(0xFF4A74E8).withValues(alpha: 0.55),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? const [Color(0xFF162B63), Color(0xFF2D1858)]
                  : const [Color(0xFFE8EEFF), Color(0xFFDDE6FF)],
            ),
          ),
          child: ChatAvatar(title: title, radius: 20, avatarUrl: avatarUrl),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.href,
    required this.fallbackIcon,
    this.active = false,
    this.onTap,
    required this.appearance,
    required this.iconNames,
    required this.globalStyle,
    required this.localStyle,
  });

  final String href;
  final IconData fallbackIcon;
  final bool active;
  final VoidCallback? onTap;
  final String appearance;
  final Map<String, String> iconNames;
  final BottomNavIconVisualStyle globalStyle;
  final BottomNavIconVisualStyle? localStyle;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final visual = mergeBottomNavIconVisualStyles(globalStyle, localStyle);
    final resolvedName = resolveBottomNavIconName(href, iconNames);
    final iconData = iconDataForBottomNavName(resolvedName, fallbackIcon);

    final customIconColor = parseColorFromHex(visual.iconColor);
    final customTileColor = parseColorFromHex(visual.tileBackground);
    final iconSize = (visual.size ?? 24.0).clamp(16.0, 34.0);
    final strokeWidth = (visual.strokeWidth ?? (active ? 2.35 : 2.0)).clamp(
      1.0,
      3.0,
    );
    final iconWeight = 200 + ((strokeWidth - 1.0) / 2.0 * 500.0);

    final defaultColor = appearance == 'minimal'
        ? (active
              ? const Color(0xFF2A79FF)
              : (dark ? const Color(0xFF8D93A4) : const Color(0xFF6B7280)))
        : Colors.white;
    final iconColor = customIconColor ?? defaultColor;

    final useCustomTile = customTileColor != null;
    final useColorfulTile = appearance != 'minimal' && !useCustomTile;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: useCustomTile
                  ? customTileColor
                  : (useColorfulTile ? null : Colors.transparent),
              gradient: useColorfulTile
                  ? defaultBottomNavTileGradient(href)
                  : null,
              border: Border.all(
                color: appearance == 'minimal' && !useCustomTile
                    ? Colors.white.withValues(alpha: active ? 0.12 : 0)
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Icon(
              iconData,
              color: iconColor,
              size: iconSize,
              weight: iconWeight,
            ),
          ),
        ),
      ),
    );
  }
}
