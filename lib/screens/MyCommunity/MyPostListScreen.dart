import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // 날짜 포맷을 위해 추가

// ✨ 테마 색상 정의 (CommunityScreen과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 긍정/강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색
const Color _expenseColor = Color(0xFFEF5350); // 지출/경고 (빨간색 계열)

// ✅ 내가 쓴 게시물 목록 화면
// ----------------------------------------------------
class MyPostListScreen extends StatefulWidget {
  final String userId;
  const MyPostListScreen({super.key, required this.userId});

  @override
  State<MyPostListScreen> createState() => _MyPostListScreenState();
}

class _MyPostListScreenState extends State<MyPostListScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _future = _fetchMyPosts();
  }

  // 날짜/시간 포맷팅 헬퍼 함수 (CommunityScreen의 로직을 재사용)
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('yyyy.MM.dd').format(dateTime);
    }
  }

  // ----------------------------------------------------
  // ✅ 데이터 페칭 로직
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> _fetchMyPosts() async {
    final result = await _client
        .from('community_posts')
        .select()
        .match({'author_id': widget.userId}) // 작성자 ID로 필터링
        .order('created_at', ascending: false);

    return (result as List).cast<Map<String, dynamic>>();
  }
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        title: const Text("내가 쓴 게시물"),
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
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return const Center(
              child: Text(
                '작성한 게시글이 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () {
              setState(() {
                _future = _fetchMyPosts();
              });
              return _future;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final p = posts[index];
                return _buildMyPostCard(p, context);
              },
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 내가 쓴 게시글 카드 위젯 (CommunityScreen의 PostCard 스타일 적용)
  // ----------------------------------------------------
  Widget _buildMyPostCard(Map<String, dynamic> post, BuildContext context) {
    final title = post['title'] ?? '(제목 없음)';
    final content = post['content'] ?? '내용 없음';
    final category = post['category'] ?? '자유';
    final likesCount = post['likes_count'] ?? 0;
    final commentsCount = post['comments_count'] ?? 0;
    final createdAtStr = post['created_at']?.toString();
    final postTime = createdAtStr != null
        ? _formatTime(DateTime.parse(createdAtStr).toLocal())
        : '시간 정보 없음';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: Colors.white,
      child: InkWell(
        onTap: () {
          // TODO: 게시글 상세 화면으로 이동 (post id: post['id'])
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('게시글 ID ${post['id']} 로 이동 (구현 예정)')),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 태그 및 시간
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 카테고리 태그
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                  // 작성 시간
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        postTime,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 제목
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // 내용 미리보기
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const Divider(height: 20),

              // 좋아요 및 댓글 수
              Row(
                children: [
                  _buildReactionIcon(
                    Icons.thumb_up_alt_outlined,
                    likesCount,
                    _primaryColor,
                  ),
                  const SizedBox(width: 15),
                  _buildReactionIcon(
                    Icons.comment_outlined,
                    commentsCount,
                    Colors.blueGrey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 좋아요/댓글 아이콘 헬퍼 위젯 (CommunityScreen에서 복사)
  Widget _buildReactionIcon(IconData icon, int count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          NumberFormat('#,###').format(count),
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}