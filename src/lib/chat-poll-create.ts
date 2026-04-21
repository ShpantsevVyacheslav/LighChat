/**
 * Создание опроса в чате (паритет мобильного клиента и `ChatAttachPollDialog`).
 */
export type ChatPollCreateInput = {
  question: string;
  /** Пояснение под вопросом (как в Telegram). */
  description?: string;
  options: string[];
  /** true — без имён голосов; false — видно, кто за что. */
  isAnonymous: boolean;
  allowMultipleAnswers?: boolean;
  allowAddingOptions?: boolean;
  /** По умолчанию true в UI; false — нельзя сменить голос. */
  allowRevoting?: boolean;
  shuffleOptions?: boolean;
  quizMode?: boolean;
  correctOptionIndex?: number | null;
  quizExplanation?: string | null;
  /** ISO-8601 UTC/local — авто-завершение. */
  closesAt?: string | null;
};

/** Поля документа `conversations/.../polls/{id}` без `createdAt` (его кладёт caller как serverTimestamp). */
export function chatPollFirestoreFields(
  input: ChatPollCreateInput,
  pollId: string,
  creatorId: string
): Record<string, unknown> {
  const q = input.question.trim();
  const opts = input.options.map((o) => o.trim()).filter(Boolean);
  const doc: Record<string, unknown> = {
    id: pollId,
    question: q,
    options: opts,
    creatorId,
    status: 'active',
    isAnonymous: input.isAnonymous,
    votes: {},
  };
  const desc = input.description?.trim();
  if (desc) doc.description = desc;
  if (input.allowMultipleAnswers === true) doc.allowMultipleAnswers = true;
  if (input.allowAddingOptions === true) doc.allowAddingOptions = true;
  if (input.allowRevoting === false) doc.allowRevoting = false;
  if (input.shuffleOptions === true) doc.shuffleOptions = true;
  if (input.quizMode === true && input.correctOptionIndex != null) {
    doc.quizMode = true;
    doc.correctOptionIndex = input.correctOptionIndex;
    const ex = input.quizExplanation?.trim();
    if (ex) doc.quizExplanation = ex;
  }
  const closes = input.closesAt?.trim();
  if (closes) doc.closesAt = closes;
  return doc;
}
