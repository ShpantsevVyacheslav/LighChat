import { describe, expect, it } from 'vitest';
import {
  isTerminalCallStatus,
  resolveCallOutcomeForViewer,
  TERMINAL_CALL_STATUSES,
} from '@/lib/call-status';
import type { Call } from '@/lib/types';

/**
 * [audit M-013] Call status resolver — UX critical для истории звонков.
 * `resolveCallOutcomeForViewer` определяет иконку (исходящий/входящий
 * missed/ended). Регрессия → у receiver-а пропущенный звонок виден как
 * «отменён» или наоборот.
 */

describe('TERMINAL_CALL_STATUSES', () => {
  it('содержит все терминальные статусы', () => {
    expect([...TERMINAL_CALL_STATUSES].sort()).toEqual(
      ['cancelled', 'ended', 'missed', 'rejected'],
    );
  });
});

describe('isTerminalCallStatus', () => {
  it('terminal статусы → true', () => {
    expect(isTerminalCallStatus('ended')).toBe(true);
    expect(isTerminalCallStatus('cancelled')).toBe(true);
    expect(isTerminalCallStatus('missed')).toBe(true);
    expect(isTerminalCallStatus('rejected')).toBe(true);
  });

  it('non-terminal → false', () => {
    expect(isTerminalCallStatus('ringing')).toBe(false);
    expect(isTerminalCallStatus('active')).toBe(false);
    expect(isTerminalCallStatus('unknown')).toBe(false);
  });
});

describe('resolveCallOutcomeForViewer', () => {
  function call(status: Call['status']): Pick<Call, 'status' | 'callerId' | 'receiverId'> {
    return { status, callerId: 'caller', receiverId: 'receiver' };
  }

  it('ended → ended для обоих', () => {
    expect(resolveCallOutcomeForViewer(call('ended'), 'caller')).toBe('ended');
    expect(resolveCallOutcomeForViewer(call('ended'), 'receiver')).toBe('ended');
  });

  it('cancelled → cancelled для обоих', () => {
    expect(resolveCallOutcomeForViewer(call('cancelled'), 'caller')).toBe('cancelled');
    expect(resolveCallOutcomeForViewer(call('cancelled'), 'receiver')).toBe('cancelled');
  });

  it('missed: для receiver — "missed", для caller — "cancelled"', () => {
    // Receiver видит «пропущенный звонок»; caller видит «отменён» (т.е. кому-то
    // не дозвонился). Это UX-различие иконок.
    expect(resolveCallOutcomeForViewer(call('missed'), 'receiver')).toBe('missed');
    expect(resolveCallOutcomeForViewer(call('missed'), 'caller')).toBe('cancelled');
  });

  it('rejected (legacy unanswered): то же поведение как missed', () => {
    expect(resolveCallOutcomeForViewer(call('rejected'), 'receiver')).toBe('missed');
    expect(resolveCallOutcomeForViewer(call('rejected'), 'caller')).toBe('cancelled');
  });

  it('non-terminal status → fallback "ended" (defensive)', () => {
    // Cast через unknown — 'ringing' не в CallStatus union, но рантайм может
    // прийти от mobile-клиента со старым enum. Проверяем defensive default.
    expect(
      resolveCallOutcomeForViewer(
        { status: 'ringing', callerId: 'c', receiverId: 'r' } as unknown as Pick<Call, 'status' | 'callerId' | 'receiverId'>,
        'r',
      ),
    ).toBe('ended');
  });

  it('viewer не участник звонка — fallback на "cancelled" (только receiver matching → missed)', () => {
    expect(resolveCallOutcomeForViewer(call('missed'), 'third_party')).toBe('cancelled');
  });
});
