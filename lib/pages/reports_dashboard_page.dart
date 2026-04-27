import 'dart:io';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../widgets/sidebar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dummy data
// ─────────────────────────────────────────────────────────────────────────────

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

// Monthly income & expense (in ₹ thousands)
const _incomeData = [
  120.0,
  145.0,
  132.0,
  160.0,
  155.0,
  178.0,
  165.0,
  190.0,
  175.0,
  200.0,
  188.0,
  210.0,
];
const _expenseData = [
  80.0,
  95.0,
  88.0,
  110.0,
  102.0,
  120.0,
  115.0,
  130.0,
  125.0,
  140.0,
  133.0,
  148.0,
];

// Expense categories (pie)
const _expensePieData = [
  _PieDatum('Maintenance', 32, Color(0xFF0F8F82)),
  _PieDatum('Utilities', 22, Color(0xFF26C6AD)),
  _PieDatum('Salaries', 18, Color(0xFFE0DA84)),
  _PieDatum('Security', 12, Color(0xFF124B45)),
  _PieDatum('Repairs', 10, Color(0xFFF4768A)),
  _PieDatum('Others', 6, Color(0xFFA8D8EA)),
];

// Income categories (pie)
const _incomePieData = [
  _PieDatum('Maintenance Fees', 45, Color(0xFF0F8F82)),
  _PieDatum('Parking Charges', 18, Color(0xFF26C6AD)),
  _PieDatum('Club House', 12, Color(0xFFE0DA84)),
  _PieDatum('Late Fees', 10, Color(0xFF124B45)),
  _PieDatum('Event Bookings', 9, Color(0xFFF4768A)),
  _PieDatum('Others', 6, Color(0xFFA8D8EA)),
];

// Expense per flat per month (₹)
const _expensePerFlat = [
  2400.0,
  2900.0,
  2650.0,
  3100.0,
  2950.0,
  3300.0,
  3150.0,
  3500.0,
  3250.0,
  3700.0,
  3450.0,
  3800.0,
];

// Income per flat per month (₹)
const _incomePerFlat = [
  3600.0,
  4100.0,
  3850.0,
  4400.0,
  4250.0,
  4700.0,
  4500.0,
  4900.0,
  4650.0,
  5100.0,
  4850.0,
  5300.0,
];

// Budget vs Actual (₹ thousands)
const _budgetData = [
  100.0,
  120.0,
  110.0,
  130.0,
  125.0,
  145.0,
  135.0,
  155.0,
  145.0,
  165.0,
  155.0,
  175.0,
];
const _actualData = [
  80.0,
  95.0,
  88.0,
  110.0,
  102.0,
  120.0,
  115.0,
  130.0,
  125.0,
  140.0,
  133.0,
  148.0,
];

