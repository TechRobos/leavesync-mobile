// lib/pages/leave/apply_leave_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leavesync/services/api_service.dart';

class ApplyLeavePage extends StatefulWidget {
  const ApplyLeavePage({super.key});

  @override
  State<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends State<ApplyLeavePage> {
  String? selectedType = "Annual";
  int? leaveRemaining;
  DateTime? startDate;
  DateTime? endDate;
  int totalLeaveDays = 0;
  String? dateError;

  final TextEditingController reasonController = TextEditingController();

  void resetForm() {
    setState(() {
      selectedType = "Annual";
      startDate = null;
      endDate = null;
      totalLeaveDays = 0;
      reasonController.clear();
      dateError = null;
    });
  }

  Future<void> pickStartDate() async {
    DateTime? selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: datePickerTheme,
    );

    if (selected != null) {
      setState(() {
        startDate = selected;
      });
      calculateDays();
    }
  }

  Future<void> pickEndDate() async {
    DateTime? selected = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime(2025),
      lastDate: DateTime(2030),
      builder: datePickerTheme,
    );

    if (selected != null) {
      setState(() {
        endDate = selected;
      });
      calculateDays();
    }
  }

  Widget datePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          onPrimary: Colors.white,
          surface: Color(0xFF2E2A61),
          onSurface: Colors.white,
        ),
      ),
      child: child!,
    );
  }

  void calculateDays() {
    if (startDate != null && endDate != null) {
      if (endDate!.isBefore(startDate!)) {
        setState(() {
          dateError = "End date cannot be earlier than start date.";
          totalLeaveDays = 0;
        });
      } else {
        setState(() {
          dateError = null;
          totalLeaveDays = endDate!.difference(startDate!).inDays + 1;
        });
      }
    }
  }

  void submitLeave() {
    if (reasonController.text.trim().isEmpty ||
        startDate == null ||
        endDate == null ||
        dateError != null) {
      return errorPopup("Please fill in all fields correctly before submitting.");
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E2A61),
          title: const Text("Confirm Submit", style: TextStyle(color: Colors.white)),
          content: const Text(
            "Are you sure want to submit?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await handleSubmit();
              },
              child: const Text(
                "Submit",
                style: TextStyle(color: Colors.greenAccent),
              ),
            ),
          ],
        );
      },
    );

    if (leaveRemaining == null) {
      return errorPopup("Please wait... Loading leave balance");
    }

    if (totalLeaveDays > leaveRemaining!) {
      return errorPopup("Not enough leave balance!");
    }
  }

  Future<int?> getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt("userId");
  }

  Future<void> handleSubmit() async {

    final int? userId = await getCurrentUserId();

    if (userId == null) {
      return errorPopup("User ID not found!");
    }

  try {
    final leaveData = {
      "user_id": userId,   
      "leave_type": selectedType!.toLowerCase(),
      "start_date": DateFormat("yyyy-MM-dd").format(startDate!),
      "end_date": DateFormat("yyyy-MM-dd").format(endDate!),
      "reason": reasonController.text.trim(),
      "status": "pending",
      "days_requested": totalLeaveDays,
      "days_taken": totalLeaveDays,
    };

    await saveToDatabase(leaveData);

    setState(() {
      leaveRemaining = (leaveRemaining ?? 0) - totalLeaveDays;

      if (leaveRemaining! < 0) {
        leaveRemaining = 0;
      }
    });

    successPopup();
    resetForm();

  } catch (e) {
    errorPopup("Failed to submit. Please try again.");
  }
}


  void errorPopup(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E2A61),
          title: const Text("Form Incomplete",
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void successPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B0765),
          title: const Text(
            "Success",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Your leave request has been submitted.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveToDatabase(Map<String, dynamic> data) async {
    final url = ApiService.submitLeave();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode !=201) {
      throw Exception("Failed to submit leave");
    }
    
  }

  String prettyDate(DateTime d) {
    return DateFormat("d MMMM yyyy").format(d);
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat("dd/MM/yyyy");

    return Scaffold(
      backgroundColor: const Color(0xFF090A29),
      bottomNavigationBar: navBar(),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Apply Leave",
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

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2A61),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    leaveRemaining == null
                    ? "Leave Remaining: Loading..."
                    : "Leave Remaining: $leaveRemaining Days",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2A61),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label("Leave Type"),
                    const SizedBox(height: 10),

                    dropdownLeaveType(),

                    const SizedBox(height: 20),

                    label("Dates"),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: dateBox(
                            title: "Start Date",
                            value: startDate == null
                                ? "Select Date"
                                : format.format(startDate!),
                            onTap: pickStartDate,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: dateBox(
                            title: "End Date",
                            value: endDate == null
                                ? "Select Date"
                                : format.format(endDate!),
                            onTap: pickEndDate,
                          ),
                        ),
                      ],
                    ),

                    if (dateError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          dateError!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 12),
                        ),
                      ),

                    const SizedBox(height: 20),

                    label("Total Leave Days"),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1A3C),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "$totalLeaveDays",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2A61),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label("Reason"),
                    const SizedBox(height: 10),

                    TextField(
                      controller: reasonController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputStyle("State your reason briefly..."),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: submitButton(
                            "Reset",
                            const LinearGradient(
                              colors: [
                                Color(0xFF555555),
                                Color(0xFF2E2E2E),
                              ],
                            ),
                            resetForm,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: submitButton(
                            "Submit",
                            const LinearGradient(
                              colors: [
                                Color(0xFF00C853),
                                Color(0xFF00E676),
                                Color(0xFF1B5E20),
                              ],
                            ),
                            submitLeave,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchLeaveBalance();
  }

  Future<void> fetchLeaveBalance() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  final int? userId = prefs.getInt("userId");

  if (userId == null) {
    print("Tiada userId disimpan!");
    return;
  }

  try {
    final url = ApiService.leaveBalance(userId);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        leaveRemaining = data["quota"];
      });
    } else {
      print("Error: ${response.body}");
    }
  } catch (e) {
    print("Exception: $e");
  }
}

  Widget dateBox({required String title, required String value, required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1A3C),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Icon(Icons.calendar_month, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget dropdownLeaveType() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1A3C),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedType,
          dropdownColor: const Color(0xFF2E2A61),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          isExpanded: true,
          items: [
            "Annual",
            "Emergency",
            "Medical",
            "Maternity",
            "Paternity",
          ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => selectedType = v),
        ),
      ),
    );
  }

  Widget submitButton(String text, LinearGradient gradient, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  InputDecoration inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1B1A3C),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget navBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2E2A61),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: 1,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/history');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Apply Leave"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Leave History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
