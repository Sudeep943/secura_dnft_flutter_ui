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
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);

  final username = TextEditingController();
  final password = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Widget _buildDialogHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: _brandColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  InputDecoration _buildDialogInputDecoration({
    required String labelText,
    String? errorText,
    String? counterText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: _brandTextColor),
      errorText: errorText,
      counterText: counterText,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _brandColor.withValues(alpha: 0.45)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _brandColor, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.redAccent, width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  ButtonStyle _filledDialogButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _brandColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  ButtonStyle _textDialogButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: _brandColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  void _submitIfReady() {
    if (!loading) {
      login();
    }
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
            titlePadding: EdgeInsets.zero,
            title: _buildDialogHeader('OTP Verification'),
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
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    final otp = otpController.text.trim();
                    if (otp.length != 4) {
                      setDialogState(() {
                        validationMessage = 'Enter a valid 4 digit OTP.';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(otp);
                  },
                  cursorColor: _brandColor,
                  decoration: _buildDialogInputDecoration(
                    labelText: '4 digit OTP',
                    errorText: validationMessage,
                    counterText: '',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                style: _textDialogButtonStyle(),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: _filledDialogButtonStyle(),
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
            titlePadding: EdgeInsets.zero,
            title: _buildDialogHeader('Update Password'),
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
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    final newPassword = passwordController.text.trim();
                    if (newPassword.isEmpty) {
                      setDialogState(() {
                        validationMessage = 'Password is required.';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(newPassword);
                  },
                  cursorColor: _brandColor,
                  decoration: _buildDialogInputDecoration(
                    labelText: 'New Password',
                    errorText: validationMessage,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                style: _textDialogButtonStyle(),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: _filledDialogButtonStyle(),
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
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_passwordFocusNode);
                          },
                          decoration: const InputDecoration(
                            labelText: "Username / Phone",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextField(
                          controller: password,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submitIfReady(),
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandColor,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: loading ? null : _submitIfReady,
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
