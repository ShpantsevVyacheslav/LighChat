import '../../../l10n/app_localizations.dart';

const Set<String> terminalCallStatuses = <String>{
  'ended',
  'cancelled',
  'missed',
  // Legacy value in old documents.
  'rejected',
};

bool isTerminalCallStatus(String rawStatus) {
  return terminalCallStatuses.contains(rawStatus);
}

String resolveCallTerminalStatusForViewer({
  required String rawStatus,
  required bool viewerIsReceiver,
  String? callerId,
  String? receiverId,
  String? endedBy,
}) {
  final endedById = (endedBy ?? '').trim();
  final caller = (callerId ?? '').trim();
  final receiver = (receiverId ?? '').trim();
  switch (rawStatus) {
    case 'ended':
      return 'ended';
    case 'cancelled':
      if (viewerIsReceiver &&
          endedById.isNotEmpty &&
          caller.isNotEmpty &&
          receiver.isNotEmpty) {
        if (endedById == caller) {
          return 'missed';
        }
        if (endedById == receiver) {
          return 'cancelled';
        }
      }
      return 'cancelled';
    case 'missed':
      return viewerIsReceiver ? 'missed' : 'cancelled';
    case 'rejected':
      return viewerIsReceiver ? 'missed' : 'cancelled';
    default:
      return 'ended';
  }
}

String callStatusLabel(String resolvedStatus, AppLocalizations l10n) {
  switch (resolvedStatus) {
    case 'missed':
      return l10n.call_status_missed;
    case 'cancelled':
      return l10n.call_status_cancelled;
    case 'ended':
    default:
      return l10n.call_status_ended;
  }
}
