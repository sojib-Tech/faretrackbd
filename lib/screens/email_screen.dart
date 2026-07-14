import 'package:flutter/material.dart';
import '../services/email_service.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _sentEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email)) {
      _showSnackBar('সঠিক Email address দিন');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await EmailService.sendOtp(email);
      if (mounted) {
        setState(() {
          _isOtpSent = true;
          _sentEmail = email;
        });
        _showSnackBar('OTP পাঠানো হয়েছে', isError: false);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Email পাঠাতে সমস্যা হয়েছে: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      _showSnackBar('6-ডিজিটের OTP code দিন');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final valid = await EmailService.verifyOtp(_sentEmail!, otp);
      if (mounted) {
        if (valid) {
          _showSnackBar('Verified!', isError: false);
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              FocusScope.of(context).unfocus();
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          });
        } else {
          _showSnackBar('ভুল বা মেয়াদোত্তীর্ণ Code');
        }
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center),
        backgroundColor: isError ? Colors.red.shade800 : const Color(0xFF1D9E75),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text('Email Verification'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.email_outlined, color: Color(0xFF1D9E75), size: 80),
            const SizedBox(height: 24),
            const Text(
              'আপনার Email ঠিকানা দিন',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _isOtpSent
                  ? '$_sentEmail এ পাঠানো code টি দিন'
                  : 'আমরা একটি 6-ডিজিটের OTP পাঠাবো',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading && !_isOtpSent,
              decoration: InputDecoration(
                hintText: 'your@email.com',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              child: _isOtpSent
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextField(
                        controller: _otpController,
                        style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: '------',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 24, letterSpacing: 8),
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          counterText: '',
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_isOtpSent ? _verifyOtp : _sendOtp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isOtpSent ? 'Verify OTP' : 'Send OTP',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
