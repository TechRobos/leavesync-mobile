// lib/pages/dashboard/dashboard_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:leavesync/services/api_service.dart';


// ============================================================================
// DATA SOURCE UNTUK SYNCFUSION CALENDAR
// ============================================================================
class LeaveDataSource extends CalendarDataSource {
  LeaveDataSource(List<Appointment> source) {
    appointments = source;
  }
}

// ============================================================================
// MAIN PAGE
// ============================================================================
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

  List<Appointment> leaveAppointments = [];
  Map<DateTime, List<String>> holidays = {};

  List<TimeRegion> holidayRegions = [];

  @override
  void initState() {
    super.initState();
    loadToken();
  }

  // ---------------------------------------------------------------------------
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    if (token != null) {
      fetchAllData();
    }
  }

  // ---------------------------------------------------------------------------
  Future<void> fetchAllData() async {
    try {
      await Future.wait([
        fetchUserData(),
        fetchLeaveSummary(),
        fetchHolidays(),
        fetchLeaveEvents(),
      ]);
    } catch (e) {
      print("ERROR fetchAllData: $e");
    }
  }

  // ---------------------------------------------------------------------------
  Future<void> fetchUserData() async {
    try {

      final response = await http.get(
        ApiService.profile(),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

setState(() {
  userName = data['data']['name'] ?? "";
  userEmail = data['data']['email'] ?? "";
  memberSince = data['data']['created_at'] ?? "";
});

      }
    } catch (e) {
      print("ERROR fetchUserData: $e");
    }
  }

  // ---------------------------------------------------------------------------
  Future<void> fetchLeaveSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt("userId");
      if (userId == null) return;

      final response = await http.get(
  ApiService.leaveSummary(userId),
  headers: {
    "Accept": "application/json",
    "Authorization": "Bearer $token",
  },
);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          pending = (data['pending'] ?? 0);
          approved = (data['approved'] ?? 0);
          rejected = (data['rejected'] ?? 0);
          usedQuota = (data['used_quota'] ?? 0);
          totalQuota = (data['total_quota'] ?? 10);
        });
      }
    } catch (e) {
      print("ERROR fetchLeaveSummary: $e");
    }
  }

  // ---------------------------------------------------------------------------
  Future<void> fetchHolidays() async {
    try {
      final response = await http.get(
  ApiService.holidays(),
  headers: {
    "Accept": "application/json",
  },
);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List raw = jsonDecode(response.body);

        Map<DateTime, List<String>> temp = {};
        List<TimeRegion> regions = [];

        for (var item in raw) {
          DateTime date = DateTime.parse(item['date']);
          DateTime key = DateTime(date.year, date.month, date.day);

          String holidayName = (item['name'] ?? "");

          temp.putIfAbsent(key, () => []);
          temp[key]!.add(holidayName);

          regions.add(
            TimeRegion(
              startTime: key,
              endTime: key.add(const Duration(days: 1)),
              enablePointerInteraction: false,
              color: Colors.red.withOpacity(0.25),
              text: holidayName,
              textStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10),
            ),
          );
        }

        setState(() {
          holidays = temp;
          holidayRegions = regions;
        });
      }
    } catch (e) {
      print("ERROR fetchHolidays: $e");
    }
  }

  // ---------------------------------------------------------------------------
  Future<void> fetchLeaveEvents() async {
    try {
      final response = await http.get(
  ApiService.leaveEvents(),
  headers: {
    "Accept": "application/json",
    "Authorization": "Bearer $token",
  },
);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        List<Appointment> temp = [];

        for (var item in data) {
          DateTime start = DateTime.parse(item['start_date']);
          DateTime end = DateTime.parse(item['end_date']);

          Color color;
          switch ((item["status"] ?? "").toString().toLowerCase()) {
            case "approved":
              color = Colors.green;
              break;
            case "pending":
              color = Colors.orange;
              break;
            case "rejected":
              color = Colors.red;
              break;
            default:
              color = Colors.grey;
          }

          temp.add(
            Appointment(
              startTime: start,
              endTime: end.add(const Duration(days: 1)),
              subject: "${item['user_name']} (${item['type']})",
              color: color,
              isAllDay: true, // Penting untuk multi-day bar
            ),
          );
        }

        setState(() => leaveAppointments = temp);
      }
    } catch (e) {
      print("ERROR fetchLeaveEvents: $e");
    }
  }

  // ===========================================================================
  // CUSTOM MONTH VIEW BUILDER — PAPAR BAR + TEXT
  // ===========================================================================
  Widget monthCellBuilder(BuildContext context, MonthCellDetails details) {
  final DateTime date = details.date;
  final List<Appointment> apps =
      details.appointments.cast<Appointment>();

  const int maxVisible = 2; // <<< HAD APPOINTMENT
  final visibleApps = apps.take(maxVisible).toList();
  final hiddenCount = apps.length - visibleApps.length;

  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white24),
    ),
    padding: const EdgeInsets.all(4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TARIKH
        Text(
          date.day.toString(),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 2),

        // APPOINTMENT YANG MUAT SAHAJA
        for (var appt in visibleApps)
          GestureDetector(
            onTap: () => showLeavePopup(appt),
            child: Container(
              width: double.infinity,
              height: 18,
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: appt.color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                appt.subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis, // <<< POTONG ELOK
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // JIKA ADA YANG TERSEMBUNYI
        if (hiddenCount > 0)
          GestureDetector(
            onTap: () => showDayPopup(date, apps),
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                "+$hiddenCount more",
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

void showLeavePopup(Appointment appt) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF2E2A61),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        "Leave Detail",
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          infoRow("Name", appt.subject),
          infoRow(
            "From",
            formatDatePretty(appt.startTime.toIso8601String()),
          ),
          infoRow(
            "To",
            formatDatePretty(
              appt.endTime.subtract(const Duration(days: 1)).toIso8601String(),
            ),
          ),
          infoRow("Status", statusFromColor(appt.color)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Close",
            style: TextStyle(color: Colors.redAccent),
          ),
        )
      ],
    ),
  );
}

