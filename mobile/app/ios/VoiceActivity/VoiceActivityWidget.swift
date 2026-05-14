import ActivityKit
import SwiftUI
import WidgetKit

/// SwiftUI-вьюшки Live Activity для голосового сообщения.
///
/// Этот файл должен входить **только** в target VoiceActivity (Widget
/// Extension), не в Runner.
@available(iOS 16.1, *)
struct VoiceActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: VoiceActivityAttributes.self) { context in
      // Lock Screen / Banner — широкая плашка.
      LockScreenView(
        senderName: context.attributes.senderName,
        position: context.state.positionSeconds,
        total: context.attributes.totalSeconds,
        isPlaying: context.state.isPlaying
      )
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .activityBackgroundTint(Color.black.opacity(0.85))
      .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      // iPhone 14 Pro / 15+ / 16 — Dynamic Island в трёх режимах.
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: context.state.isPlaying
                ? "waveform"
                : "mic.fill")
            .font(.title2)
            .foregroundStyle(Color(red: 0.7, green: 0.6, blue: 1))
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(formatTime(context.state.positionSeconds))
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundStyle(.secondary)
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading, spacing: 2) {
            Text(context.attributes.senderName)
              .font(.system(size: 14, weight: .semibold))
              .lineLimit(1)
            Text("Voice message")
              .font(.system(size: 12, weight: .regular))
              .foregroundStyle(.secondary)
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          ProgressBar(progress: progress(context))
        }
      } compactLeading: {
        Image(systemName: "waveform")
          .foregroundStyle(Color(red: 0.7, green: 0.6, blue: 1))
      } compactTrailing: {
        Text(formatTime(context.state.positionSeconds))
          .font(.system(size: 12, weight: .semibold, design: .monospaced))
      } minimal: {
        Image(systemName: "waveform")
          .foregroundStyle(Color(red: 0.7, green: 0.6, blue: 1))
      }
    }
  }

  private func progress(
    _ context: ActivityViewContext<VoiceActivityAttributes>
  ) -> Double {
    let total = context.attributes.totalSeconds
    if total <= 0.001 { return 0 }
    return min(max(context.state.positionSeconds / total, 0), 1)
  }

  private func formatTime(_ seconds: Double) -> String {
    let s = Int(seconds.rounded())
    let m = s / 60
    let r = s % 60
    return String(format: "%d:%02d", m, r)
  }
}

@available(iOS 16.1, *)
private struct LockScreenView: View {
  let senderName: String
  let position: Double
  let total: Double
  let isPlaying: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 10) {
        Image(systemName: isPlaying ? "waveform" : "pause.fill")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(Color(red: 0.8, green: 0.7, blue: 1))
          .frame(width: 28, height: 28)
          .background(Color.white.opacity(0.1))
          .clipShape(Circle())
        VStack(alignment: .leading, spacing: 2) {
          Text(senderName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
          Text("Voice message")
            .font(.system(size: 12))
            .foregroundStyle(.white.opacity(0.6))
        }
        Spacer()
        Text(formatTime(position))
          .font(.system(size: 12, weight: .semibold, design: .monospaced))
          .foregroundStyle(.white.opacity(0.7))
      }
      ProgressBar(progress: progressRatio)
    }
  }

  private var progressRatio: Double {
    total <= 0.001 ? 0 : min(max(position / total, 0), 1)
  }

  private func formatTime(_ seconds: Double) -> String {
    let s = Int(seconds.rounded())
    let m = s / 60
    let r = s % 60
    return String(format: "%d:%02d", m, r)
  }
}

@available(iOS 16.1, *)
private struct ProgressBar: View {
  let progress: Double
  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(Color.white.opacity(0.18))
        Capsule()
          .fill(
            LinearGradient(
              colors: [
                Color(red: 0.92, green: 0.85, blue: 1.0),
                Color(red: 0.7, green: 0.6, blue: 1.0),
              ],
              startPoint: .leading,
              endPoint: .trailing))
          .frame(width: max(2, proxy.size.width * progress))
      }
    }
    .frame(height: 3)
  }
}

/// Entry point — должен быть в Widget Extension Bundle.
@available(iOS 16.1, *)
@main
struct VoiceActivityBundle: WidgetBundle {
  var body: some Widget {
    VoiceActivityWidget()
  }
}
