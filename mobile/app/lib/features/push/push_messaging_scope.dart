import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import 'push_messaging_service.dart';

/// Поднимает FCM после входа и останавливает при выходе.
class PushMessagingScope extends ConsumerStatefulWidget {
  const PushMessagingScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushMessagingScope> createState() => _PushMessagingScopeState();
}

class _PushMessagingScopeState extends ConsumerState<PushMessagingScope> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromProvider());
  }

  void _syncFromProvider() {
    ref.read(authUserProvider).when(
          data: (user) {
            if (user != null) {
              unawaited(PushMessagingService.instance.start(uid: user.uid));
            } else {
              unawaited(PushMessagingService.instance.stop());
            }
          },
          loading: () {},
          error: (_, _) {},
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(authUserProvider, (prev, next) {
      next.when(
        data: (user) {
          if (user != null) {
            unawaited(PushMessagingService.instance.start(uid: user.uid));
          } else {
            unawaited(PushMessagingService.instance.stop());
          }
        },
        loading: () {},
        error: (_, _) {},
      );
    });
    return widget.child;
  }
}
