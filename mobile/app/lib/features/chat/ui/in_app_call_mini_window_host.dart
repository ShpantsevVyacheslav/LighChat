import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../l10n/app_localizations.dart';
import 'in_app_call_mini_window_controller.dart';

class InAppCallMiniWindowHost extends StatefulWidget {
  const InAppCallMiniWindowHost({super.key, required this.child});

  final Widget child;

  @override
  State<InAppCallMiniWindowHost> createState() => _InAppCallMiniWindowHostState();
}

class _InAppCallMiniWindowHostState extends State<InAppCallMiniWindowHost> {
  Offset _offset = const Offset(16, 120);
  Offset? _dragStart;
  Offset? _offsetAtStart;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ValueListenableBuilder<InAppCallMiniWindowPayload?>(
          valueListenable: InAppCallMiniWindowController.notifier,
          builder: (context, payload, _) {
            if (payload == null) return const SizedBox.shrink();

            final mq = MediaQuery.of(context);
            final safe = mq.padding;
            final size = mq.size;

            const w = 168.0;
            const h = 224.0;

            final minX = 8.0;
            final minY = safe.top + 8.0;
            final maxX = size.width - w - 8.0;
            final maxY = size.height - h - safe.bottom - 8.0;
            final clamped = Offset(
              _offset.dx.clamp(minX, maxX),
              _offset.dy.clamp(minY, maxY),
            );
            if (clamped != _offset) {
              // Keep it in bounds after orientation / insets changes.
              _offset = clamped;
            }

            return Positioned(
              left: _offset.dx,
              top: _offset.dy,
              width: w,
              height: h,
              child: GestureDetector(
                onPanStart: (d) {
                  _dragStart = d.globalPosition;
                  _offsetAtStart = _offset;
                },
                onPanUpdate: (d) {
                  final start = _dragStart;
                  final base = _offsetAtStart;
                  if (start == null || base == null) return;
                  setState(() {
                    _offset = base + (d.globalPosition - start);
                  });
                },
                onPanEnd: (_) {
                  _dragStart = null;
                  _offsetAtStart = null;
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: RTCVideoView(
                              payload.remoteRenderer,
                              mirror: false,
                              objectFit:
                                  RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Row(
                              children: [
                                _MiniIconButton(
                                  icon: Icons.call_end_rounded,
                                  tooltip: AppLocalizations.of(context)!.call_mini_end,
                                  background: Colors.red.withValues(alpha: 0.88),
                                  onPressed: payload.onHangUp,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 8,
                            bottom: 8,
                            right: 8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  payload.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: payload.onReturnToCall,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.35,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                        ),
                                        child: const Text(
                                          'Open',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 10,
                            top: 10,
                            width: 56,
                            height: 76,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.14),
                                  ),
                                ),
                                child: RTCVideoView(
                                  payload.localRenderer,
                                  mirror: true,
                                  objectFit: RTCVideoViewObjectFit
                                      .RTCVideoViewObjectFitCover,
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                onTap: payload.onReturnToCall,
                                splashColor: Colors.white.withValues(alpha: 0.08),
                                highlightColor:
                                    Colors.white.withValues(alpha: 0.04),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    required this.icon,
    required this.tooltip,
    required this.background,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color background;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

