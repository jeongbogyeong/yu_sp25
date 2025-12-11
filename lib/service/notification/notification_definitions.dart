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
    description: "", // 🔥 body는 NotificationService에서 오늘 총 지출로 만들어줌
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
    description: "", // 🔥 실제 문구는 NotificationService에서 하루 예산으로 채움
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

  // -------------------------------
  // 🌱 계절 알림 (항상 제공되는 시스템 알림)
  // -------------------------------
  NotificationDefinition(
    type: 6,
    title: "여름 생활비 걱정",
    description: "여름 생활비 벌써 걱정되시나요? 커뮤니티에서 생활비 관련 꿀팁을 나눠보세요!",
    frequency: "매년 6월 1일 오전 9시",
  ),
  NotificationDefinition(
    type: 7,
    title: "겨울 난방비 걱정",
    description: "겨울 난방비 벌써 걱정되시나요? 커뮤니티에서 생활비 관련 꿀팁을 나눠보세요!",
    frequency: "매년 12월 1일 오전 9시",
  ),
  NotificationDefinition(
    type: 8,
    title: "환절기 병원비 걱정 (봄)",
    description: "일교차가 심한 환절기 병원비 벌써 걱정되시나요? 커뮤니티에서 꿀팁을 나눠보세요!",
    frequency: "매년 3월 1일 오전 9시",
  ),
  NotificationDefinition(
    type: 9,
    title: "환절기 병원비 걱정 (가을)",
    description: "일교차가 심한 환절기 병원비 벌써 걱정되시나요? 커뮤니티에서 꿀팁을 나눠보세요!",
    frequency: "매년 9월 1일 오전 9시",
  ),
  NotificationDefinition(
    type: 10,
    title: "연말정산 준비 알림",
    description: "연말 정산, 걱정이 많으신가요? 커뮤니티에서 관련 꿀팁을 나눠보세요!",
    frequency: "매년 1월 5일",
  ),
  NotificationDefinition(
    type: 11,
    title: "소득 계획 작성 //사실은 유령 버튼(발표용으로 생성)",
    description: "소비계획이 아직 없네요! Nudge Gap에서 소득 계획을 작성해보세요.",
    frequency: "필요시",
  ),

  NotificationDefinition(
    type: 12,
    title: "월급 기록 //사실은 유령 버튼(발표용으로 생성)",
    description: "월급이 아직 없네요! Nudge Gap에서 월급을 작성해보세요.",
    frequency: "필요시",
  ),
];
