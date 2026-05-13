import 'package:lighchat_mobile/features/chat/data/user_profile.dart';

/// Доменная модель именинника для UI-слоя — собирает имя/аватар из
/// `contactProfiles` (для мгновенного отображения без сети) или из
/// подгруженного `UserProfile`.
class ContactBirthday {
  const ContactBirthday({
    required this.userId,
    required this.displayName,
    required this.birthDate,
    this.avatarUrl,
    this.avatarThumb,
    this.username,
    this.profile,
  });

  final String userId;
  final String displayName;
  final DateTime birthDate;
  final String? avatarUrl;
  final String? avatarThumb;
  final String? username;

  /// Полный профиль контакта если уже подгружен (нужен для `createOrOpenDirectChat`).
  final UserProfile? profile;
}
