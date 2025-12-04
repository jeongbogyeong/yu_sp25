import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // 날짜 포맷을 위해 추가

// ✨ 테마 색상 정의 (CommunityScreen과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 긍정/강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색
const Color _expenseColor = Color(0xFFEF5350); // 지출/경고 (빨간색 계열)

// ✅ 내가 쓴 댓글 목록 화면
// ----------------------------------------------------
class MyCommentListScreen extends StatefulWidget {
  final String userId;
  const MyCommentListScreen({super.key, required this.userId});

  @override
  State<MyCommentListScreen> createState() => _MyCommentListScreenState();
}

class _MyCommentListScreenState extends State<MyCommentListScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  final _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _future = _fetchMyComments();
  }

  // 날짜 포맷팅 헬퍼 함수 (CommunityScreen의 로직을 간소화하여 재사용)
  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      return DateFormat('yyyy.MM.dd HH:mm').format(dateTime);
    } catch (e) {
      return '시간 정보 없음';
    }
  }

  // ----------------------------------------------------
  // ✅ 데이터 페칭 로직
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> _fetchMyComments() async {
    // 댓글 정보와 해당 댓글이 달린 게시글의 제목을 함께 가져옵니다.
    // 'post_id'를 이용해 'community_posts' 테이블의 'title'을 조인하여 가져오는 방식 (PostgreSQL/Supabase RLS 설정 필요)
    // 만약 RLS 설정이 복잡하다면, 쿼리를 분리하여 postTitle을 가져와야 할 수도 있습니다.
    // 여기서는 Supabase의 `select('*, community_posts(title)')` 구문을 사용합니다.
    final result = await _client
        .from('community_comments') // 🔥 테이블 이름
        .select('*, community_posts(title)') // 🔥 조인하여 게시글 제목 가져오기
        .match({
      'author_id': widget.userId, // 🔥 컬럼 이름
    })
        .order('created_at', ascending: false);

    return (result as List).cast<Map<String, dynamic>>();
  }
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        title: const Text("내가 쓴 댓글"),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: _secondaryColor,
        elevation: 0.0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '데이터 로드 중 에러가 발생했습니다:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _expenseColor),
              ),
            );
          }

          final comments = snapshot.data ?? [];
          if (comments.isEmpty) {
            return const Center(
              child: Text(
                '아직 작성한 댓글이 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () {
              setState(() {
                _future = _fetchMyComments();
              });
              return _future;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final c = comments[index];
                return _buildCommentCard(c, context);
              },
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 댓글 카드 위젯 (CommunityScreen의 PostCard 스타일 적용)
  // ----------------------------------------------------
  Widget _buildCommentCard(
      Map<String, dynamic> comment, BuildContext context) {
    final content = comment['content'] ?? '내용 없음';
    final createdAtStr = comment['created_at']?.toString() ?? '';
    final formattedTime = _formatDateTime(createdAtStr);

    // 조인된 게시글 정보에서 제목 추출 (Supabase 조인 결과 구조를 가정)
    final postTitleMap = comment['community_posts'] as Map<String, dynamic>?;
    final postTitle = postTitleMap?['title'] as String? ?? '원본 게시글 제목 없음';
    final postId = comment['post_id']; // 게시글 ID (이동 시 사용)

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: Colors.white,
      child: InkWell(
        onTap: () {
          if (postId != null) {
            // TODO: postId를 사용하여 해당 게시글 상세 화면으로 이동
            // 예시: Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailScreen(postId: postId)));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('게시글 ID $postId 로 이동 (구현 예정)')),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ➡️ 원본 게시글 제목 (카테고리 태그 위치)
              Row(
                children: [
                  const Icon(
                    Icons.article_outlined,
                    size: 16,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '원글: $postTitle',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 15),

              // 💬 댓글 내용 (제목 위치)
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  // fontWeight: FontWeight.bold, // 댓글이라 Bold는 해제
                  color: Colors.black87,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // ⏱️ 작성 시간 (사용자 정보 위치)
              Row(
                children: [
                  const Icon(
                    Icons.access_time_filled,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '작성일: $formattedTime',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}