import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:lighchat_mobile/features/chat/ui/chat_document_open.dart';

void main() {
  ChatAttachment attachment({
    required String url,
    required String name,
    String? type,
  }) {
    return ChatAttachment(url: url, name: name, type: type);
  }

  test('isChatDocumentPreviewCandidate returns true for pdf mime', () {
    final a = attachment(
      url: 'https://example.com/file',
      name: 'file',
      type: 'application/pdf',
    );
    expect(isChatDocumentPreviewCandidate(a), isTrue);
  });

  test('isChatDocumentPreviewCandidate returns true for text mime', () {
    final a = attachment(
      url: 'https://example.com/readme',
      name: 'readme',
      type: 'text/plain',
    );
    expect(isChatDocumentPreviewCandidate(a), isTrue);
  });

  test('isChatDocumentPreviewCandidate returns true for docx extension', () {
    final a = attachment(
      url: 'https://example.com/files/contract',
      name: 'contract.docx',
    );
    expect(isChatDocumentPreviewCandidate(a), isTrue);
  });

  test('isChatDocumentPreviewCandidate returns false for images', () {
    final a = attachment(
      url: 'https://example.com/image.jpg',
      name: 'image.jpg',
      type: 'image/jpeg',
    );
    expect(isChatDocumentPreviewCandidate(a), isFalse);
  });

  test('isChatDocumentPreviewCandidate returns false for unknown binary', () {
    final a = attachment(url: 'https://example.com/blob', name: 'blob');
    expect(isChatDocumentPreviewCandidate(a), isFalse);
  });

  test('isChatPdfPreviewCandidate returns true for pdf mime', () {
    final a = attachment(
      url: 'https://example.com/file',
      name: 'file',
      type: 'application/pdf',
    );
    expect(isChatPdfPreviewCandidate(a), isTrue);
  });

  test('isChatPdfPreviewCandidate returns true for .pdf extension', () {
    final a = attachment(
      url: 'https://example.com/media/certificate',
      name: 'certificate.pdf',
    );
    expect(isChatPdfPreviewCandidate(a), isTrue);
  });

  test('isChatPdfPreviewCandidate returns false for non-pdf documents', () {
    final a = attachment(
      url: 'https://example.com/media/readme.txt',
      name: 'readme.txt',
      type: 'text/plain',
    );
    expect(isChatPdfPreviewCandidate(a), isFalse);
  });
}
