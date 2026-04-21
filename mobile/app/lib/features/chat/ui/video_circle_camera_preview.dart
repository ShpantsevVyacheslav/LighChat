import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Превью для кружка: паритет с [CameraPreview], но без `recordingOrientation!`
/// (иначе редкие кадры во время записи дают падение) и с запасным поворотом на Android.
class VideoCircleCameraPreview extends StatelessWidget {
  const VideoCircleCameraPreview({super.key, required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    return ValueListenableBuilder<CameraValue>(
      valueListenable: controller,
      builder: (BuildContext context, CameraValue value, Widget? _) {
        if (!value.isInitialized || value.previewSize == null) {
          return const ColoredBox(color: Colors.black);
        }
        // Паритет с штатным `CameraPreview`: `value.aspectRatio` рапортует
        // соотношение сенсора (landscape), поэтому в портретной ориентации
        // его необходимо инвертировать. Если этого не сделать, контент
        // (уже перевёрнутый плагином/`RotatedBox` в портрет) растягивается
        // по ширине — именно это и давало «сплющенное» лицо.
        final isLandscape = _isLandscape(controller);
        final ar = isLandscape
            ? value.aspectRatio
            : 1.0 / value.aspectRatio;

        // Нормализованные «пиксельные» размеры, сохраняющие нужное AR.
        // Для круга используем `BoxFit.cover`, чтобы превью полностью
        // закрывало квадратный родитель без чёрных полей.
        final contentW = ar >= 1.0 ? ar : 1.0;
        final contentH = ar >= 1.0 ? 1.0 : 1.0 / ar;
        return FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: contentW * 1000,
            height: contentH * 1000,
            child: _wrapInRotatedBox(
              controller: controller,
              child: controller.buildPreview(),
            ),
          ),
        );
      },
    );
  }
}

bool _isLandscape(CameraController controller) {
  final o = _getApplicableOrientation(controller);
  return o == DeviceOrientation.landscapeLeft ||
      o == DeviceOrientation.landscapeRight;
}

int _getQuarterTurns(CameraController controller) {
  final turns = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeRight: 1,
    DeviceOrientation.portraitDown: 2,
    DeviceOrientation.landscapeLeft: 3,
  };
  return turns[_getApplicableOrientation(controller)] ?? 0;
}

DeviceOrientation _getApplicableOrientation(CameraController controller) {
  final v = controller.value;
  if (v.isRecordingVideo) {
    return v.recordingOrientation ??
        v.lockedCaptureOrientation ??
        v.deviceOrientation;
  }
  return v.previewPauseOrientation ??
      v.lockedCaptureOrientation ??
      v.deviceOrientation;
}

Widget _wrapInRotatedBox({
  required CameraController controller,
  required Widget child,
}) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return child;
  }
  return RotatedBox(
    quarterTurns: _getQuarterTurns(controller),
    child: child,
  );
}
