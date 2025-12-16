// lib/pages/auth/register_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:leavesync/services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0038),
              Color(0xFF190052),
              Color(0xFF2A006C),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button → Go to Welcome Page
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/welcome');
                    },
                  ),
                  // Enetech Logo
                  Image.asset(
                    'lib/assets/images/enetech_logo.png',
                    height: 50,
                  ),
                ],
              ),

              // TEXT "ENETECH" DI BAWAH LOGO
              const SizedBox(height: 0),
              const Align(
                alignment: Alignment.topRight,
                child: Text(
                  "ENETECH",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "REGISTER",
                  style: TextStyle(
                    fontSize: 34,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "New User",
                  style: TextStyle(
                    fontSize: 32,
                    color: Color(0xFFD21312),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              _buildTextField(
                hintText: "Username",
                icon: Icons.person_outline,
                controller: usernameController,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                hintText: "Email Address",
                icon: Icons.email_outlined,
                controller: emailController,
              ),
              const SizedBox(height: 20),

              _buildPasswordField(
                hintText: "Password",
                obscure: _obscurePassword,
                toggle: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                controller: passwordController,
              ),
              const SizedBox(height: 20),

              _buildPasswordField(
                hintText: "Confirm Password",
                obscure: _obscureConfirmPassword,
                toggle: () {
                  setState(() =>
                      _obscureConfirmPassword = !_obscureConfirmPassword);
                },
                controller: confirmPasswordController,
              ),

              const SizedBox(height: 40),

              // Register Button
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFF0B0B),
                      Color(0xFF1B0765),
                    ],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: validateForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    "REGISTER",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text(
                      "Sign In",
                      style: TextStyle(
                        color: Color(0xFFD21312),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    {
      required String hintText,
      required IconData icon,
      required TextEditingController controller,
    }
  ) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white70),
            border: InputBorder.none,
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white70),
            contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      );
    }

  Widget _buildPasswordField(
    {
      required String hintText,
      required bool obscure,
      required VoidCallback toggle,
      required TextEditingController controller,
    }
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
            ),
            onPressed: toggle,
          ),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white70),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
  
    void validateForm() {
      String username = usernameController.text.trim();
      String email = emailController.text.trim();
      String password = passwordController.text;
      String confirmPassword = confirmPasswordController.text;

      if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
        showFancyDialog("Something Went Wrong", "Please fill in all fields.");
        return;
      }

      // Email regex simple dan efektif
      bool emailValid = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email);
      if (!emailValid) {
        showFancyDialog("Something Went Wrong", "Please enter a valid email address.");
        return;
      }

      if (password.length < 8) {
        showFancyDialog("Something Went Wrong", "Password must be at least 8 characters.");
        return;
      }

      if (password != confirmPassword) {
        showFancyDialog("Something Went Wrong", "Passwords do not match.");
        return;
      }

      registerUser();
    }

    Future<void> registerUser() async {
  final url = ApiService.register();

  final response = await http.post(
    url,
    headers: {
      "Accept": "application/json",
    },
    body: {
      "username": usernameController.text.trim(),
      "email": emailController.text.trim(),
      "password": passwordController.text,
    },
  );

  if (!mounted) return;

  if (response.statusCode == 201) {
    showFancyDialog("Success", "Registration successful!", onOk: () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  } else {
    final body = jsonDecode(response.body);
    showFancyDialog("Error", body['message'] ?? "Registration failed.");
  }
}

void showFancyDialog(String title, String message, {VoidCallback? onOk}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Dismiss",
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (context, anim1, anim2) => Container(),
    transitionBuilder: (context, anim1, anim2, child) {
      return Transform.scale(
        scale: Curves.easeOutBack.transform(anim1.value),
        child: Opacity(
          opacity: anim1.value,
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withOpacity(0.4)),
              ),

              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.5),
                      width: 1.4,
                    ),
                  ),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent.withOpacity(0.2),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          decoration: TextDecoration.none,
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          decoration: TextDecoration.none,
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 25),

                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(); // tutup dialog dulu
                          if (onOk != null) onOk();   // kemudian redirect
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF0B0B), Color(0xFF1B0765)],
                            ),
                          ),
                          child: const Text(
                            "OK",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


}
