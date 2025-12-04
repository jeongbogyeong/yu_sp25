import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // 날짜 포맷을 위해 추가

// ✨ 테마 색상 정의 (CommunityScreen과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 긍정/강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색
const Color _expenseColor = Color(0xFFEF5350); // 지출/경고 (빨간색 계열)

// ✅ 내가 좋아요한 게시글 목록 화면
// ----------------------------------------------------
class MyLikedPostListScreen extends StatefulWidget {
  final String userId;
  const MyLikedPostListScreen({super.key, required this.userId});

  @override
  State<MyLikedPostListScreen> createState() => _MyLikedPostListScreenState();
}

class _MyLikedPostListScreenState extends State<MyLikedPostListScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _future = _fetchMyLikedPosts();
  }

  // 날짜 포맷팅 헬퍼 함수 (CommunityScreen의 로직을 간소화하여 재사용)
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else {
      return DateFormat('yy.MM.dd').format(dateTime);
    }
  }

  // ----------------------------------------------------
  // ✅ 데이터 페칭 로직 개선 (하나씩 fetch하는 대신 in 필터 사용)
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> _fetchMyLikedPosts() async {
    // 1) 내가 좋아요 누른 post_id 목록 가져오기
    final likeRows = await _client
        .from('community_post_likes')
        .select('post_id, created_at') // 좋아요 누른 시점도 함께 가져옵니다.
        .match({'user_id': widget.userId})
        .order('created_at', ascending: false); // 좋아요 누른 최신순으로 정렬

    final likedPostsInfo = (likeRows as List)
        .map<Map<String, dynamic>>((row) => {
          'post_id': row['post_id'],
          'liked_at': row['created_at'], // 좋아요 누른 시간
        })
        .toList();

    if (likedPostsInfo.isEmpty) return [];

    final postIds = likedPostsInfo.map((info) => info['post_id']).toList();

    // 2) in 필터를 사용하여 해당 post_id 목록에 해당하는 게시글 한 번에 조회
    final postList = await _client
        .from('community_posts')
        .select(
          'id, title, content, created_at, category, author_name, likes_count, comments_count') // 필요한 컬럼만 선택
        .inFilter('id', postIds);

    final typedPostList =
      (postList as List).cast<Map<String, dynamic>>();

    // 3) 좋아요 누른 순서대로 정렬하기 위해, 좋아요 정보와 게시글 정보를 병합합니다.
    final List<Map<String, dynamic>> finalPosts = [];

    for (final info in likedPostsInfo) {
      final postId = info['post_id'];
      final Map<String, dynamic> postData = typedPostList.firstWhere(
            (post) => post['id'] == postId,
        orElse: () => <String, dynamic>{},
      );

      if (postData.isNotEmpty) {
        // liked_at 정보 추가해서 새 Map으로 합치기
        finalPosts.add({
          ...postData,
          'liked_at': info['liked_at'],
        });
      }
    }

    // 4) 좋아요 누른 시점(liked_at) 기준 내림차순 정렬 (이미 쿼리에서 정렬했지만 한 번 더 확인)
    finalPosts.sort((a, b) {
      final aTime = a['liked_at']?.toString() ?? '';
      final bTime = b['liked_at']?.toString() ?? '';
      return bTime.compareTo(aTime);
    });

    return finalPosts;
  }
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        title: const Text("내가 좋아요한 게시글"),
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
                '아직 좋아요한 게시글이 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () {
              setState(() {
                _future = _fetchMyLikedPosts();
              });
              return _future;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final p = posts[index];
                return _buildLikedPostCard(p, context);
              },
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 좋아요한 게시글 카드 위젯 (CommunityScreen의 PostCard 스타일 적용)
  // ----------------------------------------------------
  Widget _buildLikedPostCard(Map<String, dynamic> post, BuildContext context) {
    final title = post['title'] ?? '(제목 없음)';
    final authorName = post['author_name'] ?? '익명';
    final category = post['category'] ?? '자유';
    final likesCount = post['likes_count'] ?? 0;
    final commentsCount = post['comments_count'] ?? 0;

    // 게시글 작성 시간 (createdAt)
    final createdAtStr = post['created_at']?.toString();
    final postTime = createdAtStr != null
        ? _formatTime(DateTime.parse(createdAtStr).toLocal())
        : '시간 정보 없음';

    // 좋아요 누른 시간 (liked_at)
    final likedAtStr = post['liked_at']?.toString();
    final likedTime = likedAtStr != null
        ? DateFormat('yy.MM.dd HH:mm').format(
      DateTime.parse(likedAtStr).toLocal(),
    )
        : '좋아요 시각 없음';

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
              // 카테고리 태그 및 작성자
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                  Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        authorName,
                        style:
                        const TextStyle(fontSize: 13, color: Colors.black54),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Divider(height: 20),

              // 좋아요/댓글 수 및 좋아요 시각
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 좋아요 및 댓글 수
                  Row(
                    children: [
                      _buildReactionIcon(
                        Icons.thumb_up_alt_rounded, // 좋아요 목록이므로 채워진 아이콘
                        likesCount,
                        _primaryColor,
                      ),
                      const SizedBox(width: 15),
                      _buildReactionIcon(
                        Icons.comment_outlined,
                        commentsCount,
                        Colors.blueGrey,
                      ),
                      const SizedBox(width: 15),
                      // 게시글 작성 시간
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            postTime,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 좋아요 누른 시각
                  Text(
                    'Liked: $likedTime',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
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