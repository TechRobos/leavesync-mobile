// lib/pages/profile/leave_history_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leavesync/services/api_service.dart';

class LeaveHistoryPage extends StatefulWidget {
  const LeaveHistoryPage({super.key});

  @override
  State<LeaveHistoryPage> createState() => _LeaveHistoryPageState();
}

class LeaveRecord {
  final int id;
  final String type;
  final String status;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;

  LeaveRecord({
    required this.id,
    required this.type,
    required this.status,
    required this.reason,
    required this.startDate,
    required this.endDate,
  });

  int get daysTaken => endDate.difference(startDate).inDays + 1;

  factory LeaveRecord.fromJson(Map<String, dynamic> json) {
    return LeaveRecord(
      id: json['id'],
      type: json['leave_type'],
      status: json['status'],
      reason: json['reason'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
    );
  }
}

class _LeaveHistoryPageState extends State<LeaveHistoryPage> {

  // results after search/filter
  List<LeaveRecord> allRecords = [];  
  List<LeaveRecord> results = [];

  // --- Filters / Search ---
  final TextEditingController reasonSearchController = TextEditingController();
  String selectedType = "All";
  String selectedStatus = "All";
  DateTime? filterStartDate;
  DateTime? filterEndDate;
  
  final DateFormat displayFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    loadLeavesFromAPI();
  }

 Future<void> loadLeavesFromAPI() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? userId = prefs.getInt("userId");

  if (userId == null) {
    print("User ID not found in SharedPreferences");
    return;
  }

  final uri = ApiService.leaveSearch({
    "user_id": userId.toString(),
  });

  final response = await http.get(uri);

   if (!mounted) return;

  if (response.statusCode == 200) {
    final jsonBody = jsonDecode(response.body);
    final List<dynamic> data = jsonBody['data'];

    if (!mounted) return;

    setState(() {
      allRecords = data.map((e) => LeaveRecord.fromJson(e)).toList();
      results = List.from(allRecords);
    });
  }
}



  Widget tableHeader(String text) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget tableCell(String text) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
      ),
    ),
  );
}

