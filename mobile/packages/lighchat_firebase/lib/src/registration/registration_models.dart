class RegistrationData {
  RegistrationData({
    required this.name,
    required this.username,
    required this.phone,
    required this.email,
    required this.password,
    required this.dateOfBirth,
    required this.bio,
    required this.avatarFullJpeg,
    required this.avatarThumbPng,
  });

  final String name;
  final String username;
  final String phone;
  final String email;
  final String password;
  final String? dateOfBirth; // yyyy-mm-dd
  final String? bio;

  /// Cropped square full image (jpeg).
  final List<int>? avatarFullJpeg;

  /// Circle 512x512 thumb (png with alpha).
  final List<int>? avatarThumbPng;
}

class GoogleProfileCompletionData {
  GoogleProfileCompletionData({
    required this.name,
    required this.username,
    required this.phone,
    required this.email,
    required this.dateOfBirth,
    required this.bio,
    required this.avatarFullJpeg,
    required this.avatarThumbPng,
  });

  final String name;
  final String username;
  final String phone;
  final String email;
  final String? dateOfBirth;
  final String? bio;
  final List<int>? avatarFullJpeg;
  final List<int>? avatarThumbPng;
}

class RegistrationConflict implements Exception {
  RegistrationConflict({required this.message, required this.field});

  final String message;
  final String field; // email|username|phone|password

  @override
  String toString() => 'RegistrationConflict(field: $field, message: $message)';
}

