import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class EmailService {
  static const String _serviceId = 'service_8th642j';
  static const String _templateId = 'template_pep8k2q';
  static const String _publicKey = 'rWTk-ehZN4-iEHYXM';

  static final Map<String, _OtpData> _memoryOtps = {};

  static Future<String> sendOtp(String email) async {
    final cleanEmail = email.trim();

    if (cleanEmail.length < 5 || !cleanEmail.contains('@')) {
      throw Exception("Invalid email reached EmailService: '$cleanEmail'");
    }

    final generatedOtp = (100000 + Random().nextInt(900000)).toString();
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': cleanEmail,
            'passcode': generatedOtp,
            'otp_code': generatedOtp,
            'otp': generatedOtp,
            'code': generatedOtp,
            'time': '15 minutes',
          },
        }),
      );

      if (response.statusCode == 200) {
        _memoryOtps[cleanEmail] = _OtpData(
          generatedOtp,
          DateTime.now().millisecondsSinceEpoch + 5 * 60 * 1000,
        );
        return generatedOtp;
      } else {
        throw Exception("EmailJS Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> verifyOtp(String email, String userInputCode) async {
    final memo = _memoryOtps[email.trim()];
    if (memo == null) {
      print('[VerifyOTP] No memory OTP found for $email');
      return false;
    }
    if (DateTime.now().millisecondsSinceEpoch > memo.expiresAt) {
      print('[VerifyOTP] Memory OTP expired');
      _memoryOtps.remove(email);
      return false;
    }
    if (memo.code == userInputCode.trim()) {
      print('[VerifyOTP] OTP matched!');
      _memoryOtps.remove(email);
      return true;
    }
    print('[VerifyOTP] OTP mismatch');
    return false;
  }

  static void clearMemoryOtp(String email) {
    _memoryOtps.remove(email.trim());
  }
}

class _OtpData {
  final String code;
  final int expiresAt;
  _OtpData(this.code, this.expiresAt);
}
