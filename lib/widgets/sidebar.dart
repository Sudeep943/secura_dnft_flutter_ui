import 'package:flutter/material.dart';

class SideBar extends StatelessWidget {
  Widget item(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Color(0xFF0F8F82),
      child: ListView(
        children: [
          SizedBox(height: 30),

          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 35),
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
          item("Book Hall", Icons.home),
          item("Create Profile", Icons.person_add),
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
