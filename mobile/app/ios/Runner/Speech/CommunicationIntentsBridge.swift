import Flutter
import Foundation
import Intents
import UIKit

/// Bridge для `INSendMessageIntent` donations — даёт iOS-системе подсказки
/// для Siri Suggestions, Communication Notifications и handoff. Без
/// Notification Service Extension не сможем перерисовать локскрин-карточку
/// при APNS-доставке, но donate-flow всё равно даёт богатые подсказки
/// «продолжить общение с X» в Spotlight и Share Sheet.
///
/// Channel: `lighchat/communication_intents`. Метод:
///  - `donate(senderUid, senderName, avatarPath, conversationId, body, isGroup)`
final class CommunicationIntentsBridge: NSObject {
  static let shared = CommunicationIntentsBridge()

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lighchat/communication_intents", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "donate":
      let args = call.arguments as? [String: Any] ?? [:]
      donate(args: args)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func donate(args: [String: Any]) {
    guard #available(iOS 15.0, *) else { return }
    let senderUid = (args["senderUid"] as? String) ?? ""
    let senderName = (args["senderName"] as? String) ?? ""
    let conversationId = (args["conversationId"] as? String) ?? ""
    let body = (args["body"] as? String) ?? ""
    let avatarPath = args["avatarPath"] as? String
    let isGroup = (args["isGroup"] as? Bool) ?? false
    if senderUid.isEmpty || senderName.isEmpty || conversationId.isEmpty {
      return
    }

    let handle = INPersonHandle(value: senderUid, type: .unknown)
    var avatarImage: INImage?
    if let path = avatarPath, !path.isEmpty {
      let url = URL(fileURLWithPath: path)
      avatarImage = INImage(url: url)
    }
    let sender = INPerson(
      personHandle: handle,
      nameComponents: nil,
      displayName: senderName,
      image: avatarImage,
      contactIdentifier: nil,
      customIdentifier: senderUid
    )

    let intent = INSendMessageIntent(
      recipients: nil,
      outgoingMessageType: .outgoingMessageText,
      content: body,
      speakableGroupName: isGroup
        ? INSpeakableString(spokenPhrase: senderName) : nil,
      conversationIdentifier: conversationId,
      serviceName: "LighChat",
      sender: sender,
      attachments: nil
    )
    if let img = avatarImage {
      intent.setImage(img, forParameterNamed: \.sender)
    }

    let interaction = INInteraction(intent: intent, response: nil)
    interaction.direction = .incoming
    interaction.donate { error in
      if let error = error {
        NSLog("[CommIntents] donate failed: %@", "\(error)")
      }
    }
  }
}
