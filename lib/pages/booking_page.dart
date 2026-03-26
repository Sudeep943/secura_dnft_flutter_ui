import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
import '../widgets/brand_artwork.dart';
import '../widgets/sidebar.dart';
import 'check_availability_page.dart';
import 'create_booking_page.dart';
import 'view_bookings_page.dart';
import 'app_shell.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  _BookingView _selectedView = _BookingView.menu;

  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  void _showEmbeddedView(_BookingView view) {
    setState(() {
      _selectedView = view;
    });
  }

  void _goBackToMenu() {
    setState(() {
      _selectedView = _BookingView.menu;
    });
  }

  Widget _buildBookingContent(BuildContext context, {required bool embedded}) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1080),
          child: Container(
            padding: EdgeInsets.all(isMobile(context) ? 18 : 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Color(0xFF0F8F82), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bookings',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF124B45),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Choose one of the booking actions below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                SizedBox(height: 28),
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  crossAxisCount: isMobile(context) ? 1 : 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: isMobile(context) ? 1.4 : 1.05,
                  children: [
                    _BookingActionCard(
                      title: 'Create New Booking',
                      icon: Icons.add_box,
                      onTap: () {
                        if (embedded) {
                          _showEmbeddedView(_BookingView.createBooking);
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateBookingPage(),
                          ),
                        );
                      },
                    ),
                    _BookingActionCard(
                      title: 'View Bookings',
                      icon: Icons.list_alt,
                      onTap: () {
                        if (embedded) {
                          _showEmbeddedView(_BookingView.viewBookings);
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ViewBookingsPage(),
                          ),
                        );
                      },
                    ),
                    _BookingActionCard(
                      title: 'Check Availability',
                      icon: Icons.event_available,
                      onTap: () {
                        if (embedded) {
                          _showEmbeddedView(_BookingView.checkAvailability);
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckAvailabilityPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmbeddedInnerView() {
    switch (_selectedView) {
      case _BookingView.menu:
        return _buildBookingContent(context, embedded: true);
      case _BookingView.createBooking:
        return Column(
          children: [
            _EmbeddedBookingHeader(
              title: 'Create New Booking',
              subtitle:
                  'Capture event details, select a hall, and proceed to payment.',
              onBack: _goBackToMenu,
            ),
            const SizedBox(height: 16),
            const Expanded(child: CreateBookingPage(embedded: true)),
          ],
        );
      case _BookingView.viewBookings:
        return ViewBookingsPage(embedded: true, onBack: _goBackToMenu);
      case _BookingView.checkAvailability:
        return Column(
          children: [
            _EmbeddedBookingHeader(
              title: 'Check Hall Availability',
              subtitle:
                  'Verify date availability before raising a booking request.',
              onBack: _goBackToMenu,
            ),
            const SizedBox(height: 16),
            const Expanded(child: CheckAvailabilityPage(embedded: true)),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: _buildEmbeddedInnerView(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0F8F82),
        title: Text("Booking"),
      ),
      drawer: isMobile(context)
          ? Drawer(
              child: SideBar(
                selectedSection: AppSection.bookings,
                onSectionSelected: (section) =>
                    openAppShellSection(context, section),
              ),
            )
          : null,
      body: BrandBackground(
        child: Row(
          children: [
            if (!isMobile(context))
              SideBar(
                selectedSection: AppSection.bookings,
                onSectionSelected: (section) =>
                    openAppShellSection(context, section),
              ),
            Expanded(child: _buildBookingContent(context, embedded: false)),
          ],
        ),
      ),
    );
  }
}

enum _BookingView { menu, createBooking, viewBookings, checkAvailability }

class _EmbeddedBookingHeader extends StatelessWidget {
  const _EmbeddedBookingHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(17, 59, 52, 0.05),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF5FBF9),
              foregroundColor: const Color(0xFF0F8F82),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF124B45),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, height: 1.45),
                ),
              ],
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