void previewAllRecordsTable() {
  if (results.isEmpty) return;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1B45),
        title: const Text(
          'All Leave Records',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2E2A61),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: DataTable(
                border: TableBorder.all(
                  color: Colors.white24,
                  width: 0.7,
                ),
                headingRowHeight: 45,
                dataRowHeight: 45,
                headingRowColor: WidgetStateColor.resolveWith(
                  (states) => const Color(0xFF3B3870),
                ),
                dataRowColor: WidgetStateColor.resolveWith(
                  (states) => const Color(0xFF1B1A3C),
                ),
                columnSpacing: 28,
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                dataTextStyle: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
                columns: const [
                  DataColumn(label: Text('Start Date')),
                  DataColumn(label: Text('End Date')),
                  DataColumn(label: Text('Days')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Reason')),
                  DataColumn(label: Text('Status')),
                ],
                rows: results.map((record) {
                  return DataRow(
                    cells: [
                      DataCell(Text(displayFormat.format(record.startDate))),
                      DataCell(Text(displayFormat.format(record.endDate))),
                      DataCell(Text(record.daysTaken.toString())),
                      DataCell(Text(record.type)),
                      DataCell(Text(record.reason)),
                      DataCell(_statusChip(record.status)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    // main UI
    return Scaffold(
      backgroundColor: const Color(0xFF090A29),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // HEADER: My Profile + Logo (Same Row)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Leave History",
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

              const SizedBox(height: 24),

              // --- search by reason ---
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2A61),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: reasonSearchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Search by reason',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => submitSearch(),
                      ),
                    ),
                    IconButton(
                      onPressed: submitSearch,
                      icon: const Icon(Icons.search, color: Colors.white),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- filter card ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2A61),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filter by', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // leave type
                        Expanded(child: _buildDropdown('Leave Type', selectedType, _typeOptions(), (val) {
                          setState(() {
                            selectedType = val ?? 'All';
                          });
                        })),
                        const SizedBox(width: 12),
                        // status
                        Expanded(child: _buildDropdown('Status', selectedStatus, _statusOptions(), (val) {
                          setState(() {
                            selectedStatus = val ?? 'All';
                          });
                        })),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePickerBox('Start Date', filterStartDate, pickFilterStartDate),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDatePickerBox('End Date', filterEndDate, pickFilterEndDate),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                Color(0xFF4B4B4B), // kelabu cerah
                                Color(0xFF1F1F1F), // kelabu gelap
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              onPressed: resetFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,       // penting
                                shadowColor: Colors.transparent,           // buang shadow default
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12), // sama dengan container
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                'Reset',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                Color(0xFF00C853),
                                Color(0xFF00E676),
                                Color(0xFF1B5E20),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: submitSearch,
                              child: const Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- results table card ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2A61),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Table header
                    if (results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text('No records to display', style: TextStyle(color: Colors.white70)),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateColor.resolveWith((states) => Colors.transparent),
                          columnSpacing: 12,
                          columns: const [
                            DataColumn(label: Text('Start Date', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('End Date', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Days', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Type', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Reason', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Status', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Preview', style: TextStyle(color: Colors.white))),
                          ],
                          rows: results.map((r) {
                            return DataRow(
                              cells: [
                                DataCell(Text(displayFormat.format(r.startDate), style: const TextStyle(color: Colors.white))),
                                DataCell(Text(displayFormat.format(r.endDate), style: const TextStyle(color: Colors.white))),
                                DataCell(Text(r.daysTaken.toString(), style: const TextStyle(color: Colors.white))),
                                DataCell(Text(r.type, style: const TextStyle(color: Colors.white))),
                                DataCell(Text(r.reason, style: const TextStyle(color: Colors.white))),
                                DataCell(_statusChip(r.status)),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => previewRecord(r),
                                      icon: const Icon(Icons.remove_red_eye, color: Colors.white),
                                    ),
                                  ],
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // action buttons preview / export
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                              Color(0xFF1CD8D2),   // teal cerah
                              Color(0xFF14626E),   // teal gelap
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: results.isNotEmpty ? previewAllRecordsTable : null,
                            icon: const Icon(Icons.remove_red_eye, color: Colors.white),
                            label: const Text(
                              'View Details',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                          ),
                        ),

                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF4D4D), Color(0xFFB30000)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: results.isNotEmpty ? exportResultsToPdf : null,
                            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                            label: const Text(
                              'Export to PDF',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,        // penting
                              shadowColor: Colors.transparent,             // buang shadow default
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),   // sama macam Container
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // maintain saiz
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
       bottomNavigationBar: navBar(),
    );
  }

  // --- Helpers: Pickers ---
  Future<void> pickFilterStartDate() async {
    final DateTime now = DateTime.now();
    DateTime? selected = await showDatePicker(
      context: context,
      initialDate: filterStartDate ?? now,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      builder: (context, child) {
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
      },
    );

    if (selected != null) {
      setState(() => filterStartDate = selected);
    }
  }

  Future<void> pickFilterEndDate() async {
    final DateTime now = DateTime.now();
    DateTime initial = filterEndDate ?? filterStartDate ?? now;
    DateTime first = filterStartDate ?? DateTime(2024);

    DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2035),
      builder: (context, child) {
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
      },
    );

    if (selected != null) {
      setState(() => filterEndDate = selected);
    }
  }

  // --- Reset filters & search ---
  void resetFilters() {
    setState(() {
      reasonSearchController.clear();
      selectedType = "All";
      selectedStatus = "All";
      filterStartDate = null;
      filterEndDate = null;
      results = List.from(allRecords);
    });
  }

  // --- Submit filters/search ---
Future<void> submitSearch() async {
  bool confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF2E2A61),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Confirm Search',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'Proceed to search with selected options?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Yes', style: TextStyle(color: Colors.greenAccent)),
        ),
      ],
    ),
  ) ?? false;

  if (!confirmed) return;

  try {
    Map<String, String> queryParams = {};

    if (reasonSearchController.text.isNotEmpty) {
      queryParams['reason'] = reasonSearchController.text;
    }

    if (selectedType != "All") {
      queryParams['leave_type'] = selectedType;
    }

    if (selectedStatus != "All") {
      queryParams['status'] = selectedStatus;
    }

    if (filterStartDate != null) {
      queryParams['start_date'] = filterStartDate!.toIso8601String();
    }

    if (filterEndDate != null) {
      queryParams['end_date'] = filterEndDate!.toIso8601String();
    }

    final uri = ApiService.leaveSearch(queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final List<dynamic> data = jsonBody['data'];

      if (!mounted) return;

      setState(() {
        results = data.map((e) => LeaveRecord.fromJson(e)).toList();
      });
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text("Failed to fetch data: $e"),
      ),
    );
  }
}

  // --- Preview detail of a record ---
  void previewRecord(LeaveRecord record) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E2A61),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Leave Details',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Start Date", displayFormat.format(record.startDate)),
              _detailRow("End Date", displayFormat.format(record.endDate)),
              _detailRow("Days", record.daysTaken.toString()),
              _detailRow("Type", record.type),
              _detailRow("Reason", record.reason),
              _detailRow("Status", record.status),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }


  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white70)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  // --- Export current results to PDF ---
  Future<void> exportResultsToPdf() async {
    if (results.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2E2A61),
          title: const Text('No data', style: TextStyle(color: Colors.white)),
          content: const Text('There is no result to export.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Colors.white))),
          ],
        ),
      );
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(20),
        ),
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Header(level: 0, child: pw.Text('Leave History', style: pw.TextStyle(fontSize: 22))),
            pw.SizedBox(height: 10),
            pw.Text('Exported: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: ['Start Date', 'End Date', 'Days', 'Type', 'Reason', 'Status'],
              data: results.map((r) {
                return [
                  displayFormat.format(r.startDate),
                  displayFormat.format(r.endDate),
                  r.daysTaken.toString(),
                  r.type,
                  r.reason,
                  r.status,
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    Uint8List bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'leave_history_${DateTime.now().toIso8601String()}.pdf');
  }

  // helper: date picker box UI
  Widget _buildDatePickerBox(
      String label, DateTime? selectedDate, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1A3C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  selectedDate != null
                      ? displayFormat.format(selectedDate)
                      : "Select Date",
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const Icon(Icons.calendar_month, color: Colors.white70),
          ],
        ),
      ),
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
      currentIndex: 2, // history tab index
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
            Navigator.pushReplacementNamed(context, '/apply');
            break;
          case 2:
            break; // already here
          case 3:
            Navigator.pushReplacementNamed(context, '/profile');
            break;
        }
      },
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
  );
}

