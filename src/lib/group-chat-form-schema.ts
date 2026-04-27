import * as z from 'zod';

export function createGroupChatFormSchema(nameRequiredMessage: string) {
  return z.object({
    name: z.string().min(1, nameRequiredMessage),
    description: z.string().optional(),
  });
}

export type GroupChatFormValues = z.infer<ReturnType<typeof createGroupChatFormSchema>>;
