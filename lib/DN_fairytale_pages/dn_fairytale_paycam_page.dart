import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../services/api_service.dart';

class DnFairytalePayCamPage extends StatefulWidget {
  const DnFairytalePayCamPage({super.key});

  @override
  State<DnFairytalePayCamPage> createState() => _DnFairytalePayCamPageState();
}

class _DnFairytalePayCamPageState extends State<DnFairytalePayCamPage> {
  static const Color _brand = Color(0xFF0F8F82);
  static const Color _brandDark = Color(0xFF0B6A60);
  static const Color _title = Color(0xFF153D36);

  String? _selectedFlatId;
  List<_FlatSelectionNode> _flatNodes = const [];
  Map<String, String> _flatLabelById = const {};
  bool _loadingFlats = false;
  String? _flatLoadError;
  bool _loadingDueDetails = false;

  @override
  void initState() {
    super.initState();
    _loadPublicFlats();
  }

  Future<void> _loadPublicFlats() async {
    setState(() {
      _loadingFlats = true;
      _flatLoadError = null;
    });

    try {
      final response = await ApiService.getFlatsPublic();
      if (!mounted) {
        return;
      }

      if (response == null || !_isSuccessResponse(response)) {
        setState(() {
          _flatNodes = const [];
          _selectedFlatId = null;
          _flatLoadError = _responseMessage(response);
        });
        return;
      }

      final nodes = _buildFlatNodes(response);
      final allFlatIds = _collectFlatIds(nodes);
      final labelMap = _buildFlatLabelMap(nodes);
      setState(() {
        _flatNodes = nodes;
        _flatLabelById = labelMap;
        _selectedFlatId = allFlatIds.contains(_selectedFlatId)
            ? _selectedFlatId
            : (allFlatIds.isEmpty ? null : allFlatIds.first);
        _flatLoadError = allFlatIds.isEmpty
            ? 'No flats were returned for this apartment.'
            : null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _flatNodes = const [];
        _flatLabelById = const {};
        _selectedFlatId = null;
        _flatLoadError = 'Unable to load flat list right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingFlats = false;
        });
      }
    }
  }

  bool _isSuccessResponse(Map<String, dynamic> response) {
    final messageCode = response['messageCode']?.toString() ?? '';
    if (messageCode.toUpperCase().startsWith('SUCC')) {
      return true;
    }

    final payload = _extractFlatPayload(response);
    return payload['blockList'] is List ||
        payload['towerList'] is List ||
        payload['flatList'] is List;
  }

  String _responseMessage(Map<String, dynamic>? response) {
    final message = response?['message']?.toString().trim() ?? '';
    if (message.isNotEmpty) {
      return message;
    }
    return 'Unable to load flat list right now.';
  }

  List<_FlatSelectionNode> _buildFlatNodes(Map<String, dynamic> response) {
    final payload = _extractFlatPayload(response);
    final nodes = <_FlatSelectionNode>[];
    final blockList = _asMapList(payload['blockList']);
    for (var index = 0; index < blockList.length; index++) {
      nodes.addAll(_nodesFromBlock(blockList[index], 'block_$index'));
    }

    final topLevelTowers = _asMapList(payload['towerList']);
    for (var index = 0; index < topLevelTowers.length; index++) {
      nodes.addAll(_nodesFromTower(topLevelTowers[index], 'top_tower_$index'));
    }

    final rootFlatNodes = _flatLeafNodes(
      _asStringList(payload['flatList']),
      'root-flat',
    );
    if (rootFlatNodes.isNotEmpty) {
      nodes.addAll(rootFlatNodes);
    }

    return nodes;
  }

  Map<String, dynamic> _extractFlatPayload(Map<String, dynamic> response) {
    final data = response['data'];
    final root = data is Map
        ? Map<String, dynamic>.from(data)
        : Map<String, dynamic>.from(response);

    dynamic readAny(List<String> keys) {
      for (final key in keys) {
        if (root.containsKey(key)) {
          return root[key];
        }
      }
      return null;
    }

    return {
      'blockList': readAny(['blockList', 'blocklist', 'blocks', 'block']),
      'towerList': readAny(['towerList', 'towerlist', 'towers', 'tower']),
      'flatList': readAny([
        'flatList',
        'flatlist',
        'flats',
        'flatIdList',
        'flatIds',
      ]),
    };
  }

  List<_FlatSelectionNode> _nodesFromBlock(
    Map<String, dynamic> block,
    String keyBase,
  ) {
    final blockName = _safeText(block['blockName']);
    final flatChildren = _flatLeafNodes(
      _asStringList(block['flatList']),
      '$keyBase-flat',
    );
    final towerChildren = <_FlatSelectionNode>[];
    final towerList = _asMapList(block['towerList']);
    for (var index = 0; index < towerList.length; index++) {
      towerChildren.addAll(
        _nodesFromTower(towerList[index], '$keyBase-tower_$index'),
      );
    }

    final children = [...flatChildren, ...towerChildren];
    if (blockName.isEmpty) {
      return children;
    }
    if (children.isEmpty) {
      return const [];
    }

    return [
      _FlatSelectionNode(
        key: keyBase,
        label: 'Block $blockName',
        children: children,
      ),
    ];
  }

  List<_FlatSelectionNode> _nodesFromTower(
    Map<String, dynamic> tower,
    String keyBase,
  ) {
    final towerName = _safeText(tower['towerName']);
    final flatChildren = _flatLeafNodes(
      _asStringList(tower['flatList']),
      '$keyBase-flat',
    );

    if (towerName.isEmpty) {
      return flatChildren;
    }
    if (flatChildren.isEmpty) {
      return const [];
    }

    return [
      _FlatSelectionNode(
        key: keyBase,
        label: 'Tower $towerName',
        children: flatChildren,
      ),
    ];
  }

  List<_FlatSelectionNode> _flatLeafNodes(
    List<String> flatIds,
    String keyBase,
  ) {
    return [
      for (var index = 0; index < flatIds.length; index++)
        _FlatSelectionNode(
          key: '$keyBase-$index',
          label: flatIds[index],
          flatId: flatIds[index],
        ),
    ];
  }

  List<String> _collectFlatIds(List<_FlatSelectionNode> nodes) {
    final flatIds = <String>[];
    for (final node in nodes) {
      flatIds.addAll(node.flatIds);
    }
    return flatIds;
  }

  Future<void> _openFlatSelectionDialog() async {
    if (_loadingFlats || _flatNodes.isEmpty) {
      return;
    }

    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _FlatSelectionDialog(
        nodes: _flatNodes,
        initialFlatId: _selectedFlatId,
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedFlatId = selected;
    });
  }

  String _buildSelectedFlatDisplayText() {
    if (_loadingFlats) {
      return 'Loading flats...';
    }
    if (_selectedFlatId == null || _selectedFlatId!.isEmpty) {
      return 'Select flat';
    }
    return _flatLabelById[_selectedFlatId!] ?? _selectedFlatId!;
  }

  Map<String, String> _buildFlatLabelMap(List<_FlatSelectionNode> nodes) {
    final result = <String, String>{};

    void visit(_FlatSelectionNode node) {
      final flatId = node.flatId;
      if (flatId != null && flatId.trim().isNotEmpty) {
        result[flatId] = node.label;
      }
      for (final child in node.children) {
        visit(child);
      }
    }

    for (final node in nodes) {
      visit(node);
    }

    return result;
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    String? mapEntryToFlatId(Map entry) {
      final map = Map<String, dynamic>.from(entry);
      const candidateKeys = [
        'flatId',
        'flatID',
        'flatNo',
        'flatNumber',
        'id',
        'value',
      ];
      for (final key in candidateKeys) {
        final text = map[key]?.toString().trim() ?? '';
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
      return null;
    }

    return value
        .map((entry) {
          if (entry is Map) {
            return mapEntryToFlatId(entry) ?? '';
          }
          return entry?.toString().trim() ?? '';
        })
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  String _safeText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.toLowerCase() == 'null' ? '' : text;
  }

  void _openResidentLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  String _formatAsCurrency(String amount) {
    final cleaned = amount.trim();
    if (cleaned.isEmpty) return '₹0';

    final rawAmount = cleaned.startsWith('₹')
        ? cleaned.substring(1)
        : cleaned.replaceFirst(RegExp(r'^Rs\s*', caseSensitive: false), '');

    final normalized = rawAmount.replaceAll(RegExp(r'[^0-9.,-]'), '');
    final sign = normalized.startsWith('-') ? '-' : '';
    final unsigned = sign.isEmpty ? normalized : normalized.substring(1);
    final parts = unsigned.split('.');
    final integerPart = parts.first.replaceAll(RegExp(r'[^0-9]'), '');

    if (integerPart.isEmpty) return '₹0';

    final withCommas = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );

    final decimalPart = parts.length > 1
        ? '.${parts.sublist(1).join().replaceAll(RegExp(r'[^0-9]'), '')}'
        : '';

    return '₹$sign$withCommas$decimalPart';
  }

  Map<String, List<Map<String, dynamic>>> _dueDetailsByPaymentFromResponse(
    Map<String, dynamic>? response,
  ) {
    final raw = response?['dueDetailsByPayment'] ?? response?['dueDetails'];
    if (raw is! Map) {
      return <String, List<Map<String, dynamic>>>{};
    }

    final result = <String, List<Map<String, dynamic>>>{};
    raw.forEach((key, rawValue) {
      final list = <Map<String, dynamic>>[];
      if (rawValue is List) {
        for (final item in rawValue.whereType<Map>()) {
          list.add(Map<String, dynamic>.from(item));
        }
      } else if (rawValue is Map) {
        list.add(Map<String, dynamic>.from(rawValue));
      }

      if (list.isNotEmpty) {
        result[key.toString()] = list;
      }
    });

    return result;
  }

  List<Map<String, dynamic>> _flattenDueDetailsByPayment(
    Map<String, List<Map<String, dynamic>>> dueDetailsByPayment,
  ) {
    final flatList = <Map<String, dynamic>>[];
    for (final entries in dueDetailsByPayment.values) {
      for (final entry in entries) {
        flatList.add(Map<String, dynamic>.from(entry));
      }
    }
    return flatList;
  }

  Future<void> _openDueDetailsDialog() async {
    final flatId = _selectedFlatId?.trim() ?? '';
    if (_loadingDueDetails) {
      return;
    }

    if (flatId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a flat ID first.')),
        );
      }
      return;
    }

    setState(() {
      _loadingDueDetails = true;
    });

    try {
      final response = await ApiService.getDueDetailsForFlatPublic(
        flatId: flatId,
      );
      if (!mounted) {
        return;
      }

      final duePaymentList = response?['duePaymentList'];
      final dueDetailsByPayment = _dueDetailsByPaymentFromResponse(response);

      final normalizedDueList = duePaymentList is List
          ? duePaymentList
          : const <dynamic>[];
      final displayDueList = normalizedDueList.isNotEmpty
          ? normalizedDueList
          : _flattenDueDetailsByPayment(dueDetailsByPayment);

      if (displayDueList.isEmpty && dueDetailsByPayment.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No due payments found.')));
        return;
      }

      ApiService.setPublicPayFlatNo(flatId);
      await showDialog<void>(
        context: context,
        useRootNavigator: false,
        builder: (_) => PaymentDetailsModal(
          duePaymentList: displayDueList,
          dueDetailsByPayment: dueDetailsByPayment,
          formatAsCurrency: _formatAsCurrency,
        ),
      );
      ApiService.setPublicPayFlatNo(null);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load due payment details.')),
      );
    } finally {
      ApiService.setPublicPayFlatNo(null);
      if (mounted) {
        setState(() {
          _loadingDueDetails = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Row(
                children: [
                  SizedBox(
                    width: compact ? 280 : 340,
                    height: compact ? 104 : 124,
                    child: Image.asset(
                      'DNFarytaleIamges/dn_fairytale_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Spacer(),
                  if (!compact)
                    Wrap(
                      spacing: 20,
                      children: const [
                        _TopLink(label: 'Home', active: true),
                        _TopLink(label: 'About Us'),
                        _TopLink(label: 'Facilities'),
                        _TopLink(label: 'Gallery'),
                        _TopLink(label: 'Notices'),
                        _TopLink(label: 'Contact Us'),
                      ],
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: compact
                    ? ListView(
                        children: [
                          _leftImagePanel(),
                          const SizedBox(height: 12),
                          _rightFormPanel(),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 5, child: _leftImagePanel()),
                          const SizedBox(width: 14),
                          Expanded(flex: 3, child: _rightFormPanel()),
                        ],
                      ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B6A60), Color(0xFF0F8F82)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: const Row(
                children: [
                  Text(
                    '© 2026 DN Fairytale. All rights reserved.',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Spacer(),
                  Text(
                    'Follow Us',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leftImagePanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'DNFarytaleIamges/image5.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF254E47),
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: Colors.white70,
                size: 48,
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromRGBO(0, 0, 0, 0.5), Color(0x00000000)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          const Positioned(
            left: 28,
            bottom: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to\nDN Fairytale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'A community that feels like home.',
                  style: TextStyle(color: Color(0xFFEFF6F3), fontSize: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rightFormPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E8E3)),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pay CAM',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              color: _title,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select your flat ID to continue.',
            style: TextStyle(color: Color(0xFF687D76), fontSize: 15),
          ),
          const SizedBox(height: 28),
          const Text(
            'Flat ID',
            style: TextStyle(
              color: Color(0xFF3D5A54),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _loadingFlats || _flatNodes.isEmpty
                ? null
                : _openFlatSelectionDialog,
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: 'Enter your flat id',
                filled: true,
                fillColor: const Color(0xFFF9FCFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD5E6E2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD5E6E2)),
                ),
                suffixIcon: _loadingFlats
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              child: Text(
                _buildSelectedFlatDisplayText(),
                style: TextStyle(
                  color: (_selectedFlatId == null || _selectedFlatId!.isEmpty)
                      ? Colors.black45
                      : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (_flatLoadError != null && _flatLoadError!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _flatLoadError!,
              style: const TextStyle(
                color: Color(0xFFB3261E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF5F7973),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Selected flat ID: ${_selectedFlatId ?? '--'}',
                  style: const TextStyle(
                    color: Color(0xFF5F7973),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  (_loadingDueDetails ||
                      _loadingFlats ||
                      (_selectedFlatId?.trim().isEmpty ?? true))
                  ? null
                  : _openDueDetailsDialog,
              icon: const Icon(Icons.payments_outlined),
              label: Text(
                _loadingDueDetails ? 'Loading...' : 'View Due Details',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openResidentLogin,
              icon: const Icon(Icons.person_outline_rounded),
              label: const Text('Resident Login'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _brandDark,
                side: const BorderSide(color: Color(0xFF0F8F82)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopLink extends StatelessWidget {
  const _TopLink({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF124B45) : const Color(0xFF2D3F3A);
    return Container(
      padding: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? const Color(0xFFB39A63) : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _FlatSelectionNode {
  const _FlatSelectionNode({
    required this.key,
    required this.label,
    this.children = const [],
    this.flatId,
  });

  final String key;
  final String label;
  final List<_FlatSelectionNode> children;
  final String? flatId;

  bool get isFlat => flatId != null;

  List<String> get flatIds {
    if (flatId != null) {
      return [flatId!];
    }

    final flatIds = <String>[];
    for (final child in children) {
      flatIds.addAll(child.flatIds);
    }
    return flatIds;
  }
}

class _FlatSelectionDialog extends StatefulWidget {
  const _FlatSelectionDialog({
    required this.nodes,
    required this.initialFlatId,
  });

  final List<_FlatSelectionNode> nodes;
  final String? initialFlatId;

  @override
  State<_FlatSelectionDialog> createState() => _FlatSelectionDialogState();
}

class _FlatSelectionDialogState extends State<_FlatSelectionDialog> {
  late String? _selectedFlatId;
  final Set<String> _expandedKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedFlatId = widget.initialFlatId;
  }

  void _toggleExpansion(String key) {
    setState(() {
      if (_expandedKeys.contains(key)) {
        _expandedKeys.remove(key);
      } else {
        _expandedKeys.add(key);
      }
    });
  }

  Widget _buildNode(_FlatSelectionNode node, {double indent = 0}) {
    if (node.isFlat) {
      final selected = _selectedFlatId == node.flatId;
      return Padding(
        padding: EdgeInsets.only(left: indent, bottom: 6),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF8F6) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? _DnFairytalePayCamPageState._brand
                  : const Color(0xFFD5E6E2),
            ),
          ),
          child: RadioListTile<String>(
            value: node.flatId!,
            groupValue: _selectedFlatId,
            activeColor: _DnFairytalePayCamPageState._brand,
            onChanged: (value) {
              setState(() {
                _selectedFlatId = value;
              });
            },
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text(
              node.label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF214B43),
              ),
            ),
          ),
        ),
      );
    }

    final expanded = _expandedKeys.contains(node.key);
    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4FAF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD5E6E2)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    node.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E4841),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _toggleExpansion(node.key),
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF1E4841),
                  ),
                  tooltip: expanded ? 'Collapse' : 'Expand',
                ),
              ],
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final child in node.children)
                    _buildNode(child, indent: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF8FBFB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Flat',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF153D36),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Choose your flat to view due details.',
            style: TextStyle(fontSize: 13, color: Color(0xFF687D76)),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD5E6E2)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final node in widget.nodes) _buildNode(node)],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF5C6D7E)),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _DnFairytalePayCamPageState._brand,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(_selectedFlatId),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
