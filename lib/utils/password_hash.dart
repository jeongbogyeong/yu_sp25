import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHash {
  static const int _saltBytes = 8;

  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(_saltBytes, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hash(String password, String salt) {
    final bytes = utf8.encode('$salt::$password');
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  static bool verify(String password, String stored) {
    // Stored format: salt:<hex>
    final idx = stored.indexOf(':');
    if (idx <= 0) return false;
    final salt = stored.substring(0, idx);
    final expected = hash(password, salt);
    return expected == stored;
  }
}


