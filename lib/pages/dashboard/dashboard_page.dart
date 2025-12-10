// lib/pages/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? token;

  String userName = "";
  String userEmail = "";
  String memberSince = "";

  int pending = 0;
  int approved = 0;
  int rejected = 0;

  int totalQuota = 10;
  int usedQuota = 0;

  int get balanceQuota => totalQuota - usedQuota;

  int _selectedIndex = 0;

  // CALENDAR VARIABLES
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    loadToken();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    if (token != null) {
      fetchUserData();
      fetchLeaveSummary();
    } else {
      print("Token tiada! Anda belum login.");
    }
  }

  Future<void> fetchUserData() async {
    final url = Uri.parse("http://192.168.0.55:8000/api/profile");

    final response = await http.get(
      url,
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        userName = data['name'] ?? "";
        userEmail = data['email'] ?? "";
        memberSince = data['created_at'] ?? "";
      });
    } else {
      print("Gagal fetch user data: ${response.body}");
    }
  }

  Future<void> fetchLeaveSummary() async {
    final url = Uri.parse("http://192.168.0.55:8000/api/leave-request");

    final response = await http.get(
      url,
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        pending = data['pending'] ?? 0;
        approved = data['approved'] ?? 0;
        rejected = data['rejected'] ?? 0;
        usedQuota = data['used_quota'] ?? 0;
        totalQuota = data['total_quota'] ?? 12;
      });
    } else {
      print("Gagal fetch summary: ${response.body}");
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/apply');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  Widget statusBox(String title, int count, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2A61),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  String formatDatePretty(String isoString) {
  try {
    final date = DateTime.parse(isoString).toLocal();

    const monthNames = [
      "", // dummy index 0
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return "${date.day} ${monthNames[date.month]} ${date.year}";
  } catch (e) {
    return isoString;
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A29),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Dashboard",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Column(
                    children: [
                      Image.asset(
                        'lib/assets/images/enetech_logo.png',
                        height: 50,
                      ),
                      const Text(
                        "ENETECH",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 20),

              // USER CARD
              Card(
                color: const Color(0xFF2E2A61),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.blue.shade900),
                  ),
                  title: Text(
                    userName.isEmpty ? "Loading..." : userName,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  subtitle: Text(
                    "$userEmail\nMember since: ${formatDatePretty(memberSince)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // STATUS COUNTERS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  statusBox("Pending", pending, Colors.yellow),
                  statusBox("Approved", approved, Colors.green),
                  statusBox("Rejected", rejected, Colors.redAccent),
                ],
              ),

              const SizedBox(height: 25),

              // PIE CHART
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2A61),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Leave Quota Usage",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 50,
                              sections: [
                                PieChartSectionData(
                                  color: Colors.blue,
                                  value: usedQuota.toDouble(),
                                  showTitle: false,
                                  radius: 40,
                                ),
                                PieChartSectionData(
                                  color: Colors.teal,
                                  value: balanceQuota.toDouble(),
                                  showTitle: false,
                                  radius: 40,
                                )
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "$usedQuota/$totalQuota",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const Text(
                                "Used",
                                style: TextStyle(color: Colors.white70),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // CALENDAR
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2A61),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) =>
                      isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  headerStyle: const HeaderStyle(
                    titleTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    formatButtonVisible: true,
                    formatButtonShowsNext: false,
                    formatButtonTextStyle: TextStyle(color: Colors.white),
                    formatButtonDecoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    leftChevronIcon:
                        Icon(Icons.chevron_left, color: Colors.white),
                    rightChevronIcon:
                        Icon(Icons.chevron_right, color: Colors.white),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekendStyle: TextStyle(color: Colors.white),
                    weekdayStyle: TextStyle(color: Colors.white),
                  ),
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: TextStyle(color: Colors.white),
                    defaultTextStyle: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2E2A61),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavTap,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: "Apply Leave",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: "Leave History",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
