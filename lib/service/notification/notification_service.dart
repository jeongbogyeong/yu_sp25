import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'notification_definitions.dart';

// 알림 기능을 캡슐화한 서비스 클래스
class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  // ----------------------------------------------------
  // ✅ 1. 초기화 (앱 시작 시 단 한 번 호출)
  // ----------------------------------------------------
  static Future init() async {
    // 1. 시간대 데이터 초기화 (예약 알림을 위해 필수)
    tzdata.initializeTimeZones();
    // 사용자 위치의 현재 시간대를 설정 (한국 시간 기준)
    final location = tz.getLocation('Asia/Seoul');
    tz.setLocalLocation(location);

    // 2. 플랫폼별 설정
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS에서는 권한 요청이 필요합니다.
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 3. 알림 플러그인 초기화
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // 알림을 탭했을 때 실행될 로직 (예: 특정 화면으로 이동)
        debugPrint('Notification payload: ${response.payload}');
      },
    );

    //4 android 알림 권한 요청
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // 4. iOS/macOS 알림 권한 요청
    _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    //5.알림 스케쥴 등록
    final prefs = await SharedPreferences.getInstance();
    for (var def in notificationDefinitions) {
      final isEnabled = prefs.getBool('noti_${def.type}') ?? true;
      if (isEnabled) {
        // 기존 NotificationService의 스케줄 함수 재사용
        NotificationService.scheduleNotificationByType(def);
      }
    }
  }

  static void scheduleNotificationByType(NotificationDefinition def) {
    final id = def.type;
    final title = "SmartMoney 알림: ${def.title}";
    final body = def.description;

    switch (def.type) {
      case 0:
        scheduleDailyNotification(
          id: id,
          title: title,
          body: body,
          time: const TimeOfDay(hour: 22, minute: 00),
        );
        break;
      case 1:
        scheduleWeeklyNotification(
          id: id,
          title: title,
          body: body,
          day: Day.sunday,
        );
        break;
      case 2:
      case 4:
        scheduleMonthlyNotification(
          id: id,
          title: title,
          body: body,
          dayOfMonth: 1,
          time: const TimeOfDay(hour: 9, minute: 0),
        );
        break;
      case 3:
        scheduleDailyNotification(
          id: id,
          title: title,
          body: body,
          time: const TimeOfDay(hour: 8, minute: 0),
        );
        break;
      case 5:
        scheduleSpendingDelayNotification(id: id, title: title, body: body);
        break;
    }
  }

  // ----------------------------------------------------
  // ✅ 2. 알림 예약 (매일 특정 시간)
  // ----------------------------------------------------
  static Future scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time, // 예: TimeOfDay(hour: 22, minute: 0)
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // 만약 예약 시간이 현재 시간보다 이전이면, 다음 날로 설정
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel', // 채널 ID
          '일간 알림', // 채널 이름
          channelDescription: '매일 정기적으로 발생하는 알림',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 같은 시간에 반복
      payload: id.toString(),
    );
  }

  // ----------------------------------------------------
  // ✅ 3. 알림 예약 (매주 특정 요일)
  // ----------------------------------------------------
  static Future scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required Day day, // 예: Day.sunday
  }) async {
    // 다음 주 해당 요일의 0시 0분으로 예약
    tz.TZDateTime nextInstanceOfDay(Day day) {
      tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local);
      while (scheduledDate.weekday != day.value) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      return scheduledDate;
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      nextInstanceOfDay(day),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_channel',
          '주간 알림',
          channelDescription: '매주 정기적으로 발생하는 알림',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.dayOfWeekAndTime, // 매주 해당 요일 같은 시간에 반복
      payload: id.toString(),
    );
  }

  //✅ 4. 알림 예약 (매월 특정 날짜, 특정 시간)
  static Future scheduleMonthlyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfMonth, // 1부터 31 사이의 날짜 (예: 1일)
    required TimeOfDay time, // 예: TimeOfDay(hour: 8, minute: 0)
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    // 첫 번째 예약 시간을 다음 달 1일 또는 이번 달 1일(이미 지나지 않았다면)로 설정합니다.
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      dayOfMonth, // 1일
      time.hour,
      time.minute,
    );

    // 만약 현재 날짜/시간이 예약 시간과 같거나 이미 지났다면, 다음 달로 넘깁니다.
    if (scheduledDate.isBefore(now) ||
        (scheduledDate.month == now.month &&
            scheduledDate.day == now.day &&
            (scheduledDate.hour < now.hour ||
                (scheduledDate.hour == now.hour &&
                    scheduledDate.minute <= now.minute)))) {
      // 다음 달 1일로 설정
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month + 1,
        dayOfMonth,
        time.hour,
        time.minute,
      );
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'monthly_channel', // 채널 ID
          '월간 알림', // 채널 이름
          channelDescription: '매월 정기적으로 발생하는 알림',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // 매월 같은 날짜, 같은 시간에 반복하도록 설정합니다.
      payload: id.toString(),
    );
  }

  // ----------------------------------------------------
  // ✅ 5. 알림 취소 (id를 통해 취소)
  // ----------------------------------------------------
  static Future cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<PermissionStatus> requestNotificationPermissions() async {
    final status = await Permission.notification.request();
    return status;
  }

  /// ✅ 6. 소비 기록이 2일 이상 없을 때만 울리는 알림
  ///
  /// SharedPreferences에 저장된 마지막 소비 기록 날짜(`last_spending_input`)를 읽어서
  /// - 이미 2일 이상 지났으면: 지금 기준으로 몇 초 뒤에 바로 울리도록 예약
  /// - 아직 2일이 안 됐으면: 2일이 되는 시점의 아침 9시에 한 번 울리도록 예약
  static Future scheduleSpendingDelayNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lastInputStr = prefs.getString('last_spending_input');

    // 아직 한 번도 소비 기록을 안 한 사용자라면 굳이 알림 안 보냄
    if (lastInputStr == null) return;

    final lastInput = DateTime.tryParse(lastInputStr);
    if (lastInput == null) return;

    final now = tz.TZDateTime.now(tz.local);
    final diffDays = now.difference(lastInput).inDays;

    tz.TZDateTime scheduledDate;

    if (diffDays >= 2) {
      // 이미 2일 이상 안 썼으면, 바로(5초 후) 알림 한 번 울리기
      scheduledDate = now.add(const Duration(seconds: 5));
    } else {
      // 아직 2일 안 지났으면, 2일이 되는 시점의 아침 9시에 한 번 울리게
      final daysToWait = 2 - diffDays;
      final targetDate = now.add(Duration(days: daysToWait));

      scheduledDate = tz.TZDateTime(
        tz.local,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        9, // 아침 9시 (원하면 시간 바꿔도 됨)
        0,
      );
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'spending_delay_channel', // 채널 ID
          '소비 기록 지연 알림', // 채널 이름
          channelDescription: '2일 이상 소비 기록이 없을 때 알려주는 알림',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: id.toString(),
    );
  }
}
