#import "GeneratedPluginRegistrant.h"

// Меетинг-PiP: нужны нативные классы flutter_webrtc и WebRTC-SDK,
// чтобы получить ссылку на RTCVideoTrack по trackId (Dart-сторона его
// присылает через `lighchat/meeting_pip:bindLocalTrack`) и подвесить
// собственный RTCVideoRenderer, конвертирующий RTCVideoFrame → CMSampleBuffer
// в AVSampleBufferDisplayLayer PiP-окна.
//
// flutter_webrtc-1.4.x экспортирует FlutterWebRTCPlugin со static_framework,
// поэтому подключаем заголовки напрямую — Swift-import не сработает.
#import <flutter_webrtc/FlutterWebRTCPlugin.h>
#import <flutter_webrtc/LocalVideoTrack.h>
#import <flutter_webrtc/LocalTrack.h>
#import <WebRTC/WebRTC.h>