class _PieDatum {
  const _PieDatum(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Report Sheet Dummy Data (tables)
// ─────────────────────────────────────────────────────────────────────────────

const _taxSheetRows = [
  ['Income Head', 'Gross (₹)', 'Taxable (₹)', 'Tax (₹)'],
  ['Maintenance Collection', '18,00,000', '0', '0'],
  ['Interest on FD', '72,000', '72,000', '7,200'],
  ['Club House Fees', '1,20,000', '1,20,000', '12,000'],
  ['Late Fee Income', '45,000', '45,000', '4,500'],
  ['Event Bookings', '60,000', '60,000', '6,000'],
  ['Total', '20,97,000', '2,97,000', '29,700'],
];

const _paymentCollectionRows = [
  ['Flat No', 'Owner', 'Due (₹)', 'Paid (₹)', 'Balance (₹)', 'Status'],
  ['A-101', 'Ramesh Kumar', '12,000', '12,000', '0', 'Paid'],
  ['A-102', 'Sunita Verma', '12,000', '6,000', '6,000', 'Partial'],
  ['A-103', 'Amit Shah', '12,000', '0', '12,000', 'Defaulter'],
  ['B-201', 'Priya Nair', '12,000', '12,000', '0', 'Paid'],
  ['B-202', 'Vijay Iyer', '12,000', '12,000', '0', 'Paid'],
  ['B-203', 'Meena Pillai', '12,000', '4,000', '8,000', 'Defaulter'],
  ['C-301', 'Rajan Mehta', '12,000', '12,000', '0', 'Paid'],
  ['C-302', 'Kavita Rao', '12,000', '12,000', '0', 'Paid'],
];

const _defaulterRows = [
  ['Flat No', 'Owner', 'Outstanding (₹)', 'Months Due', 'Late Fee (₹)'],
  ['A-103', 'Amit Shah', '12,000', '2', '1,200'],
  ['B-203', 'Meena Pillai', '8,000', '1', '800'],
  ['C-109', 'Rahul Nanda', '10,500', '2', '1,050'],
  ['D-402', 'Neha Rao', '7,500', '1', '750'],
];

const _penaltiesRows = [
  ['Flat No', 'Owner', 'Penalty Type', 'Amount (₹)', 'Status'],
  ['A-104', 'Sonal Desai', 'Late Payment', '500', 'Open'],
  ['B-101', 'Ritu Sinha', 'Parking Violation', '1,000', 'Paid'],
  ['C-205', 'Kiran Gupta', 'Noise Complaint', '750', 'Open'],
  ['D-301', 'Harsh Patel', 'Late Payment', '1,200', 'Paid'],
];

const _budgetVsActualRows = [
  ['Category', 'Budget (₹)', 'Actual (₹)', 'Variance (₹)', 'Status'],
  ['Maintenance', '1,20,000', '1,15,000', '+5,000', 'Under Budget'],
  ['Utilities', '80,000', '88,500', '-8,500', 'Over Budget'],
  ['Salaries', '2,00,000', '2,00,000', '0', 'On Target'],
  ['Security', '60,000', '58,000', '+2,000', 'Under Budget'],
  ['Repairs', '50,000', '72,000', '-22,000', 'Over Budget'],
  ['Events', '30,000', '24,000', '+6,000', 'Under Budget'],
  ['Total', '5,40,000', '5,57,500', '-17,500', 'Over Budget'],
];

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class ReportsDashboardPage extends StatefulWidget {
  const ReportsDashboardPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ReportsDashboardPage> createState() => _ReportsDashboardPageState();
}

class _ReportsDashboardPageState extends State<ReportsDashboardPage>
    with SingleTickerProviderStateMixin {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);
  static const Color _panelBg = Color(0xFFF5FBF9);

  late TabController _tabController;
  int _activeTabIndex = 0;

  // Pie chart touch state
  int _expensePieTouched = -1;
  int _incomePieTouched = -1;

  bool _isBalanceSheetLoading = false;
  String? _balanceSheetError;
  String _balanceSheetFromDate = '';
  String _balanceSheetToDate = '';
  List<_BalanceSheetCreditRow> _creditRows = const [];
  List<_BalanceSheetDebitRow> _debitRows = const [];

  String get _balanceSheetApartmentName {
    final header = ApiService.userHeader;
    final value = header?['apartmentName']?.toString().trim() ?? '';
    return value.isEmpty ? 'Apartment' : value;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _activeTabIndex) {
        _activeTabIndex = _tabController.index;
        if (_activeTabIndex == 1) {
          _loadBalanceSheet();
        }
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadBalanceSheet() async {
    if (_isBalanceSheetLoading) {
      return;
    }

    setState(() {
      _isBalanceSheetLoading = true;
      _balanceSheetError = null;
    });

    try {
      final response = await ApiService.getBalanceSheet();
      if (!mounted) {
        return;
      }

      if (response == null) {
        setState(() {
          _balanceSheetError =
              'Unable to load balance sheet. Please try again.';
          _creditRows = const [];
          _debitRows = const [];
          _balanceSheetFromDate = '';
          _balanceSheetToDate = '';
        });
        return;
      }

      setState(() {
        _balanceSheetFromDate = response['fromDate']?.toString() ?? '';
        _balanceSheetToDate = response['toDate']?.toString() ?? '';
        _creditRows = _toCreditRows(response['creditPaymentData']);
        _debitRows = _toDebitRows(response['debitPaymentData']);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _balanceSheetError = 'Unable to load balance sheet. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBalanceSheetLoading = false;
        });
      }
    }
  }

  List<_BalanceSheetCreditRow> _toCreditRows(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((item) {
          final row = Map<String, dynamic>.from(item);
          return _BalanceSheetCreditRow(
            incomeHead: row['paymentName']?.toString() ?? '-',
            unitAmount: _toAmount(row['paymentAmount']),
            totalExcludingTax: _toAmount(row['totalAmountExcludingTax']),
            totalTax: _toAmount(row['taxCollected']),
            totalIncludingTax: _toAmount(row['totalAmountIncludingTax']),
          );
        })
        .toList(growable: false);
  }

  List<_BalanceSheetDebitRow> _toDebitRows(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((item) {
          final row = Map<String, dynamic>.from(item);
          return _BalanceSheetDebitRow(
            expenseHead: row['paymentName']?.toString() ?? '-',
            totalAmount: _toAmount(row['totalAmountIncludingTax']),
          );
        })
        .toList(growable: false);
  }

  double _toAmount(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return 0;
    }
    final normalized = raw.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  String _formatInr(double value) {
    if (value.isNaN || value.isInfinite) {
      return '₹0';
    }
    final rounded = value.round();
    final sign = rounded < 0 ? '-' : '';
    final digits = rounded.abs().toString();
    if (digits.length <= 3) {
      return '$sign₹$digits';
    }

    final last3 = digits.substring(digits.length - 3);
    var prefix = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (prefix.length > 2) {
      parts.insert(0, prefix.substring(prefix.length - 2));
      prefix = prefix.substring(0, prefix.length - 2);
    }
    if (prefix.isNotEmpty) {
      parts.insert(0, prefix);
    }
    return '$sign₹${parts.join(',')},$last3';
  }

  List<_BalanceSheetCreditRow> _orderedCreditRows() {
    final nonOthers = _creditRows
        .where((row) => row.incomeHead.trim().toLowerCase() != 'others')
        .toList(growable: false);
    final others = _creditRows
        .where((row) => row.incomeHead.trim().toLowerCase() == 'others')
        .toList(growable: false);
    return [...nonOthers, ...others];
  }

  double _creditDiscrepancy(_BalanceSheetCreditRow row) {
    return row.totalIncludingTax - row.totalTax - row.totalExcludingTax;
  }

  double _totalIncomeExcludingTax() {
    return _creditRows.fold<double>(
      0,
      (sum, row) => sum + row.totalExcludingTax,
    );
  }

  double _totalExpenseAmount() {
    return _debitRows.fold<double>(0, (sum, row) => sum + row.totalAmount);
  }

  double _netSurplusAmount() {
    return _totalIncomeExcludingTax() - _totalExpenseAmount();
  }

  Future<Uint8List?> _loadSecuraLogoBytes() async {
    try {
      final data = await rootBundle.load('secura_logo.png');
      return data.buffer.asUint8List();
    } catch (_) {}

    final candidates = <File>[];
    var dir = Directory.current;
    for (var i = 0; i < 8; i++) {
      final base = dir.path;
      candidates.add(File('$base${Platform.pathSeparator}secura_logo.png'));
      candidates.add(
        File(
          '$base${Platform.pathSeparator}web${Platform.pathSeparator}secura_logo.png',
        ),
      );
      candidates.add(
        File(
          '$base${Platform.pathSeparator}assets${Platform.pathSeparator}branding${Platform.pathSeparator}secura_logo.png',
        ),
      );

      final parent = dir.parent;
      if (parent.path == dir.path) {
        break;
      }
      dir = parent;
    }

    final seen = <String>{};
    for (final file in candidates) {
      try {
        if (!seen.add(file.path)) {
          continue;
        }
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      } catch (_) {}
    }

    return null;
  }

  String _fileNameWithoutExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0) {
      return fileName;
    }
    return fileName.substring(0, dotIndex);
  }

  String _fileExtensionFromName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  MimeType _mimeTypeForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return MimeType.pdf;
      case 'xlsx':
        return MimeType.microsoftExcel;
      default:
        return MimeType.other;
    }
  }

  Future<bool> _saveBytesToFile({
    required String fileName,
    required Uint8List bytes,
    required String dialogTitle,
    required List<String> allowedExtensions,
  }) async {
    try {
      final extension = _fileExtensionFromName(fileName);
      final baseName = _fileNameWithoutExtension(fileName);

      await FileSaver.instance.saveFile(
        name: baseName.isEmpty ? fileName : baseName,
        bytes: bytes,
        fileExtension: extension,
        mimeType: _mimeTypeForExtension(extension),
      );
      return true;
    } catch (_) {}

    try {
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        lockParentWindow: true,
      );

      if (savedPath == null || savedPath.trim().isEmpty) {
        return false;
      }

      try {
        final file = File(savedPath);
        await file.writeAsBytes(bytes, flush: true);
        return true;
      } catch (_) {
        final fallbackPath = await FilePicker.platform.saveFile(
          dialogTitle: dialogTitle,
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: allowedExtensions,
          bytes: bytes,
          lockParentWindow: true,
        );
        return fallbackPath != null;
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleBalanceSheetExport() async {
    if (_isBalanceSheetLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Balance Sheet is still loading.')),
      );
      return;
    }

    if (_balanceSheetError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to export Balance Sheet right now.'),
        ),
      );
      return;
    }

    final choice = await showDialog<_BalanceSheetExportType>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _brandColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      color: _brandColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Export Balance Sheet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _brandTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose the format for downloading the current balance sheet with logo, dates, totals, and table data.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  _ExportOptionTile(
                    icon: Icons.picture_as_pdf_rounded,
                    title: 'PDF Report',
                    subtitle: 'Best for sharing and printing',
                    accentColor: const Color(0xFFE57373),
                    onTap: () => Navigator.of(
                      dialogContext,
                    ).pop(_BalanceSheetExportType.pdf),
                  ),
                  const SizedBox(height: 12),
                  _ExportOptionTile(
                    icon: Icons.table_chart_rounded,
                    title: 'Excel Workbook',
                    subtitle: 'Best for editing and analysis',
                    accentColor: const Color(0xFF0F8F82),
                    onTap: () => Navigator.of(
                      dialogContext,
                    ).pop(_BalanceSheetExportType.excel),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (choice == null) {
      return;
    }

    if (choice == _BalanceSheetExportType.pdf) {
      await _downloadBalanceSheetAsPdf();
      return;
    }

    await _downloadBalanceSheetAsExcel();
  }

  Future<void> _downloadBalanceSheetAsPdf() async {
    try {
      final pdfBaseFont = await PdfGoogleFonts.notoSansRegular();
      final pdfBoldFont = await PdfGoogleFonts.notoSansBold();
      final document = pw.Document(
        theme: pw.ThemeData.withFont(base: pdfBaseFont, bold: pdfBoldFont),
      );
      pw.MemoryImage? logoImage;
      try {
        final logoBytes = await _loadSecuraLogoBytes();
        if (logoBytes != null) {
          logoImage = pw.MemoryImage(logoBytes);
        }
      } catch (_) {
        logoImage = null;
      }

      final orderedCreditRows = _orderedCreditRows();
      final incomeRows = orderedCreditRows
          .map(
            (item) => [
              item.incomeHead,
              _formatInr(item.unitAmount),
              _formatInr(item.totalExcludingTax),
              _formatInr(item.totalTax),
              _formatInr(item.totalIncludingTax),
              _formatInr(_creditDiscrepancy(item)),
            ],
          )
          .toList();
      incomeRows.add([
        'Total',
        _formatInr(
          _creditRows.fold<double>(0, (sum, row) => sum + row.unitAmount),
        ),
        _formatInr(
          _creditRows.fold<double>(
            0,
            (sum, row) => sum + row.totalExcludingTax,
          ),
        ),
        _formatInr(
          _creditRows.fold<double>(0, (sum, row) => sum + row.totalTax),
        ),
        _formatInr(
          _creditRows.fold<double>(
            0,
            (sum, row) => sum + row.totalIncludingTax,
          ),
        ),
        _formatInr(
          _creditRows.fold<double>(
            0,
            (sum, row) => sum + _creditDiscrepancy(row),
          ),
        ),
      ]);

      final expenseRows = _debitRows
          .map((item) => [item.expenseHead, _formatInr(item.totalAmount)])
          .toList();
      expenseRows.add(['Total', _formatInr(_totalExpenseAmount())]);

      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.fromLTRB(14, 16, 14, 14),
          header: (pdfContext) => pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 84,
                      height: 84,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                ],
              ),
              pw.SizedBox(height: pdfContext.pageNumber == 1 ? 0 : 24),
            ],
          ),
          build: (pdfContext) {
            return [
              pw.Text(
                'Balance Sheet',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Apartment Name: $_balanceSheetApartmentName',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'From Date: ${_balanceSheetFromDate.isEmpty ? '--' : _balanceSheetFromDate}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'To Date: ${_balanceSheetToDate.isEmpty ? '--' : _balanceSheetToDate}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated on: ${DateTime.now()}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  _pdfSummaryCard(
                    'Total Income(Excluding Tax)',
                    _formatInr(_totalIncomeExcludingTax()),
                    PdfColor.fromInt(0xFF0F8F82),
                  ),
                  pw.SizedBox(width: 10),
                  _pdfSummaryCard(
                    'Total Expence',
                    _formatInr(_totalExpenseAmount()),
                    PdfColor.fromInt(0xFF124B45),
                  ),
                  pw.SizedBox(width: 10),
                  _pdfSummaryCard(
                    'Net Surplus',
                    _formatInr(_netSurplusAmount()),
                    PdfColor.fromInt(0xFF26C6AD),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                'Income',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: const [
                  'Income Head',
                  'Unit Amount',
                  'Total Income(Excluding Tax)',
                  'Total Tax',
                  'Total Income(Including Tax)',
                  'Discripancy',
                ],
                data: incomeRows,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8.5,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFEAF5F2),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1.1),
                  2: pw.FlexColumnWidth(1.5),
                  3: pw.FlexColumnWidth(1),
                  4: pw.FlexColumnWidth(1.5),
                  5: pw.FlexColumnWidth(1.1),
                },
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                'Expense',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: const ['Expense Head', 'Total Amount'],
                data: expenseRows,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8.5,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFEAF5F2),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.5),
                  1: pw.FlexColumnWidth(1.2),
                },
              ),
            ];
          },
        ),
      );

      final bytes = Uint8List.fromList(await document.save());
      final saved = await _saveBytesToFile(
        fileName: 'balance_sheet_${DateTime.now().millisecondsSinceEpoch}.pdf',
        bytes: bytes,
        dialogTitle: 'Download Balance Sheet PDF',
        allowedExtensions: const ['pdf'],
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved ? 'PDF downloaded successfully.' : 'Download was cancelled.',
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Balance Sheet PDF export failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to generate PDF right now. ${error.toString()}',
          ),
        ),
      );
    }
  }

  Future<void> _downloadBalanceSheetAsExcel() async {
    final workbook = xlsio.Workbook();
    try {
      final sheet = workbook.worksheets[0];
      sheet.name = 'Balance Sheet';

      try {
        final logoBytes = await _loadSecuraLogoBytes();
        if (logoBytes != null) {
          final picture = sheet.pictures.addStream(1, 1, logoBytes);
          picture.height = 112;
          picture.width = 112;
        }
      } catch (_) {}

      var row = 1;
      sheet.getRangeByName('F$row').setText('Balance Sheet');
      row++;
      sheet
          .getRangeByName('F$row')
          .setText('Apartment Name: $_balanceSheetApartmentName');
      row++;
      sheet
          .getRangeByName('F$row')
          .setText(
            'From Date: ${_balanceSheetFromDate.isEmpty ? '--' : _balanceSheetFromDate}',
          );
      row++;
      sheet
          .getRangeByName('F$row')
          .setText(
            'To Date: ${_balanceSheetToDate.isEmpty ? '--' : _balanceSheetToDate}',
          );
      row++;
      sheet.getRangeByName('F$row').setText('Generated on: ${DateTime.now()}');
      row++;
      sheet.getRangeByName('F$row').setText('Currency: INR');
      row += 3;

      final summaryRows = [
        [
          'Total Income(Excluding Tax)',
          _formatAmountWithoutCurrency(_totalIncomeExcludingTax()),
        ],
        ['Total Expence', _formatAmountWithoutCurrency(_totalExpenseAmount())],
        ['Net Surplus', _formatAmountWithoutCurrency(_netSurplusAmount())],
      ];
      for (final summary in summaryRows) {
        sheet.getRangeByIndex(row, 1).setText(summary[0]);
        sheet.getRangeByIndex(row, 2).setText(summary[1]);
        row++;
      }

      row++;
      sheet.getRangeByIndex(row, 1).setText('Income');
      sheet.getRangeByIndex(row, 1, row, 6).merge();
      sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
      row++;

      final incomeHeaders = const [
        'Income Head',
        'Unit Amount',
        'Total Income(Excluding Tax)',
        'Total Tax',
        'Total Income(Including Tax)',
        'Discripancy',
      ];
      for (var c = 0; c < incomeHeaders.length; c++) {
        sheet.getRangeByIndex(row, c + 1).setText(incomeHeaders[c]);
      }
      final incomeHeaderRow = row;
      row++;

      for (final item in _orderedCreditRows()) {
        final values = [
          item.incomeHead,
          _formatAmountWithoutCurrency(item.unitAmount),
          _formatAmountWithoutCurrency(item.totalExcludingTax),
          _formatAmountWithoutCurrency(item.totalTax),
          _formatAmountWithoutCurrency(item.totalIncludingTax),
          _formatAmountWithoutCurrency(_creditDiscrepancy(item)),
        ];
        for (var c = 0; c < values.length; c++) {
          sheet.getRangeByIndex(row, c + 1).setText(values[c]);
        }
        row++;
      }

      final incomeTotals = [
        'Total',
        _formatAmountWithoutCurrency(
          _creditRows.fold<double>(0, (sum, item) => sum + item.unitAmount),
        ),
        _formatAmountWithoutCurrency(_totalIncomeExcludingTax()),
        _formatAmountWithoutCurrency(
          _creditRows.fold<double>(0, (sum, item) => sum + item.totalTax),
        ),
        _formatAmountWithoutCurrency(
          _creditRows.fold<double>(
            0,
            (sum, item) => sum + item.totalIncludingTax,
          ),
        ),
        _formatAmountWithoutCurrency(
          _creditRows.fold<double>(
            0,
            (sum, item) => sum + _creditDiscrepancy(item),
          ),
        ),
      ];
      for (var c = 0; c < incomeTotals.length; c++) {
        sheet.getRangeByIndex(row, c + 1).setText(incomeTotals[c]);
      }
      final incomeEndRow = row;
      row += 2;

      sheet.getRangeByIndex(row, 1).setText('Expense');
      sheet.getRangeByIndex(row, 1, row, 2).merge();
      sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
      row++;

      const expenseHeaders = ['Expense Head', 'Total Amount'];
      for (var c = 0; c < expenseHeaders.length; c++) {
        sheet.getRangeByIndex(row, c + 1).setText(expenseHeaders[c]);
      }
      final expenseHeaderRow = row;
      row++;

      for (final item in _debitRows) {
        sheet.getRangeByIndex(row, 1).setText(item.expenseHead);
        sheet
            .getRangeByIndex(row, 2)
            .setText(_formatAmountWithoutCurrency(item.totalAmount));
        row++;
      }

      sheet.getRangeByIndex(row, 1).setText('Total');
      sheet
          .getRangeByIndex(row, 2)
          .setText(_formatAmountWithoutCurrency(_totalExpenseAmount()));
      final expenseEndRow = row;

      final incomeHeaderRange = sheet.getRangeByIndex(
        incomeHeaderRow,
        1,
        incomeHeaderRow,
        incomeHeaders.length,
      );
      incomeHeaderRange.cellStyle.backColor = '#E8F7F5';
      incomeHeaderRange.cellStyle.bold = true;
      incomeHeaderRange.cellStyle.hAlign = xlsio.HAlignType.center;

      final incomeTableRange = sheet.getRangeByIndex(
        incomeHeaderRow,
        1,
        incomeEndRow,
        incomeHeaders.length,
      );
      incomeTableRange.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      incomeTableRange.cellStyle.borders.all.color = '#B7D8D2';
      final incomeColumnTexts = <List<String>>[
        [
          'Income',
          ..._orderedCreditRows().map((item) => item.incomeHead),
          'Total',
        ],
        [
          ...summaryRows.map((row) => row[1]),
          incomeHeaders[1],
          ..._orderedCreditRows().map(
            (item) => _formatAmountWithoutCurrency(item.unitAmount),
          ),
          incomeTotals[1],
        ],
        [
          summaryRows[0][0],
          incomeHeaders[2],
          ..._orderedCreditRows().map(
            (item) => _formatAmountWithoutCurrency(item.totalExcludingTax),
          ),
          incomeTotals[2],
        ],
        [
          incomeHeaders[3],
          ..._orderedCreditRows().map(
            (item) => _formatAmountWithoutCurrency(item.totalTax),
          ),
          incomeTotals[3],
        ],
        [
          incomeHeaders[4],
          ..._orderedCreditRows().map(
            (item) => _formatAmountWithoutCurrency(item.totalIncludingTax),
          ),
          incomeTotals[4],
        ],
        [
          incomeHeaders[5],
          ..._orderedCreditRows().map(
            (item) => _formatAmountWithoutCurrency(_creditDiscrepancy(item)),
          ),
          incomeTotals[5],
        ],
      ];
      for (var i = 0; i < incomeColumnTexts.length; i++) {
        sheet.getRangeByIndex(1, i + 1).columnWidth = _excelColumnWidth(
          incomeColumnTexts[i],
        );
      }

      final expenseHeaderRange = sheet.getRangeByIndex(
        expenseHeaderRow,
        1,
        expenseHeaderRow,
        expenseHeaders.length,
      );
      expenseHeaderRange.cellStyle.backColor = '#E8F7F5';
      expenseHeaderRange.cellStyle.bold = true;
      expenseHeaderRange.cellStyle.hAlign = xlsio.HAlignType.center;

      final expenseTableRange = sheet.getRangeByIndex(
        expenseHeaderRow,
        1,
        expenseEndRow,
        expenseHeaders.length,
      );
      expenseTableRange.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      expenseTableRange.cellStyle.borders.all.color = '#B7D8D2';
      final expenseColumnTexts = <List<String>>[
        [
          'Expense',
          expenseHeaders[0],
          ..._debitRows.map((item) => item.expenseHead),
          'Total',
        ],
        [
          ...summaryRows.map((row) => row[1]),
          expenseHeaders[1],
          ..._debitRows.map(
            (item) => _formatAmountWithoutCurrency(item.totalAmount),
          ),
          _formatAmountWithoutCurrency(_totalExpenseAmount()),
        ],
      ];
      for (var i = 0; i < expenseColumnTexts.length; i++) {
        sheet.getRangeByIndex(1, i + 1).columnWidth = _excelColumnWidth(
          expenseColumnTexts[i],
        );
      }

      final bytes = Uint8List.fromList(workbook.saveSync());
      final saved = await _saveBytesToFile(
        fileName: 'balance_sheet_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        bytes: bytes,
        dialogTitle: 'Download Balance Sheet Excel',
        allowedExtensions: const ['xlsx'],
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Excel downloaded successfully.'
                : 'Download was cancelled.',
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Balance Sheet Excel export failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to generate Excel right now.')),
      );
    } finally {
      workbook.dispose();
    }
  }

  pw.Widget _pdfSummaryCard(String label, String value, PdfColor color) {
    final resolvedValue = value.trim().isEmpty ? 'INR 0' : value;
    return pw.Expanded(
      child: pw.Container(
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          border: pw.Border.all(color: PdfColor.fromInt(0xFFDCEEEA)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: pw.Text(
                label,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: pw.Text(
                resolvedValue,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _excelColumnWidth(List<String> values) {
    var longest = 0;
    for (final value in values) {
      final length = value.trim().length;
      if (length > longest) {
        longest = length;
      }
    }
    final estimated = (longest * 1.15).clamp(12, 42);
    return estimated.toDouble();
  }

  String _formatAmountWithoutCurrency(double value) {
    final formatted = _formatInr(value);
    if (formatted.startsWith('-₹')) {
      return '-${formatted.substring(2)}';
    }
    if (formatted.startsWith('₹')) {
      return formatted.substring(1);
    }
    return formatted;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 800;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!widget.embedded) {
      return Scaffold(
        drawer: SideBar(
          selectedSection: AppSection.reports,
          onSectionSelected: (_) {},
        ),
        body: _buildBody(context),
      );
    }
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    final isMobile = _isMobile(context);
    return Container(
      color: _panelBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          _buildReportOptions(isMobile),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildReportDashboardTab(),
                _buildBalanceSheetTab(),
                _buildTaxSheetTab(),
                _buildPaymentCollectionTab(),
                _buildDefaulterTab(),
                _buildPenaltiesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOptions(bool isMobile) {
    final options = [
      _ReportOptionItem('Report Dashboard', Icons.dashboard_rounded, 0),
      _ReportOptionItem('Balance Sheet', Icons.account_balance_rounded, 1),
      _ReportOptionItem('Tax Sheet', Icons.receipt_long_rounded, 2),
      _ReportOptionItem('Payment Wise Collection', Icons.payments_rounded, 3),
      _ReportOptionItem('Defaulter Report', Icons.warning_amber_rounded, 4),
      _ReportOptionItem('Penalties Report', Icons.gavel_rounded, 5),
    ];

    final content = isMobile
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: options
                  .map(
                    (o) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _buildReportOptionCard(o),
                    ),
                  )
                  .toList(),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options.map(_buildReportOptionCard).toList(),
            ),
          );

    return Container(color: Colors.white, child: content);
  }

  Widget _buildReportOptionCard(_ReportOptionItem option) {
    final isSelected = _tabController.index == option.tabIndex;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (option.tabIndex == 1) {
          _loadBalanceSheet();
        }
        _tabController.animateTo(option.tabIndex);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(minWidth: 210),
        decoration: BoxDecoration(
          color: isSelected ? _brandColor.withOpacity(0.12) : _panelBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _brandColor : const Color(0xFFDCEEEA),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.icon,
              color: isSelected ? _brandColor : Colors.black54,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                option.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _brandColor : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isMobile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _brandColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: _brandColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Reports Dashboard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _brandTextColor,
                    ),
                  ),
                  Text(
                    'Financial insights and analytics',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildKpiRow(isMobile),
        ],
      ),
    );
  }

  // ── KPI Cards ──────────────────────────────────────────────────────────────

  Widget _buildKpiRow(bool isMobile) {
    final kpis = [
      _KpiData(
        'Total Income',
        '₹20,97,000',
        Icons.trending_up_rounded,
        const Color(0xFF0F8F82),
      ),
      _KpiData(
        'Total Expense',
        '₹13,24,500',
        Icons.trending_down_rounded,
        const Color(0xFFE57373),
      ),
      _KpiData(
        'Net Surplus',
        '₹7,72,500',
        Icons.account_balance_wallet_rounded,
        const Color(0xFF26C6AD),
      ),
      _KpiData(
        'Defaulters',
        '2 / 8',
        Icons.warning_amber_rounded,
        const Color(0xFFFFB300),
        note: 'To collect: ₹20,000',
      ),
      _KpiData(
        'Income/Expense Ratio',
        '1.6',
        Icons.balance_rounded,
        const Color(0xFF124B45),
      ),
    ];

    if (isMobile) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
        children: kpis.map(_buildKpiCard).toList(),
      );
    }
    return Row(
      children: kpis
          .map(
            (k) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildKpiCard(k),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildKpiCard(_KpiData k) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: k.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: k.color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(k.icon, color: k.color, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  k.label,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                Text(
                  k.value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: k.color,
                  ),
                ),
                if (k.note != null)
                  Text(
                    k.note!,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Graphs Section ─────────────────────────────────────────────────────────

  Widget _buildGraphsSection(bool isMobile) {
    final graphs = [
      _buildIncomeVsExpenseChart(),
      _buildExpensePieChart(),
      _buildIncomePieChart(),
      _buildExpensePerFlatChart(),
      _buildIncomePerFlatChart(),
    ];

    if (isMobile) {
      return Column(
        children: graphs
            .map(
              (g) =>
                  Padding(padding: const EdgeInsets.only(bottom: 20), child: g),
            )
            .toList(),
      );
    }

    return Column(
      children: [
        // Full-width income vs expense
        graphs[0],
        const SizedBox(height: 20),
        // Pie charts side by side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: graphs[1]),
            const SizedBox(width: 16),
            Expanded(child: graphs[2]),
          ],
        ),
        const SizedBox(height: 20),
        // Per-flat charts side by side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: graphs[3]),
            const SizedBox(width: 16),
            Expanded(child: graphs[4]),
          ],
        ),
      ],
    );
  }

  // ── Chart: Income vs Expense ───────────────────────────────────────────────

  Widget _buildIncomeVsExpenseChart() {
    return _ChartCard(
      title: 'Month Wise Income vs Expense',
      subtitle: 'FY 2025-26  ( ₹ in thousands )',
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 240,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gi, rod, ri) {
                final label = ri == 0 ? 'Income' : 'Expense';
                return BarTooltipItem(
                  '$label\n₹${rod.toY.toStringAsFixed(0)}K',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: const TextStyle(fontSize: 9, color: Colors.black45),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= _months.length) return const SizedBox();
                  return Text(
                    _months[i],
                    style: const TextStyle(fontSize: 9, color: Colors.black54),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(12, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _incomeData[i],
                  color: const Color(0xFF0F8F82),
                  width: 9,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: _expenseData[i],
                  color: const Color(0xFFE57373),
                  width: 9,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            );
          }),
        ),
      ),
      legend: const [
        _LegendItem(color: Color(0xFF0F8F82), label: 'Income'),
        _LegendItem(color: Color(0xFFE57373), label: 'Expense'),
      ],
    );
  }

  // ── Chart: Expense Pie ─────────────────────────────────────────────────────

  Widget _buildExpensePieChart() {
    return _ChartCard(
      title: 'Expense Distribution',
      subtitle: 'Percentage breakdown by category',
      height: 240,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    response == null ||
                    response.touchedSection == null) {
                  _expensePieTouched = -1;
                } else {
                  _expensePieTouched =
                      response.touchedSection!.touchedSectionIndex;
                }
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 38,
          sections: List.generate(_expensePieData.length, (i) {
            final isTouched = i == _expensePieTouched;
            final d = _expensePieData[i];
            return PieChartSectionData(
              color: d.color,
              value: d.value,
              title: '${d.value.toInt()}%',
              radius: isTouched ? 68 : 58,
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }),
        ),
      ),
      legend: _expensePieData
          .map((d) => _LegendItem(color: d.color, label: d.label))
          .toList(),
    );
  }

  // ── Chart: Income Pie ──────────────────────────────────────────────────────

  Widget _buildIncomePieChart() {
    return _ChartCard(
      title: 'Income Distribution',
      subtitle: 'Percentage breakdown by category',
      height: 240,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    response == null ||
                    response.touchedSection == null) {
                  _incomePieTouched = -1;
                } else {
                  _incomePieTouched =
                      response.touchedSection!.touchedSectionIndex;
                }
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 38,
          sections: List.generate(_incomePieData.length, (i) {
            final isTouched = i == _incomePieTouched;
            final d = _incomePieData[i];
            return PieChartSectionData(
              color: d.color,
              value: d.value,
              title: '${d.value.toInt()}%',
              radius: isTouched ? 68 : 58,
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }),
        ),
      ),
      legend: _incomePieData
          .map((d) => _LegendItem(color: d.color, label: d.label))
          .toList(),
    );
  }

  // ── Chart: Expense Per Flat ────────────────────────────────────────────────

  Widget _buildExpensePerFlatChart() {
    return _ChartCard(
      title: 'Expense Cost Per Flat – Month Wise',
      subtitle: 'X-axis: Cost (₹)  •  Y-axis: Month',
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 2000,
          maxX: 4200,
          minY: 0,
          maxY: 11,
          titlesData: _expenseCostXAxisMonthYAxisTitles(),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                12,
                (i) => FlSpot(_expensePerFlat[i], i.toDouble()),
              ),
              isCurved: true,
              color: const Color(0xFFE57373),
              barWidth: 2.5,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFE57373).withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
      legend: const [
        _LegendItem(color: Color(0xFFE57373), label: 'Expense / Flat'),
      ],
    );
  }

  // ── Chart: Income Per Flat ─────────────────────────────────────────────────

  Widget _buildIncomePerFlatChart() {
    return _ChartCard(
      title: 'Income Per Flat – Month Wise',
      subtitle: 'Average income collected per flat  ( ₹ )',
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 3000,
          maxY: 5800,
          titlesData: _lineTitles(),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                12,
                (i) => FlSpot(i.toDouble(), _incomePerFlat[i]),
              ),
              isCurved: true,
              color: const Color(0xFF0F8F82),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF0F8F82).withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
      legend: const [
        _LegendItem(color: Color(0xFF0F8F82), label: 'Income / Flat'),
      ],
    );
  }

  FlTitlesData _lineTitles() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          getTitlesWidget: (v, _) => Text(
            '${v.toInt()}',
            style: const TextStyle(fontSize: 9, color: Colors.black45),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= _months.length) return const SizedBox();
            return Text(
              _months[i],
              style: const TextStyle(fontSize: 9, color: Colors.black54),
            );
          },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  FlTitlesData _expenseCostXAxisMonthYAxisTitles() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          reservedSize: 36,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= _months.length) return const SizedBox();
            return Text(
              _months[i],
              style: const TextStyle(fontSize: 9, color: Colors.black54),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 400,
          reservedSize: 30,
          getTitlesWidget: (v, _) => Text(
            '₹${v.toInt()}',
            style: const TextStyle(fontSize: 9, color: Colors.black45),
          ),
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  Widget _buildReportDashboardTab() {
    final isMobile = _isMobile(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _brandTextColor,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Overview of income, expense, and flat-wise trends',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          _buildGraphsSection(isMobile),
          const SizedBox(height: 20),
          _buildBudgetVsActualLineChart(),
        ],
      ),
    );
  }

  // ── Tab: Balance Sheet ─────────────────────────────────────────────────────

  Widget _buildBalanceSheetTab() {
    final totalIncomeExcludingTax = _creditRows.fold<double>(
      0,
      (sum, row) => sum + row.totalExcludingTax,
    );
    final totalExpense = _debitRows.fold<double>(
      0,
      (sum, row) => sum + row.totalAmount,
    );
    final netSurplus = totalIncomeExcludingTax - totalExpense;

    final subtitle =
        (_balanceSheetFromDate.isNotEmpty && _balanceSheetToDate.isNotEmpty)
        ? '$_balanceSheetFromDate to $_balanceSheetToDate'
        : 'As on current date';

    return _ReportSheetScaffold(
      title: 'Balance Sheet',
      subtitle: subtitle,
      icon: Icons.account_balance_rounded,
      onExport: _handleBalanceSheetExport,
      summaryCards: [
        _SummaryCard(
          label: 'Total Income(Excluding Tax)',
          value: _formatInr(totalIncomeExcludingTax),
          color: const Color(0xFF0F8F82),
        ),
        _SummaryCard(
          label: 'Total Expence',
          value: _formatInr(totalExpense),
          color: const Color(0xFF124B45),
        ),
        _SummaryCard(
          label: 'Net Surplus',
          value: _formatInr(netSurplus),
          color: const Color(0xFF26C6AD),
        ),
      ],
      headers: const ['Category', 'Details'],
      rows: const [],
      topSection: _buildBalanceSheetContent(),
      sectionRows: const {},
      statusCol: -1,
      showTable: false,
    );
  }

  Widget _buildBalanceSheetContent() {
    if (_isBalanceSheetLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_balanceSheetError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7F7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFD6D6)),
        ),
        child: Text(
          _balanceSheetError!,
          style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 12),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBalanceSectionTitle('Income'),
        _buildAssetsTable(),
        const SizedBox(height: 16),
        _buildBalanceSectionTitle('Expense'),
        _buildLiabilitiesTable(),
      ],
    );
  }

  Widget _buildBalanceSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _brandTextColor,
        ),
      ),
    );
  }

  Widget _buildAssetsTable() {
    final nonOthers = _creditRows
        .where((row) => row.incomeHead.trim().toLowerCase() != 'others')
        .toList(growable: false);
    final others = _creditRows
        .where((row) => row.incomeHead.trim().toLowerCase() == 'others')
        .toList(growable: false);
    final orderedRows = [...nonOthers, ...others];

    final rows = orderedRows
        .map(
          (item) => [
            item.incomeHead,
            _formatInr(item.unitAmount),
            _formatInr(item.totalExcludingTax),
            _formatInr(item.totalTax),
            _formatInr(item.totalIncludingTax),
            _formatInr(
              item.totalIncludingTax - item.totalTax - item.totalExcludingTax,
            ),
          ],
        )
        .toList(growable: false);

    final unitAmountTotal = _creditRows.fold<double>(
      0,
      (sum, row) => sum + row.unitAmount,
    );
    final excludingTaxTotal = _creditRows.fold<double>(
      0,
      (sum, row) => sum + row.totalExcludingTax,
    );
    final taxTotal = _creditRows.fold<double>(
      0,
      (sum, row) => sum + row.totalTax,
    );
    final includingTaxTotal = _creditRows.fold<double>(
      0,
      (sum, row) => sum + row.totalIncludingTax,
    );
    final discrepancyTotal = _creditRows.fold<double>(
      0,
      (sum, row) =>
          sum + (row.totalIncludingTax - row.totalTax - row.totalExcludingTax),
    );

    return _BalanceTableCard(
      headers: const [
        'Income Head',
        'Unit Amount',
        'Total Income(Excluding Tax)',
        'Total Tax',
        'Total Income(Including Tax)',
        'Discripancy',
      ],
      rows: rows,
      totalsRow: [
        'Total',
        _formatInr(unitAmountTotal),
        _formatInr(excludingTaxTotal),
        _formatInr(taxTotal),
        _formatInr(includingTaxTotal),
        _formatInr(discrepancyTotal),
      ],
      firstColumnFlex: 2,
    );
  }

  Widget _buildLiabilitiesTable() {
    final rows = _debitRows
        .map((item) => [item.expenseHead, _formatInr(item.totalAmount)])
        .toList(growable: false);

    final totalExpense = _debitRows.fold<double>(
      0,
      (sum, row) => sum + row.totalAmount,
    );

    return _BalanceTableCard(
      headers: const ['Expense Head', 'Total Amount'],
      rows: rows,
      totalsRow: ['Total', _formatInr(totalExpense)],
      firstColumnFlex: 2,
    );
  }

  // ── Tab: Tax Sheet ─────────────────────────────────────────────────────────

  Widget _buildTaxSheetTab() {
    return _ReportSheetScaffold(
      title: 'Tax Sheet',
      subtitle: 'Financial Year 2025-26',
      icon: Icons.receipt_long_rounded,
      summaryCards: [
        _SummaryCard(
          label: 'Gross Income',
          value: '₹20,97,000',
          color: const Color(0xFF0F8F82),
        ),
        _SummaryCard(
          label: 'Taxable Income',
          value: '₹2,97,000',
          color: const Color(0xFFFFB300),
        ),
        _SummaryCard(
          label: 'Total Tax',
          value: '₹29,700',
          color: const Color(0xFFE57373),
        ),
      ],
      headers: _taxSheetRows[0].cast<String>(),
      rows: _taxSheetRows.sublist(1),
      sectionRows: const {},
      statusCol: -1,
    );
  }

  // ── Tab: Payment Collection & Defaulters ──────────────────────────────────

  Widget _buildPaymentCollectionTab() {
    return _ReportSheetScaffold(
      title: 'Payment Wise Collection Report',
      subtitle: 'April 2026 – All units',
      icon: Icons.payments_rounded,
      summaryCards: [
        _SummaryCard(
          label: 'Total Collected',
          value: '₹84,000',
          color: const Color(0xFF0F8F82),
        ),
        _SummaryCard(
          label: 'Total Due',
          value: '₹96,000',
          color: const Color(0xFFFFB300),
        ),
        _SummaryCard(
          label: 'Collection Ratio',
          value: '87.5%',
          color: const Color(0xFFE57373),
        ),
      ],
      headers: _paymentCollectionRows[0].cast<String>(),
      rows: _paymentCollectionRows.sublist(1),
      sectionRows: const {},
      statusCol: 5,
    );
  }

  Widget _buildDefaulterTab() {
    return _ReportSheetScaffold(
      title: 'Defaulter Report',
      subtitle: 'April 2026 – Pending owners list',
      icon: Icons.warning_amber_rounded,
      summaryCards: const [
        _SummaryCard(
          label: 'Defaulters',
          value: '4 Units',
          color: Color(0xFFFFB300),
        ),
        _SummaryCard(
          label: 'Amount To Be Collected',
          value: '₹38,000',
          color: Color(0xFFE57373),
        ),
        _SummaryCard(
          label: 'Late Fee Expected',
          value: '₹3,800',
          color: Color(0xFF124B45),
        ),
      ],
      headers: _defaulterRows[0].cast<String>(),
      rows: _defaulterRows.sublist(1),
      sectionRows: const {},
      statusCol: -1,
    );
  }

  Widget _buildPenaltiesTab() {
    return _ReportSheetScaffold(
      title: 'Penalties Report',
      subtitle: 'April 2026 – Penalty audit',
      icon: Icons.gavel_rounded,
      summaryCards: const [
        _SummaryCard(
          label: 'Open Penalties',
          value: '2',
          color: Color(0xFFFFB300),
        ),
        _SummaryCard(
          label: 'Collected Penalties',
          value: '₹2,200',
          color: Color(0xFF0F8F82),
        ),
        _SummaryCard(
          label: 'Pending Penalties',
          value: '₹1,250',
          color: Color(0xFFE57373),
        ),
      ],
      headers: _penaltiesRows[0].cast<String>(),
      rows: _penaltiesRows.sublist(1),
      sectionRows: const {},
      statusCol: 4,
    );
  }

  // ── Tab: Budget vs Actual ──────────────────────────────────────────────────

  // ── Chart: Budget vs Actual ────────────────────────────────────────────────

  Widget _buildBudgetVsActualLineChart() {
    return _ChartCard(
      title: 'Budget vs Actual – Month Wise',
      subtitle: 'Trend comparison  ( ₹ in thousands )',
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 60,
          maxY: 190,
          titlesData: _lineTitles(),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                12,
                (i) => FlSpot(i.toDouble(), _budgetData[i]),
              ),
              isCurved: true,
              color: const Color(0xFF0F8F82),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              dashArray: [6, 3],
            ),
            LineChartBarData(
              spots: List.generate(
                12,
                (i) => FlSpot(i.toDouble(), _actualData[i]),
              ),
              isCurved: true,
              color: const Color(0xFFE57373),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
      legend: const [
        _LegendItem(color: Color(0xFF0F8F82), label: 'Budget'),
        _LegendItem(color: Color(0xFFE57373), label: 'Actual'),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _KpiData {
  const _KpiData(this.label, this.value, this.icon, this.color, {this.note});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? note;
}

class _SummaryCard {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
}

class _LegendItem {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;
}

class _ExportOptionTile extends StatelessWidget {
  const _ExportOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accentColor.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ReportsDashboardPageState._brandTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: accentColor),
            ],
          ),
        ),
      ),
    );
  }
}

