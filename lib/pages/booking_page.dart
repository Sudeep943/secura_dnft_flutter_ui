import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/sidebar.dart';
import 'create_booking_page.dart';

class BookingPage extends StatefulWidget {
  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0F8F82),
        title: Text("Booking"),
        leading: IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      drawer: isMobile(context) ? Drawer(child: SideBar()) : null,
      body: Row(
        children: [
          if (!isMobile(context)) SideBar(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 700),
                child: GridView.count(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  crossAxisCount: isMobile(context) ? 1 : 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.4,
                  children: [
                    _BookingActionCard(
                      title: 'Create New Booking',
                      icon: Icons.add_box,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateBookingPage(),
                          ),
                        );
                      },
                    ),
                    _BookingActionCard(
                      title: 'View Bookings',
                      icon: Icons.list_alt,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('View Bookings tapped')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _BookingActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  __BookingActionCardState createState() => __BookingActionCardState();
}

class __BookingActionCardState extends State<_BookingActionCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: hovered ? Color(0xFFE0DA84) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 50, color: Color(0xFF0F8F82)),
              SizedBox(height: 15),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
