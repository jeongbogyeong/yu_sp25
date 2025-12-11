import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../service/notification/notification_definitions.dart';
import '../../service/notification/notification_service.dart';

// ✨ 테마 색상 정의 (MyPageScreen과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 긍정/강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색

// 알림 항목 데이터 모델
class NotificationItem {
  final int type;
  final String title;
  final String description;
  final String frequency;
  bool isEnabled;

  NotificationItem({
    required this.type,
    required this.title,
    required this.description,
    required this.frequency,
    this.isEnabled = true,
  });
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late SharedPreferences _prefs;

  // ✅ 로딩 상태 플래그 (초기값: true -> 로딩 중)
  bool _isLoading = true;

  // ✅ 알림 리스트 (로딩 후 채워짐)
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadSettings(); // 설정 불러오기 시작
  }

  // 🌱 계절 알림(type 6~9)인지 확인
  bool _isSeasonal(NotificationItem item) {
    return item.type >= 6 && item.type <= 9;
  }

  // ----------------------------------------------------
  // ✅ 1. SharedPreferences에서 설정 불러오기
  // ----------------------------------------------------
  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    List<NotificationItem> loadedItems = [];
    for (var def in notificationDefinitions) {
      final key = 'noti_${def.type}';

      bool isEnabled;
      if (def.type >= 6 && def.type <= 9) {
        // 🌱 계절 알림은 항상 ON, 사용자 설정 무시
        isEnabled = true;
      } else {
        // 저장된 값이 없으면 기본값(true) 사용
        isEnabled = _prefs.getBool(key) ?? true;
      }

      loadedItems.add(
        NotificationItem(
          type: def.type,
          title: def.title,
          description: def.description,
          frequency: def.frequency,
          isEnabled: isEnabled,
        ),
      );
    }

    // 로딩이 완료되면 상태 업데이트
    setState(() {
      _notifications = loadedItems;
      _isLoading = false; // 로딩 완료
    });
  }

  // ----------------------------------------------------
  // ✅ 2. SharedPreferences에 설정 저장하기
  //     (계절 알림은 저장/변경 안 함)
  // ----------------------------------------------------
  Future<void> _saveSetting(NotificationItem item, bool newValue) async {
    // 🌱 계절 알림은 사용자가 바꿀 수 없음 → 그냥 무시
    if (_isSeasonal(item)) return;

    final key = 'noti_${item.type}';
    await _prefs.setBool(key, newValue);
    debugPrint("SharedPreferences 저장 완료: $key = $newValue");

    // type으로 대응되는 NotificationDefinition 찾기
    final def = notificationDefinitions.firstWhere(
      (d) => d.type == item.type,
      orElse: () => notificationDefinitions[0],
    );

    if (newValue) {
      // ON 상태: 알림 예약
      NotificationService.scheduleNotificationByType(def);
    } else {
      // OFF 상태: 알림 취소
      await NotificationService.cancelNotification(item.type);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        title: const Text("알림 설정"),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: _secondaryColor,
        elevation: 0.0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "알림 유형을 선택하여 켜거나 끌 수 있습니다.\n(일부 시스템 알림은 항상 제공됩니다.)",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    color: Colors.white,
                    child: Column(
                      children: _notifications
                          .map((item) => _buildNotificationTile(item))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "현재 알림 설정: ${_notifications.where((e) => e.isEnabled).length} / ${_notifications.length}개 활성화",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ----------------------------------------------------
  // ✅ 3. 개별 알림 항목 위젯 (SwitchListTile)
  // ----------------------------------------------------
  Widget _buildNotificationTile(NotificationItem item) {
    final isSeasonal = _isSeasonal(item);

    // 🌱 계절 알림이면 항상 ON + 비활성화된 스위치
    if (isSeasonal) {
      return SwitchListTile(
        secondary: const Icon(Icons.notifications_active, color: _primaryColor),
        title: Text(
          item.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.description,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            Text(
              "주기: ${item.frequency} (필수 시스템 알림)",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        value: true, // 항상 ON
        onChanged: null, // 🔒 눌러도 안 바뀜
        activeColor: _primaryColor,
      );
    }

    // 🔓 일반 알림 (사용자가 켜고 끌 수 있음)
    return SwitchListTile(
      secondary: Icon(
        item.isEnabled ? Icons.notifications_active : Icons.notifications_off,
        color: item.isEnabled ? _primaryColor : Colors.grey,
      ),
      title: Text(
        item.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.description,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            "주기: ${item.frequency}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      value: item.isEnabled,
      onChanged: (bool newValue) {
        setState(() {
          item.isEnabled = newValue;
        });
        _saveSetting(item, newValue); // 변경 시 바로 저장 + 스케줄 조정
      },
      activeColor: _primaryColor,
    );
  }
}