enum _BalanceSheetExportType { pdf, excel }

class _ReportOptionItem {
  const _ReportOptionItem(this.title, this.icon, this.tabIndex);
  final String title;
  final IconData icon;
  final int tabIndex;
}

class _BalanceSheetCreditRow {
  const _BalanceSheetCreditRow({
    required this.incomeHead,
    required this.unitAmount,
    required this.totalExcludingTax,
    required this.totalTax,
    required this.totalIncludingTax,
  });

  final String incomeHead;
  final double unitAmount;
  final double totalExcludingTax;
  final double totalTax;
  final double totalIncludingTax;
}

class _BalanceSheetDebitRow {
  const _BalanceSheetDebitRow({
    required this.expenseHead,
    required this.totalAmount,
  });

  final String expenseHead;
  final double totalAmount;
}

class _BalanceTableCard extends StatelessWidget {
  const _BalanceTableCard({
    required this.headers,
    required this.rows,
    required this.totalsRow,
    this.firstColumnFlex = 2,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final List<String> totalsRow;
  final int firstColumnFlex;

  static const Color _brandTextColor = Color(0xFF124B45);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0F0EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade100),
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
          columnWidths: {
            if (headers.length > 1)
              0: FlexColumnWidth(firstColumnFlex.toDouble()),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFE8F7F5)),
              children: headers
                  .map(
                    (h) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        h,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _brandTextColor,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            ...List.generate(rows.length, (i) {
              final row = rows[i];
              return TableRow(
                decoration: BoxDecoration(
                  color: i.isOdd ? Colors.white : const Color(0xFFFAFAFA),
                ),
                children: List.generate(row.length, (j) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      row[j],
                      style: TextStyle(
                        fontSize: 12,
                        color: j == 0 ? Colors.black87 : Colors.black54,
                        fontWeight: j == 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              );
            }),
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF0FAF9)),
              children: List.generate(totalsRow.length, (j) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  child: Text(
                    totalsRow[j],
                    style: const TextStyle(
                      fontSize: 12,
                      color: _brandTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chart Card wrapper ─────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.height,
    required this.child,
    this.legend = const [],
  });

  final String title;
  final String subtitle;
  final double height;
  final Widget child;
  final List<_LegendItem> legend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0F0EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF124B45),
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
          const SizedBox(height: 12),
          SizedBox(height: height, child: child),
          if (legend.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: legend
                  .map(
                    (l) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: l.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          l.label,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Report Sheet Scaffold ──────────────────────────────────────────────────

class _ReportSheetScaffold extends StatelessWidget {
  const _ReportSheetScaffold({
    this.topSection,
    this.onExport,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.summaryCards,
    required this.headers,
    required this.rows,
    required this.sectionRows,
    required this.statusCol,
    this.budgetChart,
    this.showTable = true,
  });

  final Widget? topSection;
  final VoidCallback? onExport;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_SummaryCard> summaryCards;
  final List<String> headers;
  final List<List<dynamic>> rows;
  final Set<int> sectionRows;
  final int statusCol; // column index to apply status colour, or -1
  final Widget? budgetChart;
  final bool showTable;

  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(),
          const SizedBox(height: 16),
          _buildSummaryRow(),
          const SizedBox(height: 20),
          if (topSection != null) ...[topSection!, const SizedBox(height: 20)],
          if (budgetChart != null) ...[
            budgetChart!,
            const SizedBox(height: 20),
          ],
          if (showTable) _buildTable(),
        ],
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _brandColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _brandColor, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _brandTextColor,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: onExport ?? () {},
          icon: const Icon(Icons.download_outlined, size: 16),
          label: const Text('Export'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _brandColor,
            side: const BorderSide(color: _brandColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: summaryCards
          .map(
            (c) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: c.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.color.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: c.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0F0EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade100),
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
          columnWidths: _columnWidths(),
          children: [
            // Header row
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFE8F7F5)),
              children: headers
                  .map(
                    (h) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        h,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _brandTextColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            // Data rows
            ...List.generate(rows.length, (i) {
              final row = rows[i];
              final isSection = sectionRows.contains(i);
              return TableRow(
                decoration: BoxDecoration(
                  color: isSection
                      ? const Color(0xFFF0FAF9)
                      : (i.isOdd ? Colors.white : const Color(0xFFFAFAFA)),
                ),
                children: List.generate(row.length, (j) {
                  final cell = row[j].toString();
                  if (isSection && j == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        cell,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _brandTextColor,
                        ),
                      ),
                    );
                  }
                  if (j == statusCol) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: _StatusChip(cell),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      cell,
                      style: TextStyle(
                        fontSize: 12,
                        color: j == 0 ? Colors.black87 : Colors.black54,
                        fontWeight: j == 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              );
            }),
          ],
        ),
      ),
    );
  }

  Map<int, TableColumnWidth> _columnWidths() {
    if (headers.length <= 2) return {};
    return {0: const FlexColumnWidth(2)};
  }
}

// ── Status Chip ────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
      case 'under budget':
      case 'on target':
      case 'closed':
        color = const Color(0xFF0F8F82);
        break;
      case 'partial':
      case 'over budget':
      case 'open':
        color = const Color(0xFFE57373);
        break;
      case 'defaulter':
        color = const Color(0xFFFFB300);
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
