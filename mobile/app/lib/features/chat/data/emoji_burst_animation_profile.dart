const String chatEmojiBurstAnimationProfileLite = 'lite';
const String chatEmojiBurstAnimationProfileBalanced = 'balanced';
const String chatEmojiBurstAnimationProfileCinematic = 'cinematic';

const Set<String> chatEmojiBurstAnimationProfiles = <String>{
  chatEmojiBurstAnimationProfileLite,
  chatEmojiBurstAnimationProfileBalanced,
  chatEmojiBurstAnimationProfileCinematic,
};

String normalizeChatEmojiBurstAnimationProfile(String? raw) {
  final v = raw?.trim().toLowerCase();
  if (chatEmojiBurstAnimationProfiles.contains(v)) {
    return v!;
  }
  return chatEmojiBurstAnimationProfileBalanced;
}
