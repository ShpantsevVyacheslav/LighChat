import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lighchat_mobile/features/chat/ui/chat_composer.dart';
import 'package:lighchat_mobile/features/chat/ui/chat_html_composer_controller.dart';
import 'package:lighchat_mobile/features/chat/ui/chat_wallpaper_scope.dart';
import 'package:lighchat_mobile/l10n/app_localizations.dart';

const _l10nDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Минимальный wrapper для рендера [ChatComposer] в widget-тесте.
/// Прокидывает локализацию и пустой wallpaper-scope, без которых
/// `AppLocalizations.of(context)` / `ChatWallpaperScope.of(context)`
/// падают с null check.
Widget _hostWith({
  required ChatHtmlComposerController controller,
  required FocusNode focusNode,
  List<XFile> pendingAttachments = const [],
  bool stickersPanelOpen = false,
  bool sendBusy = false,
  GlobalKey<ChatComposerState>? composerKey,
  VoidCallback? onSend,
  VoidCallback? onMicTap,
  VoidCallback? onStickersTap,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: _l10nDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ChatWallpaperScope(
        wallpaper: null,
        child: ChatComposer(
          key: composerKey,
          controller: controller,
          focusNode: focusNode,
          onSend: onSend ?? () {},
          onAttachmentSelected: (_) {},
          pendingAttachments: pendingAttachments,
          onRemovePending: (_) {},
          onEditPending: (_) async {},
          attachmentsEnabled: true,
          sendBusy: sendBusy,
          onMicTap: onMicTap ?? () {},
          onStickersTap: onStickersTap ?? () {},
          stickersPanelOpen: stickersPanelOpen,
        ),
      ),
    ),
  );
}

void main() {
  group('ChatComposer rendering (non-iOS, Flutter TextField путь)', () {
    testWidgets('пустой контроллер → mic-кнопка вместо send', (tester) async {
      final controller = ChatHtmlComposerController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _hostWith(controller: controller, focusNode: focusNode),
      );
      await tester.pump();

      expect(find.byIcon(Icons.send_rounded), findsNothing);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('ввели текст → send-кнопка появляется, mic исчезает',
        (tester) async {
      final controller = ChatHtmlComposerController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _hostWith(controller: controller, focusNode: focusNode),
      );
      await tester.pump();

      controller.text = 'hello world';
      await tester.pump();

      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsNothing);
    });

    testWidgets('тап на send-кнопку триггерит onSend', (tester) async {
      final controller = ChatHtmlComposerController(text: 'hi');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      var sendCalls = 0;
      await tester.pumpWidget(
        _hostWith(
          controller: controller,
          focusNode: focusNode,
          onSend: () => sendCalls += 1,
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(sendCalls, 1);
    });

    testWidgets(
        'inline format-button (Aa) НЕ показан на не-iOS '
        '(native composer выключен, fallback на Flutter TextField)',
        (tester) async {
      final controller = ChatHtmlComposerController(text: 'hello');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _hostWith(controller: controller, focusNode: focusNode),
      );
      await tester.pump();

      // Icons.text_format_rounded — иконка inline Aa-кнопки. На
      // не-iOS платформах NativeComposerFlag.isEnabled()=false,
      // _useNativeComposer=false, кнопка не рендерится.
      expect(find.byIcon(Icons.text_format_rounded), findsNothing);
    });
  });

  group('ChatComposerState.unfocusComposer', () {
    testWidgets(
        'unfocusComposer() снимает focus с переданного FocusNode',
        (tester) async {
      final controller = ChatHtmlComposerController();
      final focusNode = FocusNode();
      final composerKey = GlobalKey<ChatComposerState>();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _hostWith(
          controller: controller,
          focusNode: focusNode,
          composerKey: composerKey,
        ),
      );
      await tester.pump();

      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue,
          reason: 'pre-condition: focusNode подхватил focus');

      // unfocusComposer() возвращает Future, но в widget-тесте без
      // native PlatformView'a invokeMethod просто не доходит до Swift
      // (channel=null), и Future resolveится сразу. Поэтому хватает
      // одного `pump` после.
      await composerKey.currentState!.unfocusComposer();
      await tester.pump();

      expect(focusNode.hasFocus, isFalse,
          reason: 'unfocusComposer должен снять focus с Flutter focusNode');
    });

    testWidgets('focusComposer() поднимает focus на FocusNode',
        (tester) async {
      final controller = ChatHtmlComposerController();
      final focusNode = FocusNode();
      final composerKey = GlobalKey<ChatComposerState>();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _hostWith(
          controller: controller,
          focusNode: focusNode,
          composerKey: composerKey,
        ),
      );
      await tester.pump();

      expect(focusNode.hasFocus, isFalse, reason: 'pre-condition: пусто');

      composerKey.currentState!.focusComposer();
      await tester.pump();

      expect(focusNode.hasFocus, isTrue,
          reason: 'focusComposer должен поднять focus на focusNode');
    });
  });

  group('ChatComposer interactions', () {
    testWidgets('тап на иконку стикеров вызывает onStickersTap',
        (tester) async {
      final controller = ChatHtmlComposerController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      var stickersCalls = 0;
      await tester.pumpWidget(
        _hostWith(
          controller: controller,
          focusNode: focusNode,
          onStickersTap: () => stickersCalls += 1,
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.emoji_emotions_outlined));
      await tester.pump();

      expect(stickersCalls, 1);
    });

    testWidgets(
        'при stickersPanelOpen=true иконка превращается в keyboard_rounded',
        (tester) async {
      final controller = ChatHtmlComposerController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _hostWith(
          controller: controller,
          focusNode: focusNode,
          stickersPanelOpen: true,
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.keyboard_rounded), findsOneWidget);
      expect(find.byIcon(Icons.emoji_emotions_outlined), findsNothing);
    });

    // Note: Format popover widget-test пропущен — `_EffectBtnPreview`
    // внутри popover'а использует `AnimatedTextSpan` который требует
    // bounded constraints от parent Stack/Positioned. В test-environment
    // без MaterialApp/MediaQuery overlay-layout роняет hasSize-assert.
    // Реальная проверка popover'а делается на устройстве по логам
    // `[format-popover] open: ...` → `[format-popover] _emit tag=...`.

    testWidgets('sendBusy=true → CircularProgressIndicator', (tester) async {
      final controller = ChatHtmlComposerController(text: 'hi');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _hostWith(
          controller: controller,
          focusNode: focusNode,
          sendBusy: true,
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
