import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✨ 테마 색상 정의 (다른 화면과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 긍정/강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색
const Color _expenseColor = Color(0xFFEF5350); // 지출/경고 (빨간색 계열)

// ✅ 비밀번호 재설정 화면
// ----------------------------------------------------
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();

  bool _isLoading = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // ✅ 비밀번호 변경 로직
  // ----------------------------------------------------
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.email == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('로그인 상태를 확인해주세요.')));
        }
        return;
      }

      final currentPassword = _currentPwController.text.trim();
      final newPassword = _newPwController.text.trim();

      // 1) 기존 비밀번호 확인 (재로그인)
      await _supabase.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );

      // 2) 비밀번호 변경
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')));
      Navigator.pop(context);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알 수 없는 오류가 발생했습니다. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ----------------------------------------------------
  // ✅ 비밀번호 재설정 이메일 발송 로직
  // ----------------------------------------------------
  Future<void> _sendResetEmail() async {
    final user = _supabase.auth.currentUser;

    if (user == null || user.email == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인 상태를 확인해주세요.')));
      }
      return;
    }

    try {
      await _supabase.auth.resetPasswordForEmail(user.email!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('비밀번호 재설정 링크를 ${user.email} 로 보냈습니다.\n메일함을 확인해주세요.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('메일 발송 중 오류가 발생했습니다: $e')));
      }
    }
  }

  // ----------------------------------------------------
  // ✅ UI 빌드
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor, // 배경색 적용
      appBar: AppBar(
        title: const Text('비밀번호 재설정'),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: _secondaryColor, // AppBar 배경색 적용
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "안전한 비밀번호 변경을 위해 현재 비밀번호가 필요합니다.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // 1. 현재 비밀번호 입력
              TextFormField(
                controller: _currentPwController,
                obscureText: true,
                decoration: _inputDecoration.copyWith(
                  labelText: '현재 비밀번호',
                  prefixIcon:
                  const Icon(Icons.lock_outline_rounded, color: Colors.grey),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '현재 비밀번호를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 2. 새 비밀번호 입력
              TextFormField(
                controller: _newPwController,
                obscureText: true,
                decoration: _inputDecoration.copyWith(
                  labelText: '새 비밀번호',
                  helperText: '8자 이상 권장',
                  prefixIcon:
                  const Icon(Icons.vpn_key_rounded, color: Colors.grey),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '새 비밀번호를 입력해주세요.';
                  }
                  if (value.trim().length < 8) {
                    return '비밀번호는 8자리 이상이어야 합니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. 새 비밀번호 확인
              TextFormField(
                controller: _confirmPwController,
                obscureText: true,
                decoration: _inputDecoration.copyWith(
                  labelText: '새 비밀번호 확인',
                  prefixIcon:
                  const Icon(Icons.check_circle_outline, color: Colors.grey),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '새 비밀번호를 한 번 더 입력해주세요.';
                  }
                  if (value.trim() != _newPwController.text.trim()) {
                    return '비밀번호가 일치하지 않습니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // ✅ 비밀번호 변경 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    '비밀번호 변경',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 🔹 현재 비밀번호 모를 때: 이메일로 재설정 링크 보내기
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _sendResetEmail,
                  child: Text(
                    '현재 비밀번호를 모르겠어요 (비밀번호 찾기)',
                    style: TextStyle(
                      color: Colors.blueGrey.shade400, // 색상 조정
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 입력 필드 디자인 정의
  // ----------------------------------------------------
  InputDecoration get _inputDecoration => InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _primaryColor, width: 2.0), // 포커스 시 강조
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _expenseColor, width: 2.0),
    ),
    contentPadding:
    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    labelStyle: const TextStyle(color: Colors.black54),
    hintStyle: const TextStyle(color: Colors.grey),
    fillColor: Colors.white,
    filled: true,
  );
}