import 'dart:convert';

import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
import '../services/api_service.dart';

class SideBar extends StatefulWidget {
  const SideBar({
    super.key,
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final AppSection selectedSection;
  final ValueChanged<AppSection> onSectionSelected;

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  String? _cachedProfileSource;
  MemoryImage? _cachedProfileImage;

  Widget item(
    String title,
    IconData icon, {
    AppSection? section,
    VoidCallback? onTap,
  }) {
    final effectiveOnTap =
        onTap ??
        (section == null ? null : () => widget.onSectionSelected(section));

    return _SidebarItem(
      title: title,
      icon: icon,
      selected: section != null && widget.selectedSection == section,
      onTap: effectiveOnTap,
    );
  }

  void _syncProfileImage() {
    final profilePic = ApiService.dashboardProfilePic;
    if (profilePic == null || profilePic.trim().isEmpty) {
      _cachedProfileSource = null;
      _cachedProfileImage = null;
      return;
    }

    final encodedValue = profilePic.contains(',')
        ? profilePic.split(',').last
        : profilePic;

    if (_cachedProfileSource == encodedValue) {
      return;
    }

    try {
      final bytes = base64Decode(encodedValue);
      _cachedProfileSource = encodedValue;
      _cachedProfileImage = MemoryImage(bytes);
    } catch (_) {
      _cachedProfileSource = encodedValue;
      _cachedProfileImage = null;
    }
  }

  String _displayName() {
    return ApiService.getDisplayName();
  }

  String _flatLabel() {
    final flatNo = ApiService.getLoggedInFlatNo();
    if (flatNo == null || flatNo.isEmpty) {
      return 'Community Portal';
    }

    return 'Flat $flatNo';
  }

  @override
  Widget build(BuildContext context) {
    _syncProfileImage();
    final displayName = _displayName();
    final flatLabel = _flatLabel();

    return Container(
      width: 240,
      color: Color(0xFF0F8F82),
      child: ListView(
        padding: EdgeInsets.only(top: 0, bottom: 16),
        children: [
          SizedBox(height: 8),

          Center(
            child: Container(
              width: 188,
              height: 188,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 4,
                ),
                image: _cachedProfileImage == null
                    ? null
                    : DecorationImage(
                        image: _cachedProfileImage!,
                        fit: BoxFit.cover,
                      ),
              ),
              child: _cachedProfileImage == null
                  ? Icon(Icons.person, size: 84)
                  : null,
            ),
          ),

          SizedBox(height: 10),

          Center(
            child: Text(
              displayName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          SizedBox(height: 4),

          Center(
            child: Text(
              flatLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          ),

          SizedBox(height: 30),

          item(
            "Dashboard",
            Icons.dashboard_outlined,
            section: AppSection.dashboard,
          ),
          item(
            "Account Management",
            Icons.person_add,
            section: AppSection.profileManagement,
          ),
          item(
            "Admin Section",
            Icons.admin_panel_settings,
            section: AppSection.adminSection,
          ),
          item("Bookings", Icons.event_available, section: AppSection.bookings),
          item(
            "Meeting And Notice",
            Icons.event_note,
            section: AppSection.meetingAndNotice,
          ),
          item("Finance", Icons.account_balance, section: AppSection.finance),
          item(
            "Ticket Management",
            Icons.confirmation_number,
            section: AppSection.ticketManagement,
          ),
          item("Security", Icons.security, section: AppSection.security),
          item(
            "Group Management",
            Icons.groups,
            section: AppSection.groupManagement,
          ),
          item(
            "Vendor Management",
            Icons.storefront,
            section: AppSection.vendorManagement,
          ),
          item("Reports", Icons.assessment, section: AppSection.reports),
          item("Others", Icons.more_horiz, section: AppSection.others),
          item("Create Skill Class", Icons.school),
          item("View Classes", Icons.list),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final glowColor = Colors.white.withValues(alpha: 0.35);
    final isActive = widget.selected;
    final tileColor = isActive
        ? Colors.white.withValues(alpha: 0.16)
        : hovered
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: ListTile(
        selected: isActive,
        selectedTileColor: Colors.transparent,
        tileColor: tileColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(widget.icon, color: Colors.white),
        title: AnimatedDefaultTextStyle(
          duration: Duration(milliseconds: 180),
          style: TextStyle(
            color: Colors.white,
            fontWeight: (hovered || isActive)
                ? FontWeight.bold
                : FontWeight.w500,
            shadows: (hovered || isActive)
                ? [Shadow(color: glowColor, blurRadius: 12)]
                : null,
          ),
          child: Text(widget.title),
        ),
        onTap: widget.onTap,
        enabled: widget.onTap != null,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}