void previewAllRecords() {
  if (results.isEmpty) return;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF2E2A61),
        title: const Text(
          'All Leave Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              children: results.map((record) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1A3C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      infoRow('Start Date', displayFormat.format(record.startDate)),
                      infoRow('End Date', displayFormat.format(record.endDate)),
                      infoRow('Days Taken', record.daysTaken.toString()),
                      infoRow('Type', record.type),
                      infoRow('Reason', record.reason),
                      infoRow('Status', record.status),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}


  // helper: status chip with colors
  Widget _statusChip(String status) {
    Color bg;
    switch (status.toLowerCase()) {
      case 'approved':
        bg = Colors.green;
        break;
      case 'pending':
        bg = Colors.orange;
        break;
      case 'rejected':
        bg = Colors.red;
        break;
      default:
        bg = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: const TextStyle(color: Colors.white)),
    );
  }

  // helper: dropdown builder
  Widget _buildDropdown(String label, String current, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFF1B1A3C), borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              isExpanded: true,
              dropdownColor: const Color(0xFF2E2A61),
              style: const TextStyle(color: Colors.white),
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(color: Colors.white),))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  List<String> _typeOptions() => ['All', 'Annual', 'Emergency', 'Medical', 'Maternity', 'Paternity'];

  List<String> _statusOptions() => ['All', 'Pending', 'Approved', 'Rejected'];
}
