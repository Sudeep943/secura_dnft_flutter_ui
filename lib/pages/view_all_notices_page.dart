import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

import '../services/api_service.dart';
import '../services/notice_models.dart';

class ViewAllNoticesPage extends StatefulWidget {
  const ViewAllNoticesPage({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<ViewAllNoticesPage> createState() => _ViewAllNoticesPageState();
}

class _ViewAllNoticesPageState extends State<ViewAllNoticesPage> {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  bool _loading = true;
  String? _errorMessage;
  List<NoticeSummary> _notices = [];

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  Future<void> _loadNotices() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final genericHeader = ApiService.userHeader;
      if (genericHeader == null || genericHeader.isEmpty) {
        setState(() {
          _loading = false;
          _errorMessage =
              'Login header details are not available for this request.';
        });
        return;
      }

      final response = await ApiService.getNoticeRequest(
        NoticeQueryRequest(
          genericHeader: Map<String, dynamic>.from(genericHeader),
        ),
      );
      if (!mounted) {
        return;
      }

      if (!_isSuccessResponse(response)) {
        setState(() {
          _loading = false;
          _errorMessage = _responseMessage(response);
        });
        return;
      }

      final rawList = response?['noticeList'];
      final notices = rawList is List
          ? rawList
                .whereType<Map>()
                .map(
                  (entry) =>
                      NoticeSummary.fromMap(Map<String, dynamic>.from(entry)),
                )
                .toList()
          : <NoticeSummary>[];

      setState(() {
        _loading = false;
        _notices = notices;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = 'Unable to fetch notices right now.';
      });
    }
  }

  List<NoticeSummary> get _filteredNotices {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _notices;
    }

