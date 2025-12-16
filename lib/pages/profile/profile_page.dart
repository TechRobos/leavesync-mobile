// lib/pages/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leavesync/pages/dashboard/dashboard_page.dart';
import 'package:leavesync/pages/leave/apply_leave_page.dart';
import 'package:leavesync/pages/leave/leave_history_page.dart';
import 'package:leavesync/services/api_service.dart';
import 'package:leavesync/config/api_config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController nameController = TextEditingController(text: "Rahman");
  TextEditingController emailController =
      TextEditingController(text: "rahman@enetech.com.my");
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  bool showPassword = false;
  bool showConfirmPassword = false;

  File? _profileImage;
  String? networkImageUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  setState(() {
    nameController.text = prefs.getString("userName") ?? "Unknown";
    emailController.text = prefs.getString("userEmail") ?? "Unknown";

    final photo = prefs.getString("userPhoto");
    if (photo != null && photo.isNotEmpty) {
      networkImageUrl = "${ApiConfig.storageUrl}/$photo";
    } else {
      networkImageUrl = null;
    }
  });
}

  Future<void> _pickProfileImage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

void _updateProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  var request = http.MultipartRequest(
    'POST',
    ApiService.updateProfile(),
  );

  request.headers.addAll({
    "Authorization": "Bearer $token",
    "Accept": "application/json",
  });

  request.fields['name'] = nameController.text;
  request.fields['email'] = emailController.text;

  if (passwordController.text.isNotEmpty &&
    passwordController.text != confirmPasswordController.text) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Password & confirm password tidak sama")),
  );
  return;
}

  if (_profileImage != null) {
    request.files.add(await http.MultipartFile.fromPath(
      'photo',
      _profileImage!.path,
    ));
  }

  if (passwordController.text.isNotEmpty) {
    request.fields['password'] = passwordController.text;
  }

  if (confirmPasswordController.text.isNotEmpty) {
    request.fields['password_confirmation'] = confirmPasswordController.text;
  }

  final response = await request.send();
  final responseBody = await response.stream.bytesToString();

  print("Update response: $responseBody");

  if (response.statusCode == 200) {
    final res = jsonDecode(responseBody);

    if (!mounted) return;

    // Simpan profile baru dalam SharedPreferences
    prefs.setString("userName", res["user"]["name"]);
    prefs.setString("userEmail", res["user"]["email"]);

    if (res["user"]["photo"] != null) {
      prefs.setString("userPhoto", res["user"]["photo"]);
    }

    // Refresh UI selepas update
    setState(() {
  nameController.text = res["user"]["name"];
  emailController.text = res["user"]["email"];

  _profileImage = null; // buang local preview

  if (res["user"]["photo"] != null &&
      res["user"]["photo"].toString().isNotEmpty) {
    networkImageUrl = "${ApiConfig.storageUrl}/${res["user"]["photo"]}";
  }
  // ❗ JANGAN else → biar gambar lama kekal
});
    // Tunjuk dialog success
    if (!mounted) return;
    _showSuccessDialog();
    
  } else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Update failed: ${response.statusCode}")),
  );
}
  if (!mounted) return;
}

Future<void> fetchUserFromAPI() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");

  final response = await http.get(
    ApiService.profile(),
    headers: {"Authorization": "Bearer $token"},
  );

  if (!mounted) return;

  if (response.statusCode == 200) {
    final res = jsonDecode(response.body);

    if (!mounted) return;

    await prefs.setString("userName", res["user"]["name"]);
    await prefs.setString("userEmail", res["user"]["email"]);
   
    if (res["user"]["photo"] != null && res["user"]["photo"].toString().isNotEmpty) {
      await prefs.setString("userPhoto", res["user"]["photo"]);
    }
    // Refresh UI with fetched data
    if (!mounted) return;

    setState(() {
      nameController.text = res["user"]["name"];
      emailController.text = res["user"]["email"];
      networkImageUrl = "${ApiConfig.storageUrl}/${res["user"]["photo"]}";
    });
  }

  print("API response body: ${response.body}");
}


  void _showConfirmUpdateDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Update"),
          content: const Text("Are you sure you want to update your profile?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateProfile();
              },
              child: const Text("Confirm"),
            )
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Success"),
          content: const Text("Profile updated successfully!"),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        );
      },
    );
  }

  int _currentIndex = 3;

  void _onNavTapped(int index) {
    if (index == _currentIndex) return;

    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const DashboardPage()));
        break;
      case 1:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const ApplyLeavePage()));
        break;
      case 2:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const LeaveHistoryPage()));
        break;
      case 3:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02001D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "My Profile",
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
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2A61),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: CircleAvatar(
                        radius: 45,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (networkImageUrl != null
                                ? NetworkImage(networkImageUrl!)
                                : const AssetImage(
                                    'assets/images/profile.png',
                                  ) as ImageProvider),
                        child: _profileImage == null && networkImageUrl == null
                            ? const Icon(Icons.camera_alt,
                                size: 40, color: Colors.white)
                            : null,
                      ),
                    ),

                    const SizedBox(height: 8),

                    ElevatedButton(
                      onPressed: _pickProfileImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black26,
                      ),
                      child: const Text(
                        "Change Profile Picture",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _buildField(Icons.person, "Username", nameController),
                    const SizedBox(height: 15),
                    _buildField(Icons.email, "Email", emailController),
                    const SizedBox(height: 15),
                    _buildNewPasswordField(),
                    const SizedBox(height: 15),
                    _buildConfirmPasswordField(),

                    const SizedBox(height: 25),

                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6A11CB),
                            Color(0xFF2575FC),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: _showConfirmUpdateDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: const Text(
                          "Update Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF3B30),
                            Color(0xFF8B0000),
                            Color(0xFF000000),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/welcome');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: const Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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

  Widget _buildField(
      IconData icon, String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        prefixIcon: Icon(icon, color: Colors.black),
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildNewPasswordField() {
    return TextField(
      obscureText: !showPassword,
      controller: passwordController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        prefixIcon: const Icon(Icons.lock, color: Colors.black),
        labelText: "New Password",
        labelStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              showPassword = !showPassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextField(
      obscureText: !showConfirmPassword,
      controller: confirmPasswordController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        prefixIcon: const Icon(Icons.lock, color: Colors.black),
        labelText: "Confirm Password",
        labelStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            showConfirmPassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              showConfirmPassword = !showConfirmPassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
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
        currentIndex: _currentIndex,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        onTap: _onNavTapped,
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
}
