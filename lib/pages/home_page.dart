import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/dashboard_card.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  Map<String, dynamic>? dashboardData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  fetchDashboardData() async {
    final data = await ApiService.getDashboardData();
    setState(() {
      dashboardData = data;
      loading = false;
    });
  }

  String formatHallBookings(List<dynamic>? bookings) {
    if (bookings == null || bookings.isEmpty) return "0";
    return bookings
        .map((b) {
          DateTime date = DateTime.parse(b['bkngEvntDt']);
          String formattedDate =
              "${date.day.toString().padLeft(2, '0')}-${_monthAbbr(date.month)}-${date.year}";
          return "${formattedDate} - ${b['bkngHallId']} - ${b['bkngFltNo']}";
        })
        .join('\n');
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0F8F82),
        title: Text("Dashboard"),

        actions: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Center(child: Text("Pending Dues: ₹1250")),
          ),

          Padding(
            padding: EdgeInsets.all(10),
            child: Center(child: Text("Worklist: 10")),
          ),

          SizedBox(width: 20),
        ],
      ),

      drawer: isMobile(context) ? Drawer(child: SideBar()) : null,

      body: Row(
        children: [
          if (!isMobile(context)) SideBar(),

          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),

              child: loading
                  ? Center(child: CircularProgressIndicator())
                  : GridView.count(
                      crossAxisCount: isMobile(context) ? 2 : 4,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      // reduce card height by changing aspect ratio (width : height)
                      childAspectRatio: isMobile(context) ? 1.2 : 1.8,

                      children: [
                        DashboardCard(
                          "Payments",
                          dashboardData?['payments'] ?? "₹0",
                        ),
                        DashboardCard(
                          "Hall Booking",
                          formatHallBookings(
                            dashboardData?['upcomingBookings'],
                          ),
                        ),
                        DashboardCard(
                          "Skill Classes",
                          dashboardData?['skillClasses'] ?? "0",
                        ),
                        DashboardCard(
                          "Worklist",
                          dashboardData?['pendingWorklistCount']?.toString() ??
                              "0",
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
