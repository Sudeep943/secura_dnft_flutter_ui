import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../widgets/brand_artwork.dart';
import 'app_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _showMessageDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showOtpDialog(String message) async {
    final otpController = TextEditingController();
    String? validationMessage;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('OTP Verification'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    labelText: '4 digit OTP',
                    border: const OutlineInputBorder(),
                    errorText: validationMessage,
                    counterText: '',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final otp = otpController.text.trim();
                  if (otp.length != 4) {
                    setDialogState(() {
                      validationMessage = 'Enter a valid 4 digit OTP.';
                    });
                    return;
                  }

                  Navigator.of(dialogContext).pop(otp);
                },
                child: const Text('Verify OTP'),
              ),
            ],
          ),
        );
      },
    );

    otpController.dispose();
    return result;
  }

  Future<String?> _showPasswordUpdateDialog(String message) async {
    final passwordController = TextEditingController();
    String? validationMessage;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Update Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  autofocus: true,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    errorText: validationMessage,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final newPassword = passwordController.text.trim();
                  if (newPassword.isEmpty) {
                    setDialogState(() {
                      validationMessage = 'Password is required.';
                    });
                    return;
                  }

                  Navigator.of(dialogContext).pop(newPassword);
                },
                child: const Text('Update Password'),
              ),
            ],
          ),
        );
      },
    );

    passwordController.dispose();
    return result;
  }

  Future<void> _completeLogin(String fallbackProfileId) async {
    await ApiService.fetchAndStoreProfile(
      profileId: ApiService.currentUserId ?? fallbackProfileId,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AppShell(initialSection: AppSection.dashboard),
      ),
    );
  }

  Future<void> _handleOtpChallenge({
    required String loginMessage,
    required String userName,
    required String currentPassword,
  }) async {
    final otp = await _showOtpDialog(loginMessage);
    if (otp == null || otp.isEmpty) {
      return;
    }

    setState(() => loading = true);

    Map<String, dynamic>? response;
    try {
      response = await ApiService.login(
        username: userName,
        password: currentPassword,
        otp: otp,
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }

    final message = response?['message']?.toString() ?? 'Unable to verify OTP.';
    final messageCode = response?['messageCode']?.toString() ?? '';

    if (response == null) {
      await _showMessageDialog(title: 'Error', message: message);
      return;
    }

    if (messageCode.startsWith('SUCC')) {
      await _completeLogin(userName);
      return;
    }

    if (messageCode == 'ERR_MESSAGE_30') {
      final newPassword = await _showPasswordUpdateDialog(message);
      if (newPassword == null || newPassword.isEmpty) {
        return;
      }

      final updateResponse = await ApiService.updatePassword(
        profileId: ApiService.currentUserId ?? userName,
        newPassword: newPassword,
        otpVerified: true,
      );
      final updateMessage =
          updateResponse?['message']?.toString() ??
          'Unable to update password.';
      final updateCode = updateResponse?['messageCode']?.toString() ?? '';

      if (updateCode.startsWith('SUCC')) {
        password.text = newPassword;
        await _showMessageDialog(title: 'Success', message: updateMessage);
      } else {
        await _showMessageDialog(title: 'Error', message: updateMessage);
      }
      return;
    }

    await _showMessageDialog(title: 'Error', message: message);
  }

  Future<void> login() async {
    final trimmedUsername = username.text.trim();
    final trimmedPassword = password.text.trim();

    if (trimmedUsername.isEmpty || trimmedPassword.isEmpty) {
      await _showMessageDialog(
        title: 'Error',
        message: 'Username and password are required.',
      );
      return;
    }

    setState(() => loading = true);

    Map<String, dynamic>? response;
    try {
      response = await ApiService.login(
        username: trimmedUsername,
        password: trimmedPassword,
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }

    final message =
        response?['message']?.toString() ?? 'Unable to complete login.';
    final messageCode = response?['messageCode']?.toString() ?? '';

    if (response == null) {
      await _showMessageDialog(title: 'Error', message: message);
      return;
    }

    if (messageCode.startsWith('SUCC')) {
      await _completeLogin(trimmedUsername);
      return;
    }

    if (messageCode == 'ERR_MESSAGE_29') {
      await _handleOtpChallenge(
        loginMessage: message,
        userName: trimmedUsername,
        currentPassword: trimmedPassword,
      );
      return;
    }

    await _showMessageDialog(title: 'Error', message: message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF7FBFA),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 64,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BrandLogo(width: 520),
                const SizedBox(height: 28),
                Center(
                  child: Container(
                    width: 400,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 15),
                      ],
                    ),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F8F82),
                          ),
                        ),

                        const SizedBox(height: 30),

                        TextField(
                          controller: username,
                          decoration: const InputDecoration(
                            labelText: "Username / Phone",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextField(
                          controller: password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F8F82),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: loading ? null : login,
                            child: loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text("Login"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
