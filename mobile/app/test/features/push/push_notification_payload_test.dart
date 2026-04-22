import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/push/push_notification_payload.dart';

void main() {
  test('conversationIdFromPushData prefers explicit field', () {
    expect(
      conversationIdFromPushData(<String, dynamic>{
        'conversationId': 'dm_abc',
        'link': '/dashboard/chat?conversationId=other',
      }),
      'dm_abc',
    );
  });

  test('parseConversationIdFromDashboardChatLink handles relative path', () {
    expect(
      parseConversationIdFromDashboardChatLink(
        '/dashboard/chat?conversationId=x1&foo=1',
      ),
      'x1',
    );
  });
}