    return _notices.where((notice) {
      return notice.noticeId.toLowerCase().contains(query) ||
          notice.noticeHeader.toLowerCase().contains(query) ||
          notice.letterNumber.toLowerCase().contains(query) ||
          notice.shortDescription.toLowerCase().contains(query) ||
          notice.status.toLowerCase().contains(query);
    }).toList();
  }

  List<DataColumn> _buildColumns() {
    const headingStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );

    return const [
      DataColumn(label: Text('Notice Id', style: headingStyle)),
      DataColumn(label: Text('Publishing Date', style: headingStyle)),
      DataColumn(label: Text('Letter Number', style: headingStyle)),
      DataColumn(label: Text('Notice Header', style: headingStyle)),
      DataColumn(label: Text('Short Description', style: headingStyle)),
      DataColumn(label: Text('Status', style: headingStyle)),
      DataColumn(
        label: Center(child: Text('Document', style: headingStyle)),
      ),
    ];
  }

  Widget _buildStatusCell(String status) {
    final active =
        status.toUpperCase() == 'ACTIVE' ||
        status.toUpperCase() == 'PUBLISH' ||
        status.toUpperCase() == 'PUBLISHED';

    return Text(
      status,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: active ? Colors.green.shade700 : const Color(0xFF9A5A16),
      ),
    );
  }

  Future<_NoticeDocumentPayload?> _extractSummaryDocument(
    NoticeSummary notice,
  ) async {
    final rawValue = notice.noticeDocumentId.trim();
    if (rawValue.isEmpty || rawValue == '-') {
      return null;
    }

    if (_looksLikeDocumentUrl(rawValue)) {
      final resolved = rawValue.startsWith('/')
          ? '${ApiService.baseUrl}$rawValue'
          : rawValue;
      final uri = Uri.tryParse(resolved);
      if (uri != null && (uri.hasScheme || resolved.startsWith('http'))) {
        final response = await http.get(uri);
        if (response.statusCode >= 200 &&
            response.statusCode < 300 &&
            response.bodyBytes.isNotEmpty) {
          return _NoticeDocumentPayload(
            fileName:
                '${notice.noticeId}${_inferExtension(response.bodyBytes, uri.path)}',
            bytes: response.bodyBytes,
          );
        }
      }
    }

    final bytes = _decodeBase64Bytes(rawValue);
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    return _NoticeDocumentPayload(
      fileName: '${notice.noticeId}${_inferExtension(bytes, rawValue)}',
      bytes: bytes,
    );
  }

  Future<void> _showSummaryDocumentModal(NoticeSummary notice) async {
    final payload = await _extractSummaryDocument(notice);
    if (!mounted) {
      return;
    }

    if (payload == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notice document preview is not available.'),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          clipBehavior: Clip.antiAlias,
          backgroundColor: const Color(0xFFF7F4FB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            color: _brandColor,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Text(
              'Notice Document: ${notice.noticeId}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          content: SizedBox(
            width: 900,
            height: 680,
            child: _isPdf(payload.bytes)
                ? PdfPreview(
                    build: (_) async => payload.bytes,
                    allowPrinting: false,
                    allowSharing: false,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    useActions: false,
                    maxPageWidth: 700,
                    pdfFileName: payload.fileName,
                    loadingWidget: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              payload.bytes,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          actions: [
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _downloadDocumentPayload(payload);
              },
              style: FilledButton.styleFrom(backgroundColor: _brandColor),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadDocumentPayload(_NoticeDocumentPayload payload) async {
    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Download Notice Document',
      fileName: payload.fileName,
      type: FileType.custom,
      allowedExtensions: payload.fileName.toLowerCase().endsWith('.pdf')
          ? ['pdf']
          : ['png', 'jpg', 'jpeg', 'webp'],
      bytes: payload.bytes,
      lockParentWindow: true,
    );

    if (!mounted || savedPath == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notice document downloaded successfully.')),
    );
  }

  Widget _buildDocumentCell(NoticeSummary notice) {
    final hasDocument =
        notice.noticeDocumentId.trim().isNotEmpty &&
        notice.noticeDocumentId.trim() != '-';
    if (!hasDocument) {
      return const Text('No Document');
    }

    return Tooltip(
      message: 'Open Document',
      child: IconButton(
        onPressed: () => _showSummaryDocumentModal(notice),
        icon: const Icon(Icons.description_rounded, color: _brandColor),
      ),
    );
  }

  List<DataRow> _buildRows() {
    final notices = _filteredNotices;
    return notices.map((notice) {
      final shortDescription = notice.shortDescription.length > 80
          ? '${notice.shortDescription.substring(0, 80)}...'
          : notice.shortDescription;

      return DataRow(
        cells: [
          DataCell(Text(notice.noticeId)),
          DataCell(Text(_formatDate(notice.publishingDate))),
          DataCell(
            Text(notice.letterNumber.isEmpty ? '-' : notice.letterNumber),
          ),
          DataCell(
            SizedBox(
              width: 240,
              child: Text(
                notice.noticeHeader,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          DataCell(
            SizedBox(
              width: 320,
              child: Text(
                shortDescription,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
          ),
          DataCell(_buildStatusCell(notice.status)),
          DataCell(_buildDocumentCell(notice)),
        ],
      );
    }).toList();
  }

  Widget _buildSearchBar() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: _isMobile(context) ? 280 : 380,
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Search by Notice Id, Header, or Letter Number',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          ),
          onPressed: _loadNotices,
          child: const Text('Refresh'),
        ),
        OutlinedButton(
          onPressed: () {
            _searchController.clear();
            setState(() {});
          },
          child: const Text('Reset'),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadNotices,
                style: FilledButton.styleFrom(backgroundColor: _brandColor),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notices.isEmpty) {
      return const Center(child: Text('No notices are available yet.'));
    }

    final filteredNotices = _filteredNotices;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1760),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: filteredNotices.isEmpty
                      ? const Center(
                          child: Text(
                            'No notices found for the current search.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final desktopWidth = constraints.maxWidth;
                            final tableMinWidth = _isMobile(context)
                                ? 1180.0
                                : 1540.0;

                            return Scrollbar(
                              controller: _horizontalScrollController,
                              thumbVisibility: _isMobile(context),
                              trackVisibility: _isMobile(context),
                              notificationPredicate: (notification) {
                                return notification.metrics.axis ==
                                    Axis.horizontal;
                              },
                              child: SingleChildScrollView(
                                controller: _horizontalScrollController,
                                scrollDirection: Axis.horizontal,
                                physics: _isMobile(context)
                                    ? const AlwaysScrollableScrollPhysics()
                                    : const NeverScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: math.max(
                                      desktopWidth,
                                      tableMinWidth,
                                    ),
                                  ),
                                  child: Scrollbar(
                                    controller: _verticalScrollController,
                                    thumbVisibility: true,
                                    trackVisibility: true,
                                    notificationPredicate: (notification) {
                                      return notification.metrics.axis ==
                                          Axis.vertical;
                                    },
                                    child: SingleChildScrollView(
                                      controller: _verticalScrollController,
                                      child: DataTable(
                                        headingRowColor:
                                            const WidgetStatePropertyAll(
                                              _brandColor,
                                            ),
                                        dataRowMinHeight: 72,
                                        dataRowMaxHeight: 96,
                                        columnSpacing: 40,
                                        horizontalMargin: 24,
                                        columns: _buildColumns(),
                                        rows: _buildRows(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.embedded && widget.onBack != null) ...[
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back, color: _brandColor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Expanded(
                    child: Text(
                      'Notices',
                      style: TextStyle(
                        color: _brandTextColor,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (widget.embedded)
                    IconButton(
                      onPressed: _loadNotices,
                      icon: const Icon(Icons.refresh_rounded),
                      color: _brandColor,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Browse the full notice list and open any notice on its own page for document preview and download.',
                style: TextStyle(color: Colors.black54, height: 1.45),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildBody()),
      ],
    );

    if (widget.embedded) {
      return pageContent;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      appBar: AppBar(
        backgroundColor: _brandColor,
        foregroundColor: Colors.white,
        title: const Text('View All Notice'),
        actions: [
          IconButton(
            onPressed: _loadNotices,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: pageContent,
    );
  }
}

class ViewNoticeDetailsPage extends StatefulWidget {
  const ViewNoticeDetailsPage({super.key, required this.notice});

  final NoticeSummary notice;

  @override
  State<ViewNoticeDetailsPage> createState() => _ViewNoticeDetailsPageState();
}

class _ViewNoticeDetailsPageState extends State<ViewNoticeDetailsPage> {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);

  bool _loading = true;
  String? _errorMessage;
  Map<String, dynamic> _noticeDetail = <String, dynamic>{};
  _NoticeDocumentPayload? _documentPayload;

  @override
  void initState() {
    super.initState();
    _loadNoticeDetails();
  }

  Future<void> _loadNoticeDetails() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final genericHeader = ApiService.userHeader;
      if (genericHeader == null || genericHeader.isEmpty) {
        setState(() {
          _loading = false;
          _errorMessage =
              'Login header details are not available for this request.';
        });
        return;
      }

      final response = await ApiService.getNoticeRequest(
        NoticeQueryRequest(
          genericHeader: Map<String, dynamic>.from(genericHeader),
          noticeId: widget.notice.noticeId,
        ),
      );
      if (!mounted) {
        return;
      }

      if (!_isSuccessResponse(response)) {
        setState(() {
          _loading = false;
          _errorMessage = _responseMessage(response);
        });
        return;
      }

      Map<String, dynamic> detail = response ?? <String, dynamic>{};
      final rawList = response?['noticeList'];
      if (rawList is List && rawList.isNotEmpty && rawList.first is Map) {
        detail = Map<String, dynamic>.from(rawList.first as Map);
      }

      final payload = await _extractNoticeDocument(
        detail,
        widget.notice.noticeId,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _noticeDetail = detail;
        _documentPayload = payload;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = 'Unable to load this notice right now.';
      });
    }
  }

  Future<void> _downloadDocument() async {
    final payload = _documentPayload;
    if (payload == null) {
      return;
    }

    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Download Notice Document',
      fileName: payload.fileName,
      type: FileType.custom,
      allowedExtensions: payload.fileName.toLowerCase().endsWith('.pdf')
          ? ['pdf']
          : ['png', 'jpg', 'jpeg', 'webp'],
      bytes: payload.bytes,
      lockParentWindow: true,
    );

    if (!mounted || savedPath == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notice document downloaded successfully.')),
    );
  }

  TableRow _buildDetailRow(String label, String value) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE3ECEA))),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _brandTextColor,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            value,
            style: const TextStyle(height: 1.45, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final payload = _documentPayload;
    if (payload == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('No notice document is available for preview.'),
      );
    }

    if (_isPdf(payload.bytes)) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.picture_as_pdf_rounded,
              size: 72,
              color: Color(0xFFB3261E),
            ),
            SizedBox(height: 12),
            Text(
              'Preview is not available for PDF documents. Use the download button to save the file.',
              style: TextStyle(height: 1.45),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F7),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: InteractiveViewer(
        minScale: 0.8,
        maxScale: 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(payload.bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = _noticeDetail;
    final shortDescription =
        (detail['noticeShortDescription'] ??
                detail['shortDetails'] ??
                widget.notice.shortDescription)
            .toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      appBar: AppBar(
        backgroundColor: _brandColor,
        foregroundColor: Colors.white,
        title: const Text('Notice Details'),
        actions: [
          IconButton(
            onPressed: _loadNoticeDetails,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadNoticeDetails,
                      style: FilledButton.styleFrom(
                        backgroundColor: _brandColor,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFD8E5E2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.notice.noticeHeader,
                          style: const TextStyle(
                            color: _brandTextColor,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Table(
                          columnWidths: const {
                            0: FixedColumnWidth(220),
                            1: FlexColumnWidth(),
                          },
                          children: [
                            _buildDetailRow(
                              'Notice Id',
                              widget.notice.noticeId,
                            ),
                            _buildDetailRow(
                              'Letter Number',
                              widget.notice.letterNumber.isEmpty
                                  ? '-'
                                  : widget.notice.letterNumber,
                            ),
                            _buildDetailRow(
                              'Publishing Date',
                              _formatDate(
                                (detail['publishingDate'] ??
                                        widget.notice.publishingDate)
                                    .toString(),
                              ),
                            ),
                            _buildDetailRow(
                              'Status',
                              (detail['status'] ??
                                      detail['opeartion'] ??
                                      widget.notice.status)
                                  .toString(),
                            ),
                            _buildDetailRow(
                              'Notice Document Id',
                              (detail['noticeDocumentId'] ??
                                      widget.notice.noticeDocumentId)
                                  .toString(),
                            ),
                            _buildDetailRow(
                              'Short Description',
                              shortDescription,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Notice Document',
                          style: TextStyle(
                            color: _brandTextColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_documentPayload != null)
                        FilledButton.icon(
                          onPressed: _downloadDocument,
                          style: FilledButton.styleFrom(
                            backgroundColor: _brandColor,
                          ),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Download'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPreview(),
                ],
              ),
            ),
    );
  }
}

bool _isSuccessResponse(Map<String, dynamic>? response) {
  if (response == null) {
    return false;
  }

  final messageCode = response['messageCode']?.toString() ?? '';
  if (messageCode.toUpperCase().startsWith('SUCC')) {
    return true;
  }

  final status = response['status']?.toString().toLowerCase() ?? '';
  return status == 'success' || status == 'true';
}

String _responseMessage(Map<String, dynamic>? response) {
  if (response == null) {
    return 'The server did not return a valid response.';
  }

  final candidates = [
    response['message'],
    response['statusMessage'],
    response['description'],
  ];
  for (final candidate in candidates) {
    final value = candidate?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return value;
    }
  }

  return 'Unable to fetch notices.';
}

String _formatDate(String rawValue) {
  final parsed = DateTime.tryParse(rawValue);
  if (parsed == null) {
    return rawValue;
  }

  String twoDigits(int part) => part.toString().padLeft(2, '0');
  return '${parsed.year}-${twoDigits(parsed.month)}-${twoDigits(parsed.day)} ${twoDigits(parsed.hour)}:${twoDigits(parsed.minute)}';
}

Uint8List? _decodeBase64Bytes(String rawValue) {
  final value = rawValue.trim();
  if (value.isEmpty) {
    return null;
  }

  final normalized = value.startsWith('data:') && value.contains(',')
      ? value.substring(value.indexOf(',') + 1)
      : value;
  final compact = normalized.replaceAll(RegExp(r'\s+'), '');

  try {
    return base64Decode(compact);
  } catch (_) {
    try {
      return base64Decode(Uri.decodeComponent(compact));
    } catch (_) {
      return null;
    }
  }
}

bool _looksLikeDocumentUrl(String value) {
  final trimmed = value.trim().toLowerCase();
  return trimmed.startsWith('http://') ||
      trimmed.startsWith('https://') ||
      trimmed.startsWith('/') ||
      trimmed.endsWith('.png') ||
      trimmed.endsWith('.jpg') ||
      trimmed.endsWith('.jpeg') ||
      trimmed.endsWith('.webp') ||
      trimmed.endsWith('.pdf');
}

bool _looksLikeEncodedDocument(String value) {
  final trimmed = value.trim();
  if (trimmed.startsWith('data:')) {
    return true;
  }

  if (trimmed.length < 80) {
    return false;
  }

  return RegExp(r'^[A-Za-z0-9+/=%\s]+$').hasMatch(trimmed);
}

Iterable<String> _collectDocumentCandidates(dynamic value) sync* {
  const candidateKeys = [
    'noticeDoc',
    'noticeDocument',
    'noticeDocumet',
    'noticeImage',
    'documentCode',
    'documentUrl',
    'documentPath',
    'fileUrl',
    'filePath',
    'fileData',
    'base64',
    'content',
    'bytes',
  ];

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }

    if (_looksLikeDocumentUrl(trimmed) || _looksLikeEncodedDocument(trimmed)) {
      yield trimmed;
    }
    return;
  }

  if (value is Map) {
    for (final key in candidateKeys) {
      if (value.containsKey(key)) {
        yield* _collectDocumentCandidates(value[key]);
      }
    }
    for (final entry in value.values) {
      yield* _collectDocumentCandidates(entry);
    }
    return;
  }

  if (value is Iterable) {
    for (final entry in value) {
      yield* _collectDocumentCandidates(entry);
    }
  }
}

bool _isPdf(Uint8List bytes) {
  return bytes.length >= 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;
}

Future<_NoticeDocumentPayload?> _extractNoticeDocument(
  Map<String, dynamic> detail,
  String noticeId,
) async {
  final visited = <String>{};
  for (final raw in _collectDocumentCandidates(detail)) {
    if (!visited.add(raw)) {
      continue;
    }

    final source = raw.trim();
    if (_looksLikeDocumentUrl(source)) {
      final resolved = source.startsWith('/')
          ? '${ApiService.baseUrl}$source'
          : source;
      final uri = Uri.tryParse(resolved);
      if (uri != null && (uri.hasScheme || resolved.startsWith('http'))) {
        final response = await http.get(uri);
        if (response.statusCode >= 200 &&
            response.statusCode < 300 &&
            response.bodyBytes.isNotEmpty) {
          return _NoticeDocumentPayload(
            fileName:
                '$noticeId${_inferExtension(response.bodyBytes, uri.path)}',
            bytes: response.bodyBytes,
          );
        }
      }
    }

    final bytes = _decodeBase64Bytes(source);
    if (bytes != null && bytes.isNotEmpty) {
      return _NoticeDocumentPayload(
        fileName: '$noticeId${_inferExtension(bytes, source)}',
        bytes: bytes,
      );
    }
  }

  return null;
}

String _inferExtension(Uint8List bytes, String pathHint) {
  final lowerPath = pathHint.toLowerCase();
  if (lowerPath.endsWith('.pdf') || _isPdf(bytes)) {
    return '.pdf';
  }
  if (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg')) {
    return '.jpg';
  }
  if (lowerPath.endsWith('.webp')) {
    return '.webp';
  }
  return '.png';
}

class _NoticeDocumentPayload {
  const _NoticeDocumentPayload({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}
