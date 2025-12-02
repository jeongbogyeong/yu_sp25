class SpendingEntity {
  final String uid;
  final int goal;
  final int spending;
  final int type; //0:식비, 1:교통, 2:주거, 3:쇼핑, 4:기타

  SpendingEntity({
    required this.uid,
    required this.goal,
    required this.spending,
    required this.type
  });
}
