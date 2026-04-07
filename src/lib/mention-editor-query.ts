/**
 * Логика режима @ в поле ввода: после полного имени участника и пробела
 * дальше идёт обычный текст — подсказку не показываем (null).
 */
export function resolveMentionQueryFromAfterAt(
  textAfterAt: string,
  participantNamesSortedLongestFirst: string[]
): string | null {
  const afterAt = textAfterAt;
  if (!participantNamesSortedLongestFirst.length) {
    return afterAt;
  }
  for (const raw of participantNamesSortedLongestFirst) {
    const name = raw.trim();
    if (!name) continue;
    // Полное имя/username + пробел + любой продолжение текста — упоминание завершено
    if (afterAt.startsWith(name + ' ')) {
      return null;
    }
    // Курсор сразу после полного совпадения без пробела — список не нужен
    if (afterAt === name) {
      return null;
    }
  }
  return afterAt;
}

/** Имена и username для границы упоминаний; длинные строки первыми. */
export function buildMentionBoundaryNameList(namesAndUsernames: string[]): string[] {
  const uniq = [...new Set(namesAndUsernames.map((s) => s.trim()).filter(Boolean))];
  uniq.sort((a, b) => b.length - a.length);
  return uniq;
}
