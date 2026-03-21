import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onTap;

  DashboardCard(this.title, this.value, {this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Text(title),

            SizedBox(height: 10),

            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F8F82),
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}
