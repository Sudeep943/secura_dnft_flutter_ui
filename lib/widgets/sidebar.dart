import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../pages/booking_page.dart';
import '../pages/profile_management_page.dart';
import '../services/api_service.dart';

class SideBar extends StatelessWidget {
  const SideBar({super.key});

  Widget item(String title, IconData icon, {VoidCallback? onTap}) {
    return _SidebarItem(title: title, icon: icon, onTap: onTap ?? () {});
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
          item(
            "Booings",
            Icons.home,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BookingPage()),
              );
            },
          ),
          item(
            "Profile Management",
            Icons.person_add,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileManagementPage(),
                ),
              );
            },
          ),
          item("Create Skill Class", Icons.school),
          item("View Classes", Icons.list),
          item("Admin Section", Icons.admin_panel_settings),
          item("Finance", Icons.account_balance),
          item("Worklist", Icons.work),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.title,
    required this.icon,
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

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: ListTile(
        leading: Icon(widget.icon, color: Colors.white),
        title: AnimatedDefaultTextStyle(
          duration: Duration(milliseconds: 180),
          style: TextStyle(
            color: Colors.white,
            fontWeight: hovered ? FontWeight.bold : FontWeight.w500,
            shadows: hovered
                ? [Shadow(color: glowColor, blurRadius: 12)]
                : null,
          ),
          child: Text(widget.title),
        ),
        onTap: widget.onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}
