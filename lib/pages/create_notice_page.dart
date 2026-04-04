import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;

import '../services/api_service.dart';
import '../services/notice_models.dart';

class CreateNoticeDialog extends StatefulWidget {
  const CreateNoticeDialog({super.key});

  @override
  State<CreateNoticeDialog> createState() => _CreateNoticeDialogState();
}

class _CreateNoticeDialogState extends State<CreateNoticeDialog> {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);
  static const double _maxCanvasWidth = 720;
  static const double _maxCanvasHeight = 940;
  static const List<Color> _textColors = [
    Colors.black,
    Color(0xFF1F2937),
    Color(0xFF124B45),
    Color(0xFF0F8F82),
    Color(0xFF0B5FFF),
    Color(0xFF1A237E),
    Color(0xFF6A1B9A),
    Color(0xFFAD1457),
    Color(0xFFB3261E),
    Color(0xFFEF6C00),
    Color(0xFF2E7D32),
    Color(0xFF455A64),
  ];
  static const List<_FontFamilyOption> _fontFamilies = [
    _FontFamilyOption(label: 'Arial', value: 'Arimo'),
    _FontFamilyOption(label: 'Arial Black', value: 'Archivo Black'),
    _FontFamilyOption(label: 'Monotype Corsiva', value: 'Great Vibes'),
    _FontFamilyOption(label: 'Roboto', value: 'Roboto'),
    _FontFamilyOption(label: 'Lato', value: 'Lato'),
    _FontFamilyOption(label: 'Montserrat', value: 'Montserrat'),
    _FontFamilyOption(label: 'Nunito', value: 'Nunito'),
    _FontFamilyOption(label: 'Merriweather', value: 'Merriweather'),
    _FontFamilyOption(label: 'Playfair Display', value: 'Playfair Display'),
    _FontFamilyOption(label: 'Oswald', value: 'Oswald'),
    _FontFamilyOption(label: 'Source Code Pro', value: 'Source Code Pro'),
  ];
  static const List<_HeaderOption> _headerOptions = [
    _HeaderOption(label: 'Normal', level: null),
    _HeaderOption(label: 'Header 1', level: 1),
    _HeaderOption(label: 'Header 2', level: 2),
    _HeaderOption(label: 'Header 3', level: 3),
  ];
  static const List<_PlacementPreset> _placementPresets = [
    _PlacementPreset('TL', Alignment.topLeft),
    _PlacementPreset('TC', Alignment.topCenter),
    _PlacementPreset('TR', Alignment.topRight),
    _PlacementPreset('CL', Alignment.centerLeft),
    _PlacementPreset('CC', Alignment.center),
    _PlacementPreset('CR', Alignment.centerRight),
    _PlacementPreset('BL', Alignment.bottomLeft),
    _PlacementPreset('BC', Alignment.bottomCenter),
    _PlacementPreset('BR', Alignment.bottomRight),
  ];
  static const double _defaultTextBoxWidth = 72;
  static const double _defaultTextBoxHeight = 40;
  static const double _defaultAutosizeFontSize = 12;

  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _canvasViewportKey = GlobalKey();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TransformationController _canvasTransformationController =
      TransformationController();
  final ValueNotifier<int> _canvasRefreshNotifier = ValueNotifier<int>(0);
  final FocusNode _dialogFocusNode = FocusNode();
  final TextEditingController _noticeShortDescriptionController =
      TextEditingController();
  final TextEditingController _noticeHeaderController = TextEditingController();
  final TextEditingController _publishingDateController =
      TextEditingController();
  final TextEditingController _letterNumberController = TextEditingController();

  Uint8List? _letterHeadBytes;
  bool _loadingLetterHead = true;
  bool _submittingNotice = false;
  bool _capturingNotice = false;
  String? _letterHeadError;
  double _canvasWidth = 595;
  double _canvasHeight = 842;
  int _layerCounter = 0;
  final List<_NoticePage> _pages = [];
  int _currentPageIndex = 0;
  String? _selectedLayerId;
  String? _editingTextLayerId;
  DateTime? _publishingDate;
  double _canvasZoom = 1.0;
  double _textMarginLeft = 24;
  double _textMarginTop = 24;
  double _textMarginRight = 24;
  double _textMarginBottom = 24;
  double _noticeCreationProgress = 0;
  String _noticeCreationStatus = 'Preparing notice...';

  _NoticePage? get _currentPage =>
      _pages.isEmpty ? null : _pages[_currentPageIndex];

  List<_NoticeTextLayer> get _textLayers => _currentPage!.textLayers;

  List<_NoticeImageLayer> get _imageLayers => _currentPage!.imageLayers;

  int _nextLayerZOrder() {
    final currentPage = _currentPage;
    if (currentPage == null) {
      return 0;
    }

    var maxZOrder = -1;
    for (final layer in currentPage.textLayers) {
      if (layer.zOrder > maxZOrder) {
        maxZOrder = layer.zOrder;
      }
    }
    for (final layer in currentPage.imageLayers) {
      if (layer.zOrder > maxZOrder) {
        maxZOrder = layer.zOrder;
      }
    }

    return maxZOrder + 1;
  }

  List<_LayerStackEntry> _sortedCurrentLayerEntries() {
    final currentPage = _currentPage;
    if (currentPage == null) {
      return const <_LayerStackEntry>[];
    }

    final entries = <_LayerStackEntry>[
      for (final layer in currentPage.imageLayers)
        _LayerStackEntry.image(layer: layer),
      for (final layer in currentPage.textLayers)
        _LayerStackEntry.text(layer: layer),
    ];

    entries.sort((a, b) => a.zOrder.compareTo(b.zOrder));
    return entries;
  }

  bool _canMoveSelectedLayerForward() {
    final entries = _sortedCurrentLayerEntries();
    final selectedId = _selectedLayerId;
    if (selectedId == null || entries.isEmpty) {
      return false;
    }

    final index = entries.indexWhere((entry) => entry.id == selectedId);
    return index != -1 && index < entries.length - 1;
  }

  bool _canMoveSelectedLayerBackward() {
    final entries = _sortedCurrentLayerEntries();
    final selectedId = _selectedLayerId;
    if (selectedId == null || entries.isEmpty) {
      return false;
    }

    final index = entries.indexWhere((entry) => entry.id == selectedId);
    return index > 0;
  }

  void _swapLayerOrder(_LayerStackEntry first, _LayerStackEntry second) {
    setState(() {
      final original = first.zOrder;
      first.zOrder = second.zOrder;
      second.zOrder = original;
    });
  }

  void _moveSelectedLayerForward() {
    final entries = _sortedCurrentLayerEntries();
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }

    final index = entries.indexWhere((entry) => entry.id == selectedId);
    if (index == -1 || index >= entries.length - 1) {
      return;
    }

    _swapLayerOrder(entries[index], entries[index + 1]);
  }

  void _moveSelectedLayerBackward() {
    final entries = _sortedCurrentLayerEntries();
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }

    final index = entries.indexWhere((entry) => entry.id == selectedId);
    if (index <= 0) {
      return;
    }

    _swapLayerOrder(entries[index], entries[index - 1]);
  }

  void _setNoticeCreationProgress(double progress, String status) {
    if (!mounted) {
      return;
    }

    setState(() {
      _noticeCreationProgress = progress.clamp(0.0, 1.0);
      _noticeCreationStatus = status;
    });
  }

  @override
  void initState() {
    super.initState();
    _setPublishingDate(DateTime.now());
    _fetchLetterHead();
  }

  @override
  void dispose() {
    _noticeShortDescriptionController.dispose();
    _noticeHeaderController.dispose();
    _publishingDateController.dispose();
    _letterNumberController.dispose();
    _canvasTransformationController.dispose();
    _canvasRefreshNotifier.dispose();
    _dialogFocusNode.dispose();
    for (final page in _pages) {
      for (final layer in page.textLayers) {
        _disposeTextLayer(layer);
      }
    }
    super.dispose();
  }

  void _resetCanvasViewport() {
    _canvasTransformationController.value = Matrix4.identity();
    _canvasZoom = 1.0;
  }

  void _switchToPage(int index) {
    if (index < 0 || index >= _pages.length) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _currentPageIndex = index;
      _selectedLayerId = null;
      _editingTextLayerId = null;
      _resetCanvasViewport();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _dialogFocusNode.requestFocus();
      }
    });
  }

  Future<void> _showAddPageDialog() async {
    final selection = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Page'),
          content: const Text(
            'Choose whether the new page should use the same letterhead or a blank white page.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('blank'),
              child: const Text('Blank Page'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop('letterhead'),
              style: FilledButton.styleFrom(backgroundColor: _brandColor),
              child: const Text('Same Letterhead'),
            ),
          ],
        );
      },
    );

    if (!mounted || selection == null) {
      return;
    }

    if (selection == 'letterhead') {
      if (_letterHeadBytes == null || _letterHeadBytes!.isEmpty) {
        _showSnackBar('No default letterhead is available for a new page.');
        return;
      }
      _addPage(backgroundBytes: Uint8List.fromList(_letterHeadBytes!));
      return;
    }

    _addPage();
  }

  void _addPage({Uint8List? backgroundBytes}) {
    FocusManager.instance.primaryFocus?.unfocus();

    final page = _NoticePage(
      backgroundBytes: backgroundBytes,
      textLayers: <_NoticeTextLayer>[],
      imageLayers: <_NoticeImageLayer>[],
    );

    setState(() {
      _pages.add(page);
      _currentPageIndex = _pages.length - 1;
      _selectedLayerId = null;
      _editingTextLayerId = null;
      _resetCanvasViewport();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _dialogFocusNode.requestFocus();
      }
    });
  }

  Future<void> _fetchLetterHead() async {
    setState(() {
      _loadingLetterHead = true;
      _letterHeadError = null;
    });

    try {
      final response = await ApiService.getLetterHead();
      final rawImage = response?['letterHeadImage']?.toString() ?? '';
      final bytes = _decodeImageBytes(rawImage);

      if (!mounted) {
        return;
      }

      if (bytes != null && bytes.isNotEmpty) {
        _setLetterHeadBytes(bytes);
      } else {
        setState(() {
          _loadingLetterHead = false;
          _letterHeadBytes = null;
          _letterHeadError =
              'Letterhead was not available from the server. Upload one to continue.';
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingLetterHead = false;
        _letterHeadBytes = null;
        _letterHeadError =
            'Unable to load the letterhead from the server. Upload one to continue.';
      });
    }
  }

  Uint8List? _decodeImageBytes(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return null;
    }

    final normalized = value.contains(',') && value.startsWith('data:')
        ? value.substring(value.indexOf(',') + 1)
        : value;

    try {
      return base64Decode(normalized);
    } catch (_) {
      try {
        return base64Decode(Uri.decodeComponent(normalized));
      } catch (_) {
        return null;
      }
    }
  }

  void _setLetterHeadBytes(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);

    setState(() {
      _loadingLetterHead = false;
      _letterHeadBytes = bytes;
      _letterHeadError = null;
      if (decoded != null) {
        _canvasWidth = decoded.width.toDouble();
        _canvasHeight = decoded.height.toDouble();
      }

      if (_pages.isEmpty) {
        _pages.add(
          _NoticePage(
            backgroundBytes: Uint8List.fromList(bytes),
            textLayers: <_NoticeTextLayer>[],
            imageLayers: <_NoticeImageLayer>[],
          ),
        );
        _currentPageIndex = 0;
      } else if (_currentPage != null &&
          _currentPage!.backgroundBytes != null) {
        _currentPage!.backgroundBytes = Uint8List.fromList(bytes);
      }
    });
  }

  Future<void> _pickLetterHeadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final bytes = result.files.single.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showSnackBar('The selected letterhead image could not be read.');
      return;
    }

    _setLetterHeadBytes(bytes);
  }

  Future<void> _pickOverlayImage() async {
    if (_currentPage == null) {
      _showSnackBar('Add a page before importing an overlay image.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final bytes = result.files.single.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showSnackBar('The selected overlay image could not be read.');
      return;
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      _showSnackBar('This overlay image format is not supported.');
      return;
    }

    final maxWidth = _canvasWidth * 0.35;
    final width = decoded.width > maxWidth
        ? maxWidth
        : decoded.width.toDouble();
    final height = width * decoded.height / decoded.width;
    final layer = _NoticeImageLayer(
      id: _nextLayerId('image'),
      bytes: bytes,
      offset: Offset((_canvasWidth - width) / 2, (_canvasHeight - height) / 2),
      width: width,
      height: height,
      intrinsicWidth: decoded.width.toDouble(),
      intrinsicHeight: decoded.height.toDouble(),
      zOrder: _nextLayerZOrder(),
    );

    setState(() {
      _imageLayers.add(layer);
      _selectedLayerId = layer.id;
    });
  }

  String _nextLayerId(String prefix) {
    _layerCounter += 1;
    return '${prefix}_$_layerCounter';
  }

  void _disposeTextLayer(_NoticeTextLayer layer) {
    if (layer.listener != null) {
      layer.controller.removeListener(layer.listener!);
    }
    layer.controller.dispose();
    layer.focusNode.dispose();
    layer.scrollController.dispose();
  }

  void _attachTextLayer(_NoticeTextLayer layer) {
    layer.controller.onSelectionChanged = (selection) {
      if (!selection.isValid) {
        return;
      }

      layer.lastSelection = selection;
      if (mounted && _selectedLayerId == layer.id) {
        setState(() {});
      }
    };

    void listener() {
      if (!mounted) {
        return;
      }

      final selection = layer.controller.selection;
      if (selection.isValid &&
          (!selection.isCollapsed ||
              !layer.lastSelection.isValid ||
              layer.lastSelection.isCollapsed)) {
        layer.lastSelection = selection;
      }

      _syncTextLayerWidth(layer);

      _scheduleTextLayerMeasurement(layer);
      if (_selectedLayerId == layer.id) {
        setState(() {});
      }
    }

    layer.listener = listener;
    layer.controller.addListener(listener);
  }

  void _scheduleTextLayerMeasurement(_NoticeTextLayer layer) {
    if (layer.measurePending) {
      return;
    }

    layer.measurePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      layer.measurePending = false;
      if (!mounted) {
        return;
      }

      final box =
          layer.containerKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) {
        return;
      }

      final nextHeight = box.size.height;
      if ((nextHeight - layer.boxHeight).abs() < 0.5) {
        return;
      }

      setState(() {
        layer.boxHeight = nextHeight;
        layer.offset = _clampOffset(
          layer.offset,
          layerWidth: layer.boxWidth,
          layerHeight: layer.boxHeight,
          restrictToTextMargins: true,
        );
      });
    });
  }

  void _addTextLayer({int? headerLevel, required int initialFontSize}) {
    if (_currentPage == null) {
      _showSnackBar('Add a page before adding text.');
      return;
    }

    final initialBoxWidth = (initialFontSize * 8.0)
        .clamp(_defaultTextBoxWidth, _maxTextWidth())
        .toDouble();

    final centeredOffset = _clampOffset(
      Offset(
        _textMarginLeft +
            ((_canvasWidth -
                        _textMarginLeft -
                        _textMarginRight -
                        initialBoxWidth) /
                    2)
                .clamp(0.0, _canvasWidth),
        _textMarginTop +
            ((_canvasHeight -
                        _textMarginTop -
                        _textMarginBottom -
                        _defaultTextBoxHeight) /
                    2)
                .clamp(0.0, _canvasHeight),
      ),
      layerWidth: initialBoxWidth,
      layerHeight: _defaultTextBoxHeight,
      restrictToTextMargins: true,
    );

    final layer = _NoticeTextLayer(
      id: _nextLayerId('text'),
      controller: quill.QuillController.basic(),
      focusNode: FocusNode(),
      scrollController: ScrollController(),
      containerKey: GlobalKey(),
      offset: centeredOffset,
      boxWidth: initialBoxWidth,
      boxHeight: _defaultTextBoxHeight,
      zOrder: _nextLayerZOrder(),
    );
    layer.autoWidthFontSize = initialFontSize.toDouble();

    _attachTextLayer(layer);

    setState(() {
      _textLayers.add(layer);
      _selectedLayerId = layer.id;
      _editingTextLayerId = layer.id;
    });

    layer.controller.formatSelection(quill.SizeAttribute('$initialFontSize'));
    layer.controller.formatSelection(
      quill.ColorAttribute(_colorToHex(Colors.black)),
    );
    layer.controller.formatSelection(
      quill.FontAttribute(_fontFamilies.first.value),
    );
    if (headerLevel != null) {
      _applyHeaderAttribute(layer, headerLevel);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        layer.focusNode.requestFocus();
        _scheduleTextLayerMeasurement(layer);
      }
    });
  }

  void _addHeaderLayer() {
    _addTextLayer(headerLevel: 1, initialFontSize: 24);
  }

  void _addParagraphLayer() {
    _addTextLayer(initialFontSize: 14);
  }

  _NoticeTextLayer? _selectedTextLayer() {
    if (_currentPage == null) {
      return null;
    }

    final selectedLayerId = _selectedLayerId;
    if (selectedLayerId == null) {
      return null;
    }

    for (final layer in _textLayers) {
      if (layer.id == selectedLayerId) {
        return layer;
      }
    }

    return null;
  }

  _NoticeImageLayer? _selectedImageLayer() {
    if (_currentPage == null) {
      return null;
    }

    final selectedLayerId = _selectedLayerId;
    if (selectedLayerId == null) {
      return null;
    }

    for (final layer in _imageLayers) {
      if (layer.id == selectedLayerId) {
        return layer;
      }
    }

    return null;
  }

  quill.Style _selectedStyle() {
    final layer = _selectedTextLayer();
    if (layer == null) {
      return quill.Style();
    }

    final selection = layer.lastSelection;
    if (selection.isValid && !selection.isCollapsed) {
      return layer.controller.document
          .collectAllStyles(selection.start, selection.end - selection.start)
          .fold<quill.Style>(
            quill.Style(),
            (combined, style) => combined.mergeAll(style),
          );
    }

    return layer.controller.getSelectionStyle();
  }

  bool _selectionHas(quill.Attribute attribute) {
    return _selectedStyle().attributes.containsKey(attribute.key);
  }

  String? _selectionValue(String key) {
    final value = _selectedStyle().attributes[key]?.value;
    return value?.toString();
  }

  void _selectLayer(String id) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      if (_selectedLayerId != id) {
        _editingTextLayerId = null;
      }
      _selectedLayerId = id;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _dialogFocusNode.requestFocus();
      }
    });
  }

  void _clearSelection() {
    final selectedTextLayer = _selectedTextLayer();
    if (selectedTextLayer != null) {
      selectedTextLayer.lastSelection = const TextSelection.collapsed(
        offset: 0,
      );
      selectedTextLayer.controller.updateSelection(
        const TextSelection.collapsed(offset: 0),
        quill.ChangeSource.local,
      );
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedLayerId = null;
      _editingTextLayerId = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _dialogFocusNode.requestFocus();
      }
    });
  }

  bool _isEditingTextLayer(String id) {
    return _editingTextLayerId == id;
  }

  void _beginTextEditing(_NoticeTextLayer layer) {
    setState(() {
      _selectedLayerId = layer.id;
      _editingTextLayerId = layer.id;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        layer.focusNode.requestFocus();
      }
    });
  }

  void _stopTextEditing() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) {
      return;
    }

    setState(() {
      _editingTextLayerId = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _dialogFocusNode.requestFocus();
      }
    });
  }

  void _toggleSelectionAttribute(quill.Attribute attribute) {
    final layer = _selectedTextLayer();
    if (layer == null) {
      return;
    }

    final exists = _selectionHas(attribute);
    _applySelectionFormat(
      layer,
      exists ? quill.Attribute.clone(attribute, null) : attribute,
    );
  }

  void _applyHeaderStyle(int? level) {
    final layer = _selectedTextLayer();
    if (layer == null) {
      return;
    }

    layer.autoWidthFontSize = switch (level) {
      1 => 24,
      2 => 20,
      3 => 18,
      _ => 14,
    }.toDouble();

    final attribute = level == null
        ? quill.Attribute.clone(quill.Attribute.header, null)
        : switch (level) {
            1 => quill.Attribute.h1,
            2 => quill.Attribute.h2,
            3 => quill.Attribute.h3,
            _ => quill.Attribute.clone(quill.Attribute.header, null),
          };

    _applySelectionFormat(layer, attribute, remeasure: true);
  }

  void _applyHeaderAttribute(_NoticeTextLayer layer, int? level) {
    final attribute = level == null
        ? quill.Attribute.clone(quill.Attribute.header, null)
        : switch (level) {
            1 => quill.Attribute.h1,
            2 => quill.Attribute.h2,
            3 => quill.Attribute.h3,
            _ => quill.Attribute.clone(quill.Attribute.header, null),
          };

    _restoreSelection(layer);
    layer.controller.formatSelection(attribute);
  }

  void _applyFontFamily(String fontFamily) {
    final layer = _selectedTextLayer();
    if (layer == null) {
      return;
    }

    _applySelectionFormat(layer, quill.FontAttribute(fontFamily));
  }

  void _applyFontSize(int size) {
    final layer = _selectedTextLayer();
    if (layer == null) {
      return;
    }

    layer.autoWidthFontSize = size.toDouble();
    _applySelectionFormat(layer, quill.SizeAttribute('$size'), remeasure: true);
  }

  void _applyTextColor(Color color) {
    final layer = _selectedTextLayer();
    if (layer == null) {
      return;
    }

    _applySelectionFormat(layer, quill.ColorAttribute(_colorToHex(color)));
  }

  void _applyTextAlignment(quill.Attribute<String?> attribute) {
    final layer = _selectedTextLayer();
    if (layer == null) {
      return;
    }

    _applySelectionFormat(layer, attribute, remeasure: true);
  }

  void _updateSelectedTextWidth(double value) {
    final layer = _selectedTextLayer();
    if (layer == null) {
      return;
    }

    setState(() {
      layer.autoWidth = false;
      layer.boxWidth = value;
      layer.offset = _clampOffset(
        layer.offset,
        layerWidth: layer.boxWidth,
        layerHeight: layer.boxHeight,
        restrictToTextMargins: true,
      );
    });

    _scheduleTextLayerMeasurement(layer);
  }

  void _placeSelectedText(Alignment alignment) {
    final layer = _selectedTextLayer();
    if (layer == null) {
      return;
    }

    final minDx = _textMarginLeft;
    final maxDx = (_canvasWidth - _textMarginRight - layer.boxWidth)
        .clamp(minDx, _canvasWidth)
        .toDouble();
    final minDy = _textMarginTop;
    final maxDy = (_canvasHeight - _textMarginBottom - layer.boxHeight)
        .clamp(minDy, _canvasHeight)
        .toDouble();
    final availableWidth = (maxDx - minDx).clamp(0.0, _canvasWidth).toDouble();
    final availableHeight = (maxDy - minDy)
        .clamp(0.0, _canvasHeight)
        .toDouble();

    setState(() {
      layer.offset = _clampOffset(
        Offset(
          minDx + ((alignment.x + 1) / 2) * availableWidth,
          minDy + ((alignment.y + 1) / 2) * availableHeight,
        ),
        layerWidth: layer.boxWidth,
        layerHeight: layer.boxHeight,
        restrictToTextMargins: true,
      );
    });
  }

  void _nudgeSelectedText(Offset delta) {
    final layer = _selectedTextLayer();
    if (layer == null) {
      return;
    }

    setState(() {
      layer.offset = _clampOffset(
        layer.offset + delta,
        layerWidth: layer.boxWidth,
        layerHeight: layer.boxHeight,
        restrictToTextMargins: true,
      );
    });
  }

  void _moveTextLayer(_NoticeTextLayer layer, Offset delta) {
    layer.offset = _clampOffset(
      layer.offset + delta,
      layerWidth: layer.boxWidth,
      layerHeight: layer.boxHeight,
      restrictToTextMargins: true,
    );
    _invalidateCanvas();
  }

  void _moveImageLayer(_NoticeImageLayer layer, Offset delta) {
    layer.offset = _clampOffset(
      layer.offset + delta,
      layerWidth: layer.width,
      layerHeight: layer.height,
    );
    _invalidateCanvas();
  }

  Offset _clampOffset(
    Offset candidate, {
    required double layerWidth,
    required double layerHeight,
    bool restrictToTextMargins = false,
  }) {
    final minDx = restrictToTextMargins ? _textMarginLeft : 0.0;
    final minDy = restrictToTextMargins ? _textMarginTop : 0.0;
    final maxDx =
        (restrictToTextMargins
                ? _canvasWidth - _textMarginRight - layerWidth
                : _canvasWidth - layerWidth)
            .clamp(minDx, _canvasWidth)
            .toDouble();
    final maxDy =
        (restrictToTextMargins
                ? _canvasHeight - _textMarginBottom - layerHeight
                : _canvasHeight - layerHeight)
            .clamp(minDy, _canvasHeight)
            .toDouble();

    return Offset(
      candidate.dx.clamp(minDx, maxDx).toDouble(),
      candidate.dy.clamp(minDy, maxDy).toDouble(),
    );
  }

  void _updateSelectedImageWidth(double value) {
    final layer = _selectedImageLayer();
    if (layer == null) {
      return;
    }

    final height = value * layer.intrinsicHeight / layer.intrinsicWidth;
    setState(() {
      layer.width = value;
      layer.height = height;
      layer.offset = _clampOffset(
        layer.offset,
        layerWidth: layer.width,
        layerHeight: layer.height,
      );
    });
  }

  void _removeSelectedLayer() {
    final textLayer = _selectedTextLayer();
    if (textLayer != null) {
      setState(() {
        _textLayers.remove(textLayer);
        _selectedLayerId = null;
        _editingTextLayerId = null;
      });
      _disposeTextLayer(textLayer);
      return;
    }

    final imageLayer = _selectedImageLayer();
    if (imageLayer == null) {
      return;
    }

    setState(() {
      _imageLayers.remove(imageLayer);
      _selectedLayerId = null;
    });
  }

  KeyEventResult _handleDialogKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey != LogicalKeyboardKey.delete) {
      return KeyEventResult.ignored;
    }

    final selectedTextLayer = _selectedTextLayer();
    if (selectedTextLayer != null &&
        _isEditingTextLayer(selectedTextLayer.id)) {
      return KeyEventResult.ignored;
    }

    if (selectedTextLayer == null && _selectedImageLayer() == null) {
      return KeyEventResult.ignored;
    }

    _removeSelectedLayer();
    return KeyEventResult.handled;
  }

  String _colorToHex(Color color) {
    final rgb = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
    return '#${rgb.toUpperCase()}';
  }

  void _invalidateCanvas() {
    _canvasRefreshNotifier.value++;
  }

  void _restoreSelection(_NoticeTextLayer layer) {
    final selection = layer.lastSelection;
    if (!selection.isValid) {
      return;
    }

    layer.controller.updateSelection(selection, quill.ChangeSource.local);
  }

  void _syncTextLayerWidth(_NoticeTextLayer layer) {
    if (!layer.autoWidth) {
      return;
    }

    final plainText = layer.controller.document
        .toPlainText()
        .replaceAll('\r', '')
        .replaceAll('\u0000', '');
    final longestLineLength = plainText
        .split('\n')
        .map((line) => line.trimRight().length)
        .fold<int>(0, (current, next) => next > current ? next : current);
    final estimatedCharacters = longestLineLength < 6 ? 6 : longestLineLength;
    final estimatedWidth =
        24 + (estimatedCharacters * layer.autoWidthFontSize * 0.64);
    final nextWidth = estimatedWidth
        .clamp(_defaultTextBoxWidth, _maxTextWidth())
        .toDouble();

    if ((nextWidth - layer.boxWidth).abs() < 1) {
      return;
    }

    setState(() {
      layer.boxWidth = nextWidth;
      layer.offset = _clampOffset(
        layer.offset,
        layerWidth: layer.boxWidth,
        layerHeight: layer.boxHeight,
        restrictToTextMargins: true,
      );
    });
  }

  void _applySelectionFormat(
    _NoticeTextLayer layer,
    quill.Attribute attribute, {
    bool remeasure = false,
  }) {
    final selection = layer.lastSelection;
    if (selection.isValid && !selection.isCollapsed) {
      layer.controller.formatText(
        selection.start,
        selection.end - selection.start,
        attribute,
      );
      layer.controller.updateSelection(selection, quill.ChangeSource.local);
    } else {
      final documentLength = math.max(0, layer.controller.document.length - 1);
      if (documentLength > 0) {
        final wholeLayerSelection = TextSelection(
          baseOffset: 0,
          extentOffset: documentLength,
        );
        layer.lastSelection = wholeLayerSelection;
        layer.controller.formatText(0, documentLength, attribute);
        layer.controller.updateSelection(
          wholeLayerSelection,
          quill.ChangeSource.local,
        );
      } else {
        _restoreSelection(layer);
        layer.controller.formatSelection(attribute);
      }
    }

    if (remeasure) {
      _scheduleTextLayerMeasurement(layer);
    }
    setState(() {});
  }

  double _maxTextWidth() {
    return (_canvasWidth - _textMarginLeft - _textMarginRight)
        .clamp(_defaultTextBoxWidth, _canvasWidth)
        .toDouble();
  }

  void _updateTextMargins({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    setState(() {
      _textMarginLeft = left ?? _textMarginLeft;
      _textMarginTop = top ?? _textMarginTop;
      _textMarginRight = right ?? _textMarginRight;
      _textMarginBottom = bottom ?? _textMarginBottom;

      final currentPage = _currentPage;
      if (currentPage == null) {
        return;
      }

      final maxWidth = _maxTextWidth();
      for (final layer in currentPage.textLayers) {
        if (layer.boxWidth > maxWidth) {
          layer.boxWidth = maxWidth;
        }
        layer.offset = _clampOffset(
          layer.offset,
          layerWidth: layer.boxWidth,
          layerHeight: layer.boxHeight,
          restrictToTextMargins: true,
        );
      }
    });
  }

  Color _colorFromHex(String value) {
    final normalized = value.replaceAll('#', '').trim();
    if (normalized.length != 6) {
      return Colors.black;
    }

    return Color(int.parse('FF$normalized', radix: 16));
  }

  Map<String, dynamic>? _buildGenericHeaderRequest() {
    final header = ApiService.userHeader;
    if (header == null) {
      return null;
    }

    return Map<String, dynamic>.from(header);
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

    return 'Notice request completed.';
  }

  String _formatDisplayDate(DateTime value) {
    String twoDigits(int part) => part.toString().padLeft(2, '0');
    return '${twoDigits(value.day)}-${twoDigits(value.month)}-${value.year}';
  }

  String _formatRequestDate(DateTime value) {
    String twoDigits(int part) => part.toString().padLeft(2, '0');
    return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)}';
  }

  void _setPublishingDate(DateTime value) {
    _publishingDate = DateTime(value.year, value.month, value.day);
    _publishingDateController.text = _formatDisplayDate(_publishingDate!);
  }

  Future<void> _pickPublishingDate() async {
    final now = DateTime.now();
    final initial = _publishingDate ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted || date == null) {
      return;
    }

    _setPublishingDate(DateTime(date.year, date.month, date.day));
    setState(() {});
  }

  pdf.PdfColor? _pdfColorFromHex(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final normalized = value.replaceAll('#', '').trim();
    if (normalized.length != 6) {
      return null;
    }

    return pdf.PdfColor.fromInt(int.parse('FF$normalized', radix: 16));
  }

  pw.Font _pdfFontForFamily(String? family) {
    final normalized = family?.toLowerCase().trim() ?? '';
    if (normalized.contains('source code') || normalized.contains('courier')) {
      return pw.Font.courier();
    }
    if (normalized.contains('merriweather') ||
        normalized.contains('playfair') ||
        normalized.contains('georgia') ||
        normalized.contains('times')) {
      return pw.Font.times();
    }
    return pw.Font.helvetica();
  }

  double _pdfFontSize(Map<String, dynamic> attributes, double fallback) {
    final sizeValue = attributes[quill.Attribute.size.key];
    final parsedSize = sizeValue == null
        ? null
        : double.tryParse(sizeValue.toString());
    if (parsedSize != null) {
      return parsedSize;
    }

    final headerValue = attributes[quill.Attribute.header.key];
    final headerLevel = headerValue is int
        ? headerValue
        : int.tryParse(headerValue?.toString() ?? '');
    return switch (headerLevel) {
      1 => 24,
      2 => 20,
      3 => 18,
      _ => fallback,
    };
  }

  pw.TextAlign _pdfTextAlignForLayer(_NoticeTextLayer layer) {
    final style = layer.controller.document.collectStyle(
      0,
      math.max(1, layer.controller.document.length - 1),
    );
    final alignValue = style.attributes[quill.Attribute.align.key]?.value
        ?.toString();
    return switch (alignValue) {
      'center' => pw.TextAlign.center,
      'right' => pw.TextAlign.right,
      'justify' => pw.TextAlign.justify,
      _ => pw.TextAlign.left,
    };
  }

  pw.TextStyle _pdfTextStyleFromAttributes(
    Map<String, dynamic> attributes, {
    required double fallbackFontSize,
  }) {
    final isBold = attributes[quill.Attribute.bold.key] == true;
    final isItalic = attributes[quill.Attribute.italic.key] == true;
    final isUnderline = attributes[quill.Attribute.underline.key] == true;
    final isStrike = attributes[quill.Attribute.strikeThrough.key] == true;
    final color = _pdfColorFromHex(
      attributes[quill.Attribute.color.key]?.toString(),
    );

    return pw.TextStyle(
      font: _pdfFontForFamily(attributes[quill.Attribute.font.key]?.toString()),
      fontSize: _pdfFontSize(attributes, fallbackFontSize),
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontStyle: isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
      decoration: isUnderline
          ? pw.TextDecoration.underline
          : isStrike
          ? pw.TextDecoration.lineThrough
          : pw.TextDecoration.none,
      color: color,
      lineSpacing: 1.15,
    );
  }

  pw.InlineSpan _buildPdfTextSpan(_NoticeTextLayer layer) {
    final operations = layer.controller.document.toDelta().toJson();
    final spans = <pw.InlineSpan>[];

    for (final operation in operations) {
      final insert = operation['insert'];
      if (insert is! String || insert.isEmpty) {
        continue;
      }

      final attributes = operation['attributes'] is Map
          ? Map<String, dynamic>.from(operation['attributes'] as Map)
          : <String, dynamic>{};
      spans.add(
        pw.TextSpan(
          text: insert,
          style: _pdfTextStyleFromAttributes(
            attributes,
            fallbackFontSize: layer.autoWidthFontSize,
          ),
        ),
      );
    }

    if (spans.isEmpty) {
      return pw.TextSpan(
        text: '',
        style: _pdfTextStyleFromAttributes(
          const <String, dynamic>{},
          fallbackFontSize: layer.autoWidthFontSize,
        ),
      );
    }

    return pw.TextSpan(children: spans);
  }

  Future<Uint8List> _buildNoticePdfFromPages() async {
    final document = pw.Document();
    final pageFormat = pdf.PdfPageFormat(_canvasWidth, _canvasHeight);

    for (var index = 0; index < _pages.length; index++) {
      final page = _pages[index];
      _setNoticeCreationProgress(
        0.08 + (((index + 1) / _pages.length) * 0.72),
        'Composing page ${index + 1} of ${_pages.length}...',
      );

      final children = <pw.Widget>[
        pw.Positioned.fill(child: pw.Container(color: pdf.PdfColors.white)),
      ];

      if (page.backgroundBytes != null && page.backgroundBytes!.isNotEmpty) {
        children.add(
          pw.Positioned.fill(
            child: pw.Image(
              pw.MemoryImage(page.backgroundBytes!),
              fit: pw.BoxFit.fill,
            ),
          ),
        );
      }

      final pageEntries = <_LayerStackEntry>[
        for (final imageLayer in page.imageLayers)
          _LayerStackEntry.image(layer: imageLayer),
        for (final textLayer in page.textLayers)
          _LayerStackEntry.text(layer: textLayer),
      ]..sort((a, b) => a.zOrder.compareTo(b.zOrder));

      for (final entry in pageEntries) {
        if (entry.imageLayer case final imageLayer?) {
          children.add(
            pw.Positioned(
              left: imageLayer.offset.dx,
              top: imageLayer.offset.dy,
              child: pw.Container(
                width: imageLayer.width,
                height: imageLayer.height,
                child: pw.Image(
                  pw.MemoryImage(imageLayer.bytes),
                  fit: pw.BoxFit.fill,
                ),
              ),
            ),
          );
          continue;
        }

        final textLayer = entry.textLayer!;
        children.add(
          pw.Positioned(
            left: textLayer.offset.dx,
            top: textLayer.offset.dy,
            child: pw.Container(
              width: textLayer.boxWidth,
              child: pw.RichText(
                textAlign: _pdfTextAlignForLayer(textLayer),
                text: _buildPdfTextSpan(textLayer),
              ),
            ),
          ),
        );
      }

      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Stack(children: children),
        ),
      );
    }

    _setNoticeCreationProgress(0.86, 'Finalizing PDF...');
    return Uint8List.fromList(await document.save());
  }

  Future<void> _submitNotice(String operation) async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    if (_letterHeadBytes == null || _letterHeadBytes!.isEmpty) {
      _showSnackBar('Upload a letterhead image before creating the notice.');
      return;
    }

    final genericHeader = _buildGenericHeaderRequest();
    if (genericHeader == null || genericHeader.isEmpty) {
      _showSnackBar('Login header details are not available for this request.');
      return;
    }

    if (_publishingDate == null) {
      _showSnackBar('Publishing date is required.');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _submittingNotice = true;
      _capturingNotice = true;
      _selectedLayerId = null;
      _editingTextLayerId = null;
      _noticeCreationProgress = 0.02;
      _noticeCreationStatus = 'Preparing notice...';
    });

    await WidgetsBinding.instance.endOfFrame;

    try {
      if (_pages.isEmpty) {
        _showSnackBar('Add at least one page before creating the notice.');
        return;
      }

      _setNoticeCreationProgress(0.08, 'Composing notice PDF...');
      final pdfBytes = await _buildNoticePdfFromPages();
      _setNoticeCreationProgress(0.9, 'Uploading notice document...');

      final request = NoticeCreateRequest(
        genericHeader: genericHeader,
        noticeShortDescription: _noticeShortDescriptionController.text.trim(),
        noticeHeader: _noticeHeaderController.text.trim(),
        publishingDate: _formatRequestDate(_publishingDate!),
        letterNumber: _letterNumberController.text.trim(),
        noticeDoc: base64Encode(pdfBytes),
        operation: operation,
      );

      final response = await ApiService.createNoticeRequest(request);
      _setNoticeCreationProgress(1, 'Notice created successfully.');

      if (!mounted) {
        return;
      }

      final isSuccess = _isSuccessResponse(response);
      final message = _responseMessage(response);
      await _showResultDialog(
        title: isSuccess
            ? 'Notice ${operation == 'SAVE' ? 'Saved' : 'Published'}'
            : 'Notice Request Failed',
        message: message,
        isSuccess: isSuccess,
        closeOnAcknowledge: isSuccess,
      );
    } catch (_) {
      if (mounted) {
        await _showResultDialog(
          title: 'Notice Request Failed',
          message: 'Unable to submit the notice right now.',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submittingNotice = false;
          _capturingNotice = false;
          _noticeCreationProgress = 0;
          _noticeCreationStatus = 'Preparing notice...';
        });
      }
    }
  }

  Widget _buildNoticeCreationOverlay() {
    final percent = (_noticeCreationProgress * 100).clamp(0, 100).round();
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: const Color(0x88000000),
          alignment: Alignment.center,
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.18),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Notice Creating',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _brandTextColor,
                  ),
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: _noticeCreationProgress <= 0
                      ? null
                      : _noticeCreationProgress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: const Color(0xFFE4ECEA),
                  valueColor: const AlwaysStoppedAnimation<Color>(_brandColor),
                ),
                const SizedBox(height: 12),
                Text(
                  '$percent%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _noticeCreationStatus,
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.45, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
    bool closeOnAcknowledge = false,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final accentColor = isSuccess
            ? const Color(0xFF0F8F82)
            : const Color(0xFFB3261E);
        final accentIcon = isSuccess
            ? Icons.check_circle_rounded
            : Icons.error_rounded;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 420,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4FB),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.12),
                  blurRadius: 30,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(accentIcon, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Text(
                    message,
                    style: const TextStyle(height: 1.5, color: Colors.black87),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('OK'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (closeOnAcknowledge && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _setCanvasZoom(double targetZoom, {Offset? focalPoint}) {
    final nextZoom = targetZoom.clamp(1.0, 4.0).toDouble();
    final currentZoom = _canvasTransformationController.value
        .getMaxScaleOnAxis();
    final effectiveScale = nextZoom / currentZoom;
    if ((effectiveScale - 1.0).abs() < 0.001) {
      return;
    }

    final viewportBox =
        _canvasViewportKey.currentContext?.findRenderObject() as RenderBox?;
    final localFocal =
        focalPoint ??
        (viewportBox == null
            ? const Offset(200, 200)
            : viewportBox.size.center(Offset.zero));

    final matrix = _canvasTransformationController.value.clone();
    matrix.translate(localFocal.dx, localFocal.dy);
    matrix.scale(effectiveScale);
    matrix.translate(-localFocal.dx, -localFocal.dy);
    _canvasTransformationController.value = matrix;
    setState(() {
      _canvasZoom = nextZoom;
    });
  }

  void _handleCanvasPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }

    final viewportBox =
        _canvasViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null) {
      return;
    }

    final localPoint = viewportBox.globalToLocal(event.position);
    final scaleStep = event.scrollDelta.dy < 0 ? 1.08 : 1 / 1.08;
    _setCanvasZoom(_canvasZoom * scaleStep, focalPoint: localPoint);
  }

  TextStyle _googleFontStyle(String fontFamily) {
    try {
      return GoogleFonts.getFont(fontFamily);
    } catch (_) {
      return TextStyle(fontFamily: fontFamily);
    }
  }

  TextStyle _buildQuillCustomStyle(quill.Attribute attribute) {
    if (attribute.key == quill.Attribute.font.key &&
        attribute.value != null &&
        attribute.value.toString().trim().isNotEmpty) {
      return _googleFontStyle(attribute.value.toString());
    }

    return const TextStyle();
  }

  Widget _buildEmptyCanvas() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E5E2)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_not_supported_rounded, size: 56),
              const SizedBox(height: 12),
              Text(
                _letterHeadError ??
                    'Upload a letterhead image to start composing the notice.',
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.4),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _pickLetterHeadImage,
                style: FilledButton.styleFrom(backgroundColor: _brandColor),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Upload Letterhead'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _addPage(),
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Add Blank Page'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextLayer(_NoticeTextLayer layer) {
    final isSelected = _selectedLayerId == layer.id;
    final isEditing = _isEditingTextLayer(layer.id);
    layer.controller.readOnly = _capturingNotice || !isEditing;

    final editor = quill.QuillEditor.basic(
      key: ValueKey(layer.id),
      controller: layer.controller,
      focusNode: layer.focusNode,
      scrollController: layer.scrollController,
      config: quill.QuillEditorConfig(
        padding: EdgeInsets.zero,
        scrollable: false,
        autoFocus: false,
        expands: false,
        minHeight: 28,
        enableSelectionToolbar: true,
        onTapOutsideEnabled: false,
        customStyleBuilder: _buildQuillCustomStyle,
      ),
    );

    final content = IgnorePointer(
      ignoring: !isEditing,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: editor,
      ),
    );

    return Positioned(
      left: layer.offset.dx,
      top: layer.offset.dy,
      width: layer.boxWidth,
      child: SizedBox(
        key: layer.containerKey,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _selectLayer(layer.id);
              },
              onDoubleTap: _capturingNotice
                  ? null
                  : () => _beginTextEditing(layer),
              onPanStart: _capturingNotice || isEditing
                  ? null
                  : (_) => _selectLayer(layer.id),
              onPanUpdate: _capturingNotice || isEditing
                  ? null
                  : (details) => _moveTextLayer(layer, details.delta),
              child: MouseRegion(
                cursor: isEditing
                    ? SystemMouseCursors.text
                    : SystemMouseCursors.move,
                child: AnimatedContainer(
                  duration: Duration.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: isSelected && !_capturingNotice
                        ? Border.all(color: const Color(0x550F8F82), width: 1.2)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: content,
                ),
              ),
            ),
            if (isSelected && !_capturingNotice)
              Positioned(
                top: -18,
                left: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F8F82),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isEditing ? 'Editing text' : 'Drag anywhere to move',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: isEditing
                          ? _stopTextEditing
                          : () => _beginTextEditing(layer),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _brandTextColor,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      icon: Icon(
                        isEditing ? Icons.check_rounded : Icons.edit_rounded,
                        size: 16,
                      ),
                      label: Text(isEditing ? 'Done' : 'Edit'),
                    ),
                  ],
                ),
              ),
            if (isSelected && !_capturingNotice && !isEditing)
              Positioned(
                bottom: -20,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F6F5),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFD7E6E3)),
                  ),
                  child: const Text(
                    'Double-click to type',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterHeadCanvas() {
    if (_loadingLetterHead) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentPage == null) {
      return _buildEmptyCanvas();
    }

    final backgroundBytes = _currentPage!.backgroundBytes;

    return LayoutBuilder(
      builder: (context, constraints) {
        final widthScale = constraints.maxWidth / _canvasWidth;
        final heightScale = constraints.maxHeight / _canvasHeight;
        final scale = widthScale < heightScale ? widthScale : heightScale;
        final displayWidth = _canvasWidth * scale;
        final displayHeight = _canvasHeight * scale;

        return ClipRect(
          child: Listener(
            key: _canvasViewportKey,
            onPointerSignal: _handleCanvasPointerSignal,
            child: InteractiveViewer(
              transformationController: _canvasTransformationController,
              panEnabled: true,
              scaleEnabled: false,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(320),
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Center(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _canvasRefreshNotifier,
                    builder: (context, _, child) {
                      return SizedBox(
                        width: displayWidth,
                        height: displayHeight,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _canvasWidth,
                            height: _canvasHeight,
                            child: RepaintBoundary(
                              key: _canvasKey,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(18, 75, 69, 0.18),
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: backgroundBytes != null
                                            ? Image.memory(
                                                backgroundBytes,
                                                fit: BoxFit.fill,
                                                gaplessPlayback: true,
                                              )
                                            : const ColoredBox(
                                                color: Colors.white,
                                              ),
                                      ),
                                      if (!_capturingNotice)
                                        Positioned(
                                          left: _textMarginLeft,
                                          top: _textMarginTop,
                                          right: _textMarginRight,
                                          bottom: _textMarginBottom,
                                          child: IgnorePointer(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: const Color(
                                                    0x550F8F82,
                                                  ),
                                                  width: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (!_capturingNotice)
                                        Positioned.fill(
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: _clearSelection,
                                          ),
                                        ),
                                      for (final entry
                                          in _sortedCurrentLayerEntries())
                                        if (entry.imageLayer case final layer?)
                                          Positioned(
                                            left: layer.offset.dx,
                                            top: layer.offset.dy,
                                            width: layer.width,
                                            height: layer.height,
                                            child: GestureDetector(
                                              onTap: _capturingNotice
                                                  ? null
                                                  : () =>
                                                        _selectLayer(layer.id),
                                              onPanStart: _capturingNotice
                                                  ? null
                                                  : (_) =>
                                                        _selectLayer(layer.id),
                                              onPanUpdate: _capturingNotice
                                                  ? null
                                                  : (details) =>
                                                        _moveImageLayer(
                                                          layer,
                                                          details.delta,
                                                        ),
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  border:
                                                      !_capturingNotice &&
                                                          _selectedLayerId ==
                                                              layer.id
                                                      ? Border.all(
                                                          color: _brandColor,
                                                          width: 2.4,
                                                        )
                                                      : null,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  boxShadow:
                                                      !_capturingNotice &&
                                                          _selectedLayerId ==
                                                              layer.id
                                                      ? const [
                                                          BoxShadow(
                                                            color: Color(
                                                              0x330F8F82,
                                                            ),
                                                            blurRadius: 16,
                                                            spreadRadius: 2,
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: Image.memory(
                                                    layer.bytes,
                                                    width: layer.width,
                                                    height: layer.height,
                                                    fit: BoxFit.fill,
                                                    gaplessPlayback: true,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          _buildTextLayer(entry.textLayer!),
                                    ],
                                  ),
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
        );
      },
    );
  }

  Widget _buildNoticeDetailsSection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Notice Details',
            style: TextStyle(
              color: _brandTextColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noticeHeaderController,
            decoration: const InputDecoration(
              labelText: 'Notice Header *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Notice header is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noticeShortDescriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notice Short Description *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Notice short description is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _publishingDateController,
            readOnly: true,
            onTap: _pickPublishingDate,
            decoration: InputDecoration(
              labelText: 'Publishing Date *',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: _pickPublishingDate,
                icon: const Icon(Icons.calendar_today_rounded),
              ),
            ),
            validator: (value) {
              if (_publishingDate == null ||
                  value == null ||
                  value.trim().isEmpty) {
                return 'Publishing date is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _letterNumberController,
            decoration: const InputDecoration(
              labelText: 'Letter Number (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextControls(_NoticeTextLayer layer) {
    final selectedFont =
        _selectionValue(quill.Attribute.font.key) ?? _fontFamilies.first.value;
    final selectedSize =
        int.tryParse(_selectionValue(quill.Attribute.size.key) ?? '14') ?? 14;
    final selectedColorValue = _selectionValue(quill.Attribute.color.key);
    final selectedColor = selectedColorValue != null
        ? _colorFromHex(selectedColorValue)
        : Colors.black;
    final selectedHeader = int.tryParse(
      _selectionValue(quill.Attribute.header.key) ?? '',
    );
    final selectedAlign = _selectionValue(quill.Attribute.align.key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Selected Text',
          style: TextStyle(
            color: _brandTextColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isEditingTextLayer(layer.id)
              ? 'You are editing this text layer. Use Done when you want to drag it again.'
              : 'Click the text layer on the letterhead to select it. Drag anywhere on the selected text to move it, or double-click to type and edit.',
          style: const TextStyle(height: 1.4, color: Colors.black54),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<int?>(
          key: ValueKey('header-${layer.id}-$selectedHeader'),
          initialValue: selectedHeader,
          decoration: const InputDecoration(
            labelText: 'Header Type',
            border: OutlineInputBorder(),
          ),
          items: _headerOptions
              .map(
                (option) => DropdownMenuItem<int?>(
                  value: option.level,
                  child: Text(option.label),
                ),
              )
              .toList(),
          onChanged: _applyHeaderStyle,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('font-${layer.id}-$selectedFont'),
          initialValue: selectedFont,
          decoration: const InputDecoration(
            labelText: 'Font Family',
            border: OutlineInputBorder(),
          ),
          selectedItemBuilder: (context) {
            return _fontFamilies
                .map(
                  (option) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      option.label,
                      style: _googleFontStyle(option.value),
                    ),
                  ),
                )
                .toList();
          },
          items: _fontFamilies
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.value,
                  child: Text(
                    option.label,
                    style: _googleFontStyle(option.value),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _applyFontFamily(value);
            }
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Font Size: ${(selectedSize < 8 ? 8 : selectedSize).toString()}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Slider(
          value: (selectedSize < 8 ? 8 : selectedSize).toDouble().clamp(8, 48),
          min: 8,
          max: 48,
          divisions: 20,
          label: '${selectedSize < 8 ? 8 : selectedSize} pt',
          activeColor: _brandColor,
          onChanged: (value) => _applyFontSize(value.round()),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    _toggleSelectionAttribute(quill.Attribute.bold),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _selectionHas(quill.Attribute.bold)
                      ? const Color(0xFFE2F3F0)
                      : null,
                ),
                child: const Text(
                  'B',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    _toggleSelectionAttribute(quill.Attribute.italic),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _selectionHas(quill.Attribute.italic)
                      ? const Color(0xFFE2F3F0)
                      : null,
                ),
                child: const Text(
                  'I',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    _toggleSelectionAttribute(quill.Attribute.underline),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _selectionHas(quill.Attribute.underline)
                      ? const Color(0xFFE2F3F0)
                      : null,
                ),
                child: const Text(
                  'U',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    _toggleSelectionAttribute(quill.Attribute.strikeThrough),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _selectionHas(quill.Attribute.strikeThrough)
                      ? const Color(0xFFE2F3F0)
                      : null,
                ),
                child: const Text(
                  'S',
                  style: TextStyle(
                    decoration: TextDecoration.lineThrough,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Text Alignment',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    _applyTextAlignment(quill.Attribute.leftAlignment),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      selectedAlign == quill.Attribute.leftAlignment.value
                      ? const Color(0xFFE2F3F0)
                      : null,
                ),
                child: const Icon(Icons.format_align_left_rounded),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    _applyTextAlignment(quill.Attribute.centerAlignment),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      selectedAlign == quill.Attribute.centerAlignment.value
                      ? const Color(0xFFE2F3F0)
                      : null,
                ),
                child: const Icon(Icons.format_align_center_rounded),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    _applyTextAlignment(quill.Attribute.rightAlignment),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      selectedAlign == quill.Attribute.rightAlignment.value
                      ? const Color(0xFFE2F3F0)
                      : null,
                ),
                child: const Icon(Icons.format_align_right_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Text Box Width: ${layer.boxWidth.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Slider(
          value: layer.boxWidth,
          min: _defaultTextBoxWidth,
          max: _maxTextWidth(),
          divisions: 60,
          activeColor: _brandColor,
          onChanged: _updateSelectedTextWidth,
        ),
        const SizedBox(height: 8),
        const Text('Font Color', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _textColors.map((color) {
            final isSelected = selectedColor.toARGB32() == color.toARGB32();
            return InkWell(
              onTap: () => _applyTextColor(color),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.white,
                    width: isSelected ? 3 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        const Text(
          'Quick Placement',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _placementPresets
              .map(
                (preset) => SizedBox(
                  width: 58,
                  child: OutlinedButton(
                    onPressed: () => _placeSelectedText(preset.alignment),
                    child: Text(preset.label),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        const Text('Nudge', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _nudgeSelectedText(const Offset(0, -8)),
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _nudgeSelectedText(const Offset(-8, 0)),
              icon: const Icon(Icons.keyboard_arrow_left_rounded),
            ),
            const SizedBox(width: 18),
            IconButton(
              onPressed: () => _nudgeSelectedText(const Offset(8, 0)),
              icon: const Icon(Icons.keyboard_arrow_right_rounded),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _nudgeSelectedText(const Offset(0, 8)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControls() {
    final selectedTextLayer = _selectedTextLayer();
    final selectedImageLayer = _selectedImageLayer();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Notice Configuration',
            style: TextStyle(
              color: _brandTextColor,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _letterHeadError == null
                ? 'Add text directly on the image, use the mouse wheel to zoom, and keep text inside the configured margins. Overlay images can still move anywhere on the letterhead.'
                : _letterHeadError!,
            style: const TextStyle(height: 1.45, color: Colors.black54),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pages: ${_pages.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _brandTextColor,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _showAddPageDialog,
                style: FilledButton.styleFrom(backgroundColor: _brandColor),
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Add Page'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_pages.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<Widget>.generate(_pages.length, (index) {
                final page = _pages[index];
                final selected = index == _currentPageIndex;
                return ChoiceChip(
                  selected: selected,
                  label: Text(
                    'Page ${index + 1}${page.backgroundBytes == null ? ' - Blank' : ''}',
                  ),
                  onSelected: (_) => _switchToPage(index),
                  selectedColor: const Color(0xFFE2F3F0),
                );
              }),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Zoom: ${(_canvasZoom * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => _setCanvasZoom(_canvasZoom / 1.15),
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              IconButton(
                onPressed: () => _setCanvasZoom(_canvasZoom * 1.15),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
              TextButton(
                onPressed: () {
                  _canvasTransformationController.value = Matrix4.identity();
                  setState(() {
                    _canvasZoom = 1.0;
                  });
                },
                child: const Text('Reset Zoom'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _pickLetterHeadImage,
            style: FilledButton.styleFrom(backgroundColor: _brandColor),
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(
              _letterHeadBytes == null
                  ? 'Upload Letterhead'
                  : 'Replace Letterhead',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _loadingLetterHead ? null : _fetchLetterHead,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Fetch Letterhead Again'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _addHeaderLayer,
            style: FilledButton.styleFrom(backgroundColor: _brandColor),
            icon: const Icon(Icons.title_rounded),
            label: const Text('Add Header Text'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _addParagraphLayer,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF124B45),
            ),
            icon: const Icon(Icons.subject_rounded),
            label: const Text('Add Paragraph Text'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _pickOverlayImage,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF355C56),
            ),
            icon: const Icon(Icons.add_photo_alternate_rounded),
            label: const Text('Import Overlay Image'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Text Margins',
            style: TextStyle(
              color: _brandTextColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Left: ${_textMarginLeft.toStringAsFixed(0)} px',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _textMarginLeft,
            min: 0,
            max: 240,
            divisions: 48,
            activeColor: _brandColor,
            onChanged: (value) => _updateTextMargins(left: value),
          ),
          Text(
            'Right: ${_textMarginRight.toStringAsFixed(0)} px',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _textMarginRight,
            min: 0,
            max: 240,
            divisions: 48,
            activeColor: _brandColor,
            onChanged: (value) => _updateTextMargins(right: value),
          ),
          Text(
            'Top: ${_textMarginTop.toStringAsFixed(0)} px',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _textMarginTop,
            min: 0,
            max: 500,
            divisions: 100,
            activeColor: _brandColor,
            onChanged: (value) => _updateTextMargins(top: value),
          ),
          Text(
            'Bottom: ${_textMarginBottom.toStringAsFixed(0)} px',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _textMarginBottom,
            min: 0,
            max: 240,
            divisions: 48,
            activeColor: _brandColor,
            onChanged: (value) => _updateTextMargins(bottom: value),
          ),
          const SizedBox(height: 24),
          _buildNoticeDetailsSection(),
          const SizedBox(height: 24),
          if (selectedTextLayer != null) ...[
            _buildTextControls(selectedTextLayer),
            const SizedBox(height: 20),
          ],
          if (selectedImageLayer != null) ...[
            const Text(
              'Selected Image',
              style: TextStyle(
                color: _brandTextColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Width: ${selectedImageLayer.width.toStringAsFixed(0)} px',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: selectedImageLayer.width,
              min: 40,
              max: (_canvasWidth * 0.8).clamp(120.0, 700.0).toDouble(),
              divisions: 50,
              activeColor: _brandColor,
              onChanged: _updateSelectedImageWidth,
            ),
            const SizedBox(height: 20),
          ],
          if (selectedTextLayer == null && selectedImageLayer == null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5F4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD7E6E3)),
              ),
              child: const Text(
                'Select a text box or image on the preview to change its style, size, or placement.',
                style: TextStyle(height: 1.45, color: Colors.black54),
              ),
            ),
          if (selectedTextLayer != null || selectedImageLayer != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _canMoveSelectedLayerBackward()
                        ? _moveSelectedLayerBackward
                        : null,
                    icon: const Icon(Icons.flip_to_back_rounded),
                    label: const Text('Send Backward'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _canMoveSelectedLayerForward()
                        ? _moveSelectedLayerForward
                        : null,
                    icon: const Icon(Icons.flip_to_front_rounded),
                    label: const Text('Bring Forward'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _removeSelectedLayer,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Remove Selected Layer'),
            ),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _submittingNotice
                      ? null
                      : () => _submitNotice('SAVE'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF124B45),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _submittingNotice
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save Notice'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _submittingNotice
                      ? null
                      : () => _submitNotice('PUBLISH'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _submittingNotice
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.campaign_outlined),
                  label: const Text('Publish Notice'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _dialogFocusNode,
      autofocus: true,
      onKeyEvent: _handleDialogKeyEvent,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1380, maxHeight: 900),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F4FB),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.12),
                blurRadius: 40,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 18, 18),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Notice',
                                style: TextStyle(
                                  color: _brandTextColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 28,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Write directly on the letterhead, style selected text only, fill the notice details, then save or publish.',
                                style: TextStyle(
                                  color: Colors.black54,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            color: const Color(0xFFF0F5F4),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: _maxCanvasWidth,
                                  maxHeight: _maxCanvasHeight,
                                ),
                                child: _buildLetterHeadCanvas(),
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, color: const Color(0xFFDDE7E5)),
                        Expanded(flex: 2, child: _buildControls()),
                      ],
                    ),
                  ),
                ],
              ),
              if (_submittingNotice) _buildNoticeCreationOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeTextLayer {
  _NoticeTextLayer({
    required this.id,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.containerKey,
    required this.offset,
    required this.boxWidth,
    required this.boxHeight,
    required this.zOrder,
  });

  final String id;
  final quill.QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final GlobalKey containerKey;
  Offset offset;
  double boxWidth;
  double boxHeight;
  int zOrder;
  bool measurePending = false;
  bool autoWidth = true;
  double autoWidthFontSize = _CreateNoticeDialogState._defaultAutosizeFontSize;
  TextSelection lastSelection = const TextSelection.collapsed(offset: 0);
  VoidCallback? listener;
}

class _NoticePage {
  _NoticePage({
    required this.backgroundBytes,
    required this.textLayers,
    required this.imageLayers,
  });

  Uint8List? backgroundBytes;
  final List<_NoticeTextLayer> textLayers;
  final List<_NoticeImageLayer> imageLayers;
}

class _NoticeImageLayer {
  _NoticeImageLayer({
    required this.id,
    required this.bytes,
    required this.offset,
    required this.width,
    required this.height,
    required this.intrinsicWidth,
    required this.intrinsicHeight,
    required this.zOrder,
  });

  final String id;
  final Uint8List bytes;
  Offset offset;
  double width;
  double height;
  final double intrinsicWidth;
  final double intrinsicHeight;
  int zOrder;
}

class _LayerStackEntry {
  const _LayerStackEntry._({
    required this.id,
    required this.textLayer,
    required this.imageLayer,
  });

  factory _LayerStackEntry.text({required _NoticeTextLayer layer}) {
    return _LayerStackEntry._(id: layer.id, textLayer: layer, imageLayer: null);
  }

  factory _LayerStackEntry.image({required _NoticeImageLayer layer}) {
    return _LayerStackEntry._(id: layer.id, textLayer: null, imageLayer: layer);
  }

  final String id;
  final _NoticeTextLayer? textLayer;
  final _NoticeImageLayer? imageLayer;

  int get zOrder => textLayer?.zOrder ?? imageLayer!.zOrder;

  set zOrder(int value) {
    if (textLayer != null) {
      textLayer!.zOrder = value;
      return;
    }
    imageLayer!.zOrder = value;
  }
}

class _FontFamilyOption {
  const _FontFamilyOption({required this.label, required this.value});

  final String label;
  final String value;
}

class _HeaderOption {
  const _HeaderOption({required this.label, required this.level});

  final String label;
  final int? level;
}

class _PlacementPreset {
  const _PlacementPreset(this.label, this.alignment);

  final String label;
  final Alignment alignment;
}
