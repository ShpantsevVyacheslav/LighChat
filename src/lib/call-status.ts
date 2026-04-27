import type { Call, CallStatus } from '@/lib/types';

export type ResolvedCallOutcome = 'ended' | 'cancelled' | 'missed';

export const TERMINAL_CALL_STATUSES: ReadonlySet<CallStatus> = new Set<CallStatus>([
  'ended',
  'cancelled',
  'missed',
  'rejected',
]);

export function isTerminalCallStatus(status: string): boolean {
  return TERMINAL_CALL_STATUSES.has(status as CallStatus);
}

export function resolveCallOutcomeForViewer(
  call: Pick<Call, 'status' | 'callerId' | 'receiverId'>,
  viewerId: string
): ResolvedCallOutcome {
  switch (call.status) {
    case 'ended':
      return 'ended';
    case 'cancelled':
      return 'cancelled';
    case 'missed':
      return call.receiverId === viewerId ? 'missed' : 'cancelled';
    case 'rejected':
      // Legacy mapping: old `rejected` values were used for unanswered calls.
      return call.receiverId === viewerId ? 'missed' : 'cancelled';
    default:
      return 'ended';
  }
}