Widget infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            "$label:",
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

String statusFromColor(Color c) {
  if (c == Colors.green) return "Approved";
  if (c == Colors.orange) return "Pending";
  if (c == Colors.red) return "Rejected";
  return "Unknown";
}

void showDayPopup(DateTime date, List<Appointment> apps) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2E2A61),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Leaves on ${formatDatePretty(date.toIso8601String())}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          for (var appt in apps)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: appt.color,
                radius: 6,
              ),
              title: Text(
                appt.subject,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                showLeavePopup(appt);
              },
            ),
        ],
      ),
    ),
  );
}


  // ===========================================================================
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

              // USER INFO CARD
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
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // STATUS COUNTERS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  statusBox("pending", pending, Colors.yellow),
                  statusBox("approved", approved, Colors.green),
                  statusBox("rejected", rejected, Colors.redAccent),
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
                                ),
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
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ========================
              //       CALENDAR
              // ========================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2A61),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SizedBox(
                  height: 420,
                  child: SfCalendar(
                    view: CalendarView.month,
                    dataSource: LeaveDataSource(leaveAppointments),

                    todayHighlightColor: Colors.green,

                    selectionDecoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),

                    monthCellBuilder: monthCellBuilder,

                    specialRegions: holidayRegions,

                    monthViewSettings: const MonthViewSettings(
                      appointmentDisplayMode:
                          MonthAppointmentDisplayMode.none, // Disable dot
                      showTrailingAndLeadingDates: true,
                    ),

                    headerStyle: const CalendarHeaderStyle(
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    viewHeaderStyle: const ViewHeaderStyle(
                      dayTextStyle: TextStyle(color: Colors.white),
                    ),

                    cellBorderColor: Colors.white24,
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
                icon: Icon(Icons.dashboard), label: "Dashboard"),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month), label: "Apply Leave"),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: "Leave History"),
            BottomNavigationBarItem(
                icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
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
            "$count",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // ===========================================================================
  void _onNavTap(int index) {
    if (!mounted) return;

    setState(() => _selectedIndex = index);

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

  // ===========================================================================
  String formatDatePretty(String iso) {
    try {
      if (iso == "" || iso == "null") return "-";
      final date = DateTime.parse(iso).toLocal();
      const monthNames = [
        "",
        "January", "February", "March",
        "April", "May", "June",
        "July", "August", "September",
        "October", "November", "December",
      ];
      return "${date.day} ${monthNames[date.month]} ${date.year}";
    } catch (_) {
      return "-";
    }
  }
}
