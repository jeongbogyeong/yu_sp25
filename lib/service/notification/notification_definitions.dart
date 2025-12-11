/// 알림 유형 정의용 데이터 모델
class NotificationDefinition {
  final int type;
  final String title;
  final String description;
  final String frequency;

  const NotificationDefinition({
    required this.type,
    required this.title,
    required this.description,
    required this.frequency,
  });
}

/// 모든 알림 정의 리스트
const List<NotificationDefinition> notificationDefinitions = [
  NotificationDefinition(
    type: 0,
    title: "오늘의 지출 요약",
    description: "", // 🔥 여기 빈칸 → 매일 알림 보낼 때 채움
    frequency: "매일 저녁 10시",
  ),

  NotificationDefinition(
    type: 1,
    title: "주간 소비 패턴 분석",
    description: "최근 일주일간의 소비 패턴을 분석해 리포트 형식으로 알림",
    frequency: "일요일마다",
  ),
  NotificationDefinition(
    type: 2,
    title: "월간 소비 패턴 분석",
    description: "최근 한 달간의 소비 패턴을 분석해 리포트 형식으로 알림",
    frequency: "매월 1일",
  ),
  NotificationDefinition(
    type: 3,
    title: "오늘의 예산 확인",
    description: "하루 예산 대비 현재 지출 상황을 알림",
    frequency: "매일 아침 8시",
  ),
  NotificationDefinition(
    type: 4,
    title: "예상 세금 계산",
    description: "일정 금액 이상 소비 시 예상 세금 계산 결과를 알림",
    frequency: "매월 1일",
  ),
  NotificationDefinition(
    type: 5,
    title: "소비 기록이 지연되고 있어요",
    description: "소비 기록을 사용자가 2일 이상 입력하지 않았을 때 알림",
    frequency: "필요시",
  ),
];
