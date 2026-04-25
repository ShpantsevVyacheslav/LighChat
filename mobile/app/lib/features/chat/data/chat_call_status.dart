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
}) {
  switch (rawStatus) {
    case 'ended':
      return 'ended';
    case 'cancelled':
      return 'cancelled';
    case 'missed':
      return viewerIsReceiver ? 'missed' : 'cancelled';
    case 'rejected':
      return viewerIsReceiver ? 'missed' : 'cancelled';
    default:
      return 'ended';
  }
}

String callStatusLabelRu(String resolvedStatus) {
  switch (resolvedStatus) {
    case 'missed':
      return 'Пропущен';
    case 'cancelled':
      return 'Отменен';
    case 'ended':
    default:
      return 'Завершен';
  }
}
