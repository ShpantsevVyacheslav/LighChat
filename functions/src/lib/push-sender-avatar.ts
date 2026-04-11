/**
 * Превью аватара для пуша (как userAvatarListUrl на клиенте): thumb → avatar.
 */
export function senderListAvatarForPush(
  userData: Record<string, unknown> | undefined,
): string {
  if (!userData) return "";
  const thumb =
    typeof userData.avatarThumb === "string" ? userData.avatarThumb.trim() : "";
  if (thumb) return thumb;
  const av =
    typeof userData.avatar === "string" ? userData.avatar.trim() : "";
  return av;
}
