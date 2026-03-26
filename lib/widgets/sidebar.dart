import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
import '../services/api_service.dart';

class SideBar extends StatelessWidget {
  const SideBar({
    super.key,
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final AppSection selectedSection;
  final ValueChanged<AppSection> onSectionSelected;

  Widget item(
    String title,
    IconData icon, {
    AppSection? section,
    VoidCallback? onTap,
  }) {
    final effectiveOnTap =
        onTap ?? (section == null ? null : () => onSectionSelected(section));

    return _SidebarItem(
      title: title,
      icon: icon,
      selected: section != null && selectedSection == section,
      onTap: effectiveOnTap,
    );
  }

  Uint8List? _profileImageBytes() {
    final profilePic = ApiService.dashboardProfilePic;
    if (profilePic == null || profilePic.trim().isEmpty) {
      return null;
    }

    final encodedValue = profilePic.contains(',')
        ? profilePic.split(',').last
        : profilePic;

    try {
      return base64Decode(encodedValue);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileImageBytes = _profileImageBytes();

    return Container(
      width: 240,
      color: Color(0xFF0F8F82),
      child: ListView(
        children: [
          SizedBox(height: 30),

          Center(
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: profileImageBytes == null
                  ? Icon(Icons.person, size: 48)
                  : Image.memory(
                      profileImageBytes,
                      fit: BoxFit.cover,
                      width: 104,
                      height: 104,
                    ),
            ),
          ),

          SizedBox(height: 10),

          Center(
            child: Text(
              "John Doe",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),

          SizedBox(height: 30),

          item("Payments", Icons.payment),
          item("Bookings", Icons.home, section: AppSection.bookings),
          item(
            "Profile Management",
            Icons.person_add,
            section: AppSection.profileManagement,
          ),
          item(
            "Meeting And Notice",
            Icons.event_note,
            section: AppSection.meetingAndNotice,
          ),
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
            "Staff Management",
            Icons.badge,
            section: AppSection.staffManagement,
          ),
          item(
            "Vendor Management",
            Icons.storefront,
            section: AppSection.vendorManagement,
          ),
          item(
            "Role And Access",
            Icons.lock_person,
            section: AppSection.roleAndAccess,
          ),
          item("Reports", Icons.assessment, section: AppSection.reports),
          item("Others", Icons.more_horiz, section: AppSection.others),
          item("Create Skill Class", Icons.school),
          item("View Classes", Icons.list),
          item("Admin Section", Icons.admin_panel_settings),
          item("Finance", Icons.account_balance, section: AppSection.finance),
          item("Worklist", Icons.work),
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
    final glowColor = Colors.white.withOpacity(0.35);
    final isActive = widget.selected;
    final tileColor = isActive
        ? Colors.white.withOpacity(0.16)
        : hovered
        ? Colors.white.withOpacity(0.08)
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
