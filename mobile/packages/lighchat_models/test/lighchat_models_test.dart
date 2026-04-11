import 'package:flutter_test/flutter_test.dart';

import 'package:lighchat_models/lighchat_models.dart';

void main() {
  test('UserChatIndex.fromJson parses ids', () {
    final idx = UserChatIndex.fromJson({
      'conversationIds': ['a', 'b', '', 123],
    });
    expect(idx.conversationIds, ['a', 'b']);
  });
}
