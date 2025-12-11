import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartmoney/screens/viewmodels/TransactionViewModel.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:intl/intl.dart';

import 'notification_definitions.dart';

// 알림 기능을 캡슐화한 서비스 클래스
class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static const int salaryIncomeReminderId = 100;
  static const int planNotDoneReminderId = 101;

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

    // 4. android 알림 권한 요청
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // 5. iOS/macOS 알림 권한 요청
    _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // 6. 알림 스케쥴 등록
    final prefs = await SharedPreferences.getInstance();
    for (var def in notificationDefinitions) {
      final isEnabled = prefs.getBool('noti_${def.type}') ?? true;
      if (isEnabled) {
        NotificationService.scheduleNotificationByType(def);
      }
    }
  }

  // ----------------------------------------------------
  // ✅ 알림 정의(type)에 따라 스케줄링
  // ----------------------------------------------------
  static void scheduleNotificationByType(
    NotificationDefinition def, {
    TransactionViewModel? txVm,
    double? dailyBudget, // 🔥 하루 예산(있으면 type 3 알림에 사용)
  }) {
    final id = def.type;
    final title = "NudgeGap 알림: ${def.title}";

    // 기본 description
    String body = def.description;

    // 🔥 type 0: 오늘 지출 요약 → TransactionViewModel 있으면 실제 오늘 총 지출 금액으로 body 생성
    if (def.type == 0 && txVm != null) {
      final total = txVm.getTodayTotalSpending();
      body = "오늘 총 지출 금액은 ${total.toStringAsFixed(0)}원이에요.";
    }

    // 🔥 type 3: 오늘의 예산 확인 → 하루 예산(dailyBudget) 값이 넘어오면 그걸로 body 생성
    if (def.type == 3 && dailyBudget != null) {
      body = "오늘 사용 가능한 예산은 ${dailyBudget.toStringAsFixed(0)}원이에요.";
    }

    switch (def.type) {
      case 0:
        // 매일 22:00에 오늘 지출 요약 알림
        scheduleDailyNotification(
          id: id,
          title: title,
          body: body,
          time: const TimeOfDay(hour: 22, minute: 0),
        );
        break;

      case 1:
        // 매주 일요일 주간 요약
        scheduleWeeklyNotification(
          id: id,
          title: title,
          body: body,
          day: Day.sunday,
        );
        break;

      case 2:
      case 4:
        // 매월 1일 월간/예산 관련 알림
        scheduleMonthlyNotification(
          id: id,
          title: title,
          body: body,
          dayOfMonth: 1,
          time: const TimeOfDay(hour: 9, minute: 0),
        );
        break;

      case 3:
        // 매일 아침 8시 (예: 동기부여 메시지)
        scheduleDailyNotification(
          id: id,
          title: title,
          body: body,
          time: const TimeOfDay(hour: 8, minute: 0),
        );
        break;

      case 5:
        // 소비 기록 2일 지연 알림
        scheduleSpendingDelayNotification(id: id, title: title, body: body);
        break;

      // 🌱 6: 여름 생활비 (6월 1일 9시)
      case 6:
        scheduleYearlyNotification(
          id: id,
          title: title,
          body: body,
          month: 6,
          day: 1,
          time: const TimeOfDay(hour: 9, minute: 0),
        );
        break;

      // ❄️ 7: 겨울 난방비 (12월 1일 9시)
      case 7:
        scheduleYearlyNotification(
          id: id,
          title: title,
          body: body,
          month: 12,
          day: 1,
          time: const TimeOfDay(hour: 9, minute: 0),
        );
        break;

      // 🍃 8: 환절기 병원비 (3월 1일 9시)
      case 8:
        scheduleYearlyNotification(
          id: id,
          title: title,
          body: body,
          month: 3,
          day: 1,
          time: const TimeOfDay(hour: 9, minute: 0),
        );
        break;

      // 🍂 9: 환절기 병원비 (9월 1일 9시)
      case 9:
        scheduleYearlyNotification(
          id: id,
          title: title,
          body: body,
          month: 9,
          day: 1,
          time: const TimeOfDay(hour: 9, minute: 0),
        );
        break;

      // 🌨 10: 연말정산 시즌 알림 (매년 1월 5일)
      case 10:
        scheduleYearlyNotification(
          id: id,
          title: title,
          body: body,
          month: 1,
          day: 5,
          time: const TimeOfDay(hour: 9, minute: 0),
        );
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

  // ----------------------------------------------------
  // ✅ 4. 알림 예약 (매월 특정 날짜, 특정 시간) - 1회성
  // ----------------------------------------------------
  static Future scheduleMonthlyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfMonth, // 1부터 31 사이의 날짜 (예: 1일)
    required TimeOfDay time, // 예: TimeOfDay(hour: 8, minute: 0)
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      dayOfMonth,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now) ||
        (scheduledDate.month == now.month &&
            scheduledDate.day == now.day &&
            (scheduledDate.hour < now.hour ||
                (scheduledDate.hour == now.hour &&
                    scheduledDate.minute <= now.minute)))) {
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
      payload: id.toString(),
    );
  }

  // ----------------------------------------------------
  // ✅ 4-1. 알림 예약 (매년 특정 월/일, 특정 시간)
  // ----------------------------------------------------
  static Future scheduleYearlyNotification({
    required int id,
    required String title,
    required String body,
    required int month, // 3, 6, 9, 12 등
    required int day, // 보통 1일
    required TimeOfDay time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      month,
      day,
      time.hour,
      time.minute,
    );

    // 이미 지났으면 내년으로
    if (scheduledDate.isBefore(now)) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year + 1,
        month,
        day,
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
          'yearly_channel', // 채널 ID
          '계절 알림', // 채널 이름
          channelDescription: '계절 변화에 맞춰 보내는 알림',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // 매년 같은 월/일/시간에 반복
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
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

  /// ✅ 오늘 지출이 하루 예산을 초과했는지 체크하고,
  ///    이미 오늘 한 번 울렸으면 다시 안 울리게 막는 메서드
  static Future<void> checkDailyOverBudgetAndNotify({
    required double todayTotal,
    required double todayBudget,
  }) async {
    // 예산이 0 이하이면 의미 없음
    if (todayBudget <= 0) return;

    // 예산을 아직 안 넘었으면 알림 X
    if (todayTotal <= todayBudget) {
      debugPrint(
        '[NotificationService] todayTotal=$todayTotal, '
        'todayBudget=$todayBudget → 아직 예산 미초과',
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final flagKey = 'over_budget_notified_$todayKey';

    // 이미 오늘 한 번 알림 보냈으면 재발송 X
    final alreadyNotified = prefs.getBool(flagKey) ?? false;
    if (alreadyNotified) {
      debugPrint(
        '[NotificationService] 오늘($todayKey) 예산 초과 알림 이미 발송됨. 재발송 안 함.',
      );
      return;
    }

    final f = NumberFormat('#,###');
    final over = todayTotal - todayBudget;

    final title = 'NudgeGap 알림: 오늘 예산을 초과했어요';
    final body =
        '오늘 사용 예산 ${f.format(todayBudget)}원을 '
        '${f.format(over)}원 초과했어요. 카테고리를 한 번 점검해 볼까요?';

    await _notifications.show(
      999, // 일일 예산 초과 전용 ID
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_over_budget_channel',
          '일일 예산 초과 알림',
          channelDescription: '하루 사용 예산을 넘겼을 때 보내는 알림',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'daily_over_budget',
    );

    // 오늘은 이미 알림 보냈다는 표시 남겨두기
    await prefs.setBool(flagKey, true);

    debugPrint(
      '[NotificationService] 예산 초과 알림 발송 완료. todayTotal=$todayTotal, todayBudget=$todayBudget',
    );
  }

  /// ✅ 6. 소비 기록이 2일 이상 없을 때만 울리는 알림
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
        9, // 아침 9시
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

  /// ✅ 월급날 : "오늘 받은 월급, 급여 소득으로 기록하기" 알림
  static Future<void> scheduleSalaryIncomeReminder({
    required int salaryDay,
  }) async {
    // 혹시 이전에 잡혀 있던 같은 알림 있으면 지우고
    await cancelNotification(salaryIncomeReminderId);

    final now = tz.TZDateTime.now(tz.local);
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    // 1~31 범위, 그달 최대 일수 안에서만 사용
    int safeDay = salaryDay;
    if (safeDay < 1) safeDay = 1;
    if (safeDay > daysInMonth) safeDay = daysInMonth;

    await scheduleMonthlyNotification(
      id: salaryIncomeReminderId,
      title: 'NudgeGap 알림: 월급이 들어왔어요',
      body: '오늘 받은 월급을 급여 소득으로 기록해 볼까요?',
      dayOfMonth: safeDay,
      time: const TimeOfDay(hour: 9, minute: 0), // 아침 9시
    );
  }

  /// ✅ 월급 이후 : 이번 달 소비 계획을 아직 안 세웠다면 한 번 울리는 알림
  static Future<void> schedulePlanNotDoneReminder({
    required int salaryDay,
  }) async {
    // 이전에 잡힌 알림 있으면 먼저 취소
    await cancelNotification(planNotDoneReminderId);

    final now = tz.TZDateTime.now(tz.local);
    int year = now.year;
    int month = now.month;

    int daysInMonth = DateUtils.getDaysInMonth(year, month);

    // 이번 달 기준으로 안전한 월급 날짜 계산
    int safeSalaryDay = salaryDay;
    if (safeSalaryDay < 1) safeSalaryDay = 1;
    if (safeSalaryDay > daysInMonth) safeSalaryDay = daysInMonth;

    // 기본은 "월급 다음날 오전 9시"
    int targetDay = safeSalaryDay + 1;
    if (targetDay > daysInMonth) {
      // 월말(30/31) + 1이면 다음 달 1일로 보냄
      month += 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
      daysInMonth = DateUtils.getDaysInMonth(year, month);
      targetDay = 1;
    }

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      year,
      month,
      targetDay,
      9,
      0,
    );

    // 혹시 계산된 시간이 이미 지났으면, "다음 달 월급 다음날"로 다시 계산
    if (scheduledDate.isBefore(now)) {
      month = now.month + 1;
      year = now.year;
      if (month > 12) {
        month = 1;
        year += 1;
      }
      daysInMonth = DateUtils.getDaysInMonth(year, month);

      safeSalaryDay = salaryDay;
      if (safeSalaryDay < 1) safeSalaryDay = 1;
      if (safeSalaryDay > daysInMonth) safeSalaryDay = daysInMonth;

      targetDay = safeSalaryDay + 1;
      if (targetDay > daysInMonth) {
        targetDay = 1;
        month += 1;
        if (month > 12) {
          month = 1;
          year += 1;
        }
      }

      scheduledDate = tz.TZDateTime(tz.local, year, month, targetDay, 9, 0);
    }

    // 이 알림이 담당하는 (연,월)에 대해 소비 계획이 이미 세워졌으면 스킵
    final prefs = await SharedPreferences.getInstance();
    final planKey = 'plan_done_${scheduledDate.year}_${scheduledDate.month}';
    final isPlanDone = prefs.getBool(planKey) ?? false;
    if (isPlanDone) {
      debugPrint(
        '[NotificationService] plan already done for $planKey, skip reminder',
      );
      return;
    }

    await _notifications.zonedSchedule(
      planNotDoneReminderId,
      'NudgeGap 알림: 이번 달 소비 계획 세우기',
      '이번 달 생활비 계획을 아직 세우지 않았어요. 고정비를 입력하고 하루 예산을 확인해 볼까요?',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'plan_not_done_channel', // 채널 ID
          '소비 계획 리마인더', // 채널 이름
          channelDescription: '월급 이후 소비 계획이 작성되지 않았을 때 알려주는 알림',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: planNotDoneReminderId.toString(),
    );
  }

  /// ✅ SMS로 자동 생성된 거래에 대한 즉시 알림
  static Future<void> showInstantTransactionNotification({
    required bool isIncome,
    required int amount,
    required String memo,
  }) async {
    final title = isIncome ? '입금이 들어왔어요 💰' : '결제하셨네요? 💸';

    final body = isIncome
        ? '[$memo]에서 ${amount.toString()}원이 입금되었어요. 카테고리를 확인해 볼까요?'
        : '[$memo]에서 ${amount.toString()}원을 사용했어요. 카테고리를 설정해 주세요.';

    // 알림 id는 대충 시간 기준으로 유니크하게
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_tx_channel', // 채널 ID
          '실시간 거래 알림', // 채널 이름
          channelDescription: '문자 인식으로 자동 생성된 거래를 알려주는 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'instant_tx',
    );
  }
}
