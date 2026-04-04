class NoticeCreateRequest {
  const NoticeCreateRequest({
    required this.genericHeader,
    required this.noticeShortDescription,
    required this.noticeHeader,
    required this.publishingDate,
    required this.noticeDoc,
    required this.operation,
    this.letterNumber = '',
  });

  final Map<String, dynamic> genericHeader;
  final String noticeShortDescription;
  final String noticeHeader;
  final String publishingDate;
  final String letterNumber;
  final String noticeDoc;
  final String operation;

  Map<String, dynamic> toJson() {
    return {
      'genericHeader': Map<String, dynamic>.from(genericHeader),
      'noticeShortDescription': noticeShortDescription.trim(),
      'noticeHeader': noticeHeader.trim(),
      'publishingDate': publishingDate,
      'letterNumber': letterNumber.trim(),
      'noticeDoc': noticeDoc,
      'opeartion': operation.trim(),
    };
  }
}

class NoticeQueryRequest {
  const NoticeQueryRequest({required this.genericHeader, this.noticeId = ''});

  final Map<String, dynamic> genericHeader;
  final String noticeId;

  Map<String, dynamic> toJson() {
    return {
      'genericHeader': Map<String, dynamic>.from(genericHeader),
      'noticeId': noticeId.trim(),
    };
  }
}

class NoticeSummary {
  const NoticeSummary({
    required this.noticeId,
    required this.letterNumber,
    required this.noticeHeader,
    required this.shortDescription,
    required this.publishingDate,
    required this.status,
    required this.noticeDocumentId,
  });

  factory NoticeSummary.fromMap(Map<String, dynamic> map) {
    return NoticeSummary(
      noticeId: map['noticeId']?.toString() ?? '-',
      letterNumber: map['letterNumber']?.toString() ?? '',
      noticeHeader: map['noticeHeader']?.toString() ?? '-',
      shortDescription:
          (map['noticeShortDescription'] ?? map['shortDetails'] ?? '-')
              .toString(),
      publishingDate: map['publishingDate']?.toString() ?? '-',
      status: (map['status'] ?? map['opeartion'] ?? '-').toString(),
      noticeDocumentId: map['noticeDocumentId']?.toString() ?? '-',
    );
  }

  final String noticeId;
  final String letterNumber;
  final String noticeHeader;
  final String shortDescription;
  final String publishingDate;
  final String status;
  final String noticeDocumentId;
}
