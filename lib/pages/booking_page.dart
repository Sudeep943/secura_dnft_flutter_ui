import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
import '../services/api_service.dart';
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

  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);
  static const Color _accentColor = Color(0xFFE0DA84);
  int _upcomingBookingsCount = 0;
  bool _upcomingBookingsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUpcomingBookingsCount();
  }

  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  Future<void> _loadUpcomingBookingsCount() async {
    final response = await ApiService.getUpcomingHallBookings();
    if (!mounted) {
      return;
    }

    final bookingList = response?['bookingList'];
    final messageCode = response?['messageCode']?.toString() ?? '';
    final count = messageCode.startsWith('SUCC') && bookingList is List
        ? bookingList.length
        : 0;

    setState(() {
      _upcomingBookingsCount = count;
      _upcomingBookingsLoading = false;
    });
  }

  Widget _buildUpcomingBookingsSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Bookings',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _upcomingBookingsLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  '$_upcomingBookingsCount ${_upcomingBookingsCount == 1 ? 'Booking' : 'Bookings'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ],
      ),
    );
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

  List<_BookingActionItem> _bookingActions(bool embedded) {
    return [
      _BookingActionItem(
        title: 'Create New Booking',
        subtitle:
            'Reserve a hall, set the event details, and continue to payment.',
        icon: Icons.add_box_rounded,
        accentColor: _accentColor,
        onTap: () {
          if (embedded) {
            _showEmbeddedView(_BookingView.createBooking);
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateBookingPage()),
          );
        },
      ),
      _BookingActionItem(
        title: 'View Bookings',
        subtitle:
            'Track approvals, payment references, and booking status updates.',
        icon: Icons.list_alt_rounded,
        accentColor: const Color(0xFFDDF4F1),
        onTap: () {
          if (embedded) {
            _showEmbeddedView(_BookingView.viewBookings);
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ViewBookingsPage()),
          );
        },
      ),
      _BookingActionItem(
        title: 'Check Availability',
        subtitle: 'Verify hall schedules before raising a new booking request.',
        icon: Icons.event_available_rounded,
        accentColor: const Color(0xFFE9F7EE),
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
    ];
  }

  Widget _buildBookingContent(BuildContext context, {required bool embedded}) {
    final bookingActions = _bookingActions(embedded);

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1080),
          child: Container(
            padding: EdgeInsets.all(isMobile(context) ? 18 : 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _brandColor, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(18, 75, 69, 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F8F82), Color(0xFF15766A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 16,
                    spacing: 16,
                    children: [
                      SizedBox(
                        width: isMobile(context) ? double.infinity : 520,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Bookings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Choose one of the booking actions below and manage reservations with a single, focused workflow.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildUpcomingBookingsSummary(),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  crossAxisCount: isMobile(context) ? 1 : 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: isMobile(context) ? 1.45 : 0.96,
                  children: bookingActions
                      .map((action) => _BookingActionCard(action: action))
                      .toList(),
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
  const _BookingActionCard({required this.action});

  final _BookingActionItem action;

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
        onTap: widget.action.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: hovered ? const Color(0xFFF8F4C6) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hovered
                  ? const Color(0xFFE0DA84)
                  : const Color(0xFFE6EFED),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(17, 59, 52, 0.07),
                blurRadius: hovered ? 24 : 16,
                offset: Offset(0, hovered ? 12 : 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.action.accentColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      widget.action.icon,
                      size: 32,
                      color: const Color(0xFF0F8F82),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.action.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: _BookingPageState._brandTextColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.action.subtitle,
                style: const TextStyle(
                  color: Colors.black54,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Text(
                    'Open',
                    style: TextStyle(
                      color: Color(0xFF0F8F82),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF0F8F82),
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingActionItem {
  const _BookingActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
}
