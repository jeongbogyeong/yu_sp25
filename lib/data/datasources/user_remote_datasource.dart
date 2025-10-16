import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_datasource.dart';
import '../../api/api.dart';



class UserRemoteDataSource implements UserDataSource{
  @override
  Future<bool> registerUserToMySQL(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse(API.signup),
        body: userData,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // PHP 파일이 반환하는 "success": true/false를 확인
        return jsonResponse['success'] == true;
      } else {
        final uri = Uri.parse(API.signup);
        print('Requesting URL: $uri');
        print('Server error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // 네트워크 통신 오류
      print('Network error: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchUserFromMySQL(String uid) async {
    try {
      final response = await http.post(
        Uri.parse(API.fetchUser),
        body: {'user_id': uid}, // UID를 서버에 전달
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          // 서버에서 받은 사용자 데이터를 반환
          return jsonResponse['user_data'] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> loginUserToMySQL(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(API.login),
        body: {
          'user_email': email,
          // PHP에서 md5를 사용하고 있으므로, 여기서도 비밀번호를 해시하여 보내는 것이 안전합니다.
          // 하지만 보안을 위해 실제 앱에서는 SHA-256이나 bcrypt를 사용하는 것이 좋습니다.
          // 여기서는 PHP 코드와의 일관성을 위해 일단 해시 없이 평문을 보낸다고 가정합니다.
          'user_password': password,
        },
      );

      // 🚀 디버깅 로그 추가
      print('Login Raw Server Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          // 로그인 성공 시 사용자 데이터 맵 반환
          return jsonResponse['user_data'] as Map<String, dynamic>?;
        }
        // 서버에서 인증 실패 (비밀번호 불일치 등)
        final String errorMessage = jsonResponse['message'] ?? "이메일 또는 비밀번호가 틀렸습니다.";
        throw Exception("Login Failed: $errorMessage");

      } else {
        // HTTP 상태 코드 오류
        throw Exception("Server connection error: HTTP ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> getSpendingFromMySQL(int uid) async {
    try {
      final response = await http.post(
        Uri.parse(API.getSpending),
        body: {'user_id': uid.toString()}, // ⚠️ 문자열 변환 필요
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['spending_data'];

          // List<dynamic> → List<Map<String, dynamic>>로 캐스팅
          return data.map((item) => item as Map<String, dynamic>).toList();
        }
      }

      return null;
    } catch (e) {
      print('Error GET spending_data: $e');
      return null;
    }
  }


  Future<bool> fetchSpendingFromMySQL(Map<String, dynamic> userData)async {
    try {
      final response = await http.post(
        Uri.parse(API.fetchSpending),
        body: userData,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // PHP 파일이 반환하는 "success": true/false를 확인
        return jsonResponse['success'] == true;
      } else {
        final uri = Uri.parse(API.signup);
        print('Requesting URL: $uri');
        print('Server error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // 네트워크 통신 오류
      print('Network error: $e');
      return false;
    }
  }
}
