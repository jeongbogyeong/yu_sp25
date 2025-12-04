import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartmoney/screens/viewmodels/UserViewModel.dart';
import 'package:smartmoney/domain/entities/comment_entity.dart';
import '../viewmodels/CommunityViewModel.dart';

// ✨ 테마 색상 정의 (다른 화면과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 긍정/강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색
const Color _expenseColor = Color(0xFFEF5350); // 지출/경고 (빨간색 계열)

// ----------------------------------------------------
//  게시글 상세 화면 (Post Detail Screen)
// ----------------------------------------------------
class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 혹시 직접 들어온 경우를 대비해서 댓글 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final communityViewModel =
      Provider.of<CommunityViewModel>(context, listen: false);
      communityViewModel.loadComments(widget.post['id']);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ✅ 시간 포맷 함수 (댓글 시간용)
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('yyyy.MM.dd').format(dateTime);
  }

  // ✅ 댓글 등록 함수
  Future<void> _addComment(BuildContext context) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final communityViewModel =
    Provider.of<CommunityViewModel>(context, listen: false);

    final user = userViewModel.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    final postId = widget.post['id'] as String;

    final success = await communityViewModel.addComment(
      postId: postId,
      authorId: user.id,
      authorName: user.name ?? '익명',
      content: text,
    );

    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus(); // 키보드 닫기
      // 댓글 수는 CommunityViewModel 내부에서 selectedPost와 posts에 반영됨
      // 이 화면에서는 comments.length로 표시하므로 따로 setState 필요 없음
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            communityViewModel.errorMessage ?? '댓글 작성에 실패했습니다.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 게시글 정보 (리스트에서 넘겨준 Map)
    final currentPost = widget.post;

    // 🔹 ViewModel에서 댓글 목록/선택된 게시글 받아오기
    final communityViewModel = Provider.of<CommunityViewModel>(context);
    final comments = communityViewModel.comments;
    final selectedPost = communityViewModel.selectedPost;

    // 좋아요 수는 selectedPost가 있으면 그걸 우선 사용
    final likesCount =
        selectedPost?.likesCount ?? (currentPost['likes'] as int? ?? 0);

    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        title: const Text("게시글 보기"),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        leading: const BackButton(
          color: Colors.black87,
        ),
        backgroundColor: _secondaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ----------------------------------------
          // 게시글 내용 스크롤 영역
          // ----------------------------------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목, 작성자, 시간 등 헤더
                  _buildPostHeader(currentPost),
                  const Divider(height: 30),

                  // 내용
                  Text(
                    currentPost["content"] ??
                        "이 글은 상세 내용을 포함하고 있습니다. 여기에 사용자가 작성한 본문 내용이 표시됩니다. 절약 팁이나 재테크 정보 등 다양한 내용을 공유할 수 있습니다.",
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 좋아요 및 댓글 수 표시
                  Row(
                    children: [
                      Builder(
                        builder: (context) {
                          final communityViewModel =
                          Provider.of<CommunityViewModel>(context); // listen: true
                          final userViewModel =
                          Provider.of<UserViewModel>(context, listen: false);

                          final user = userViewModel.user;
                          final postId = currentPost['id'] as String;

                          // ✅ 현재 좋아요 상태
                          final isLiked = communityViewModel.isPostLiked(postId);

                          return _buildReactionButton(
                            icon: isLiked
                                ? Icons.thumb_up            // 활성: 채워진 손
                                : Icons.thumb_up_alt_outlined, // 비활성: 빈 손
                            count: likesCount,
                            color: _primaryColor, // 색상 토글
                            onTap: () async {
                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('로그인이 필요합니다.')),
                                );
                                return;
                              }

                              await communityViewModel.toggleLike(
                                postId: postId,
                                userId: user.id,
                              );
                              // toggleLike 안에서 notifyListeners() 호출 → isLiked 갱신 → UI 자동 리빌드
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 20),
                      // 댓글 수는 동일
                      _buildReactionButton(
                        icon: Icons.comment_outlined,
                        count: comments.length,
                        color: Colors.blueGrey,
                        onTap: () {
                          // 스크롤 이동 등 필요하면 여기서 처리
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // ----------------------------------------
                  // ✅ 댓글 섹션
                  // ----------------------------------------
                  const Text(
                    "댓글",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(height: 10),

                  if (comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "아직 댓글이 없습니다.\n첫 댓글을 남겨보세요!",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    )
                  else
                    ...comments.map(
                          (comment) => _buildCommentTile(comment),
                    ),
                ],
              ),
            ),
          ),

          // ----------------------------------------
          // ✅ 댓글 입력창
          // ----------------------------------------
          _buildCommentInputField(context),
        ],
      ),
    );
  }

  // 게시글 헤더 (제목, 정보)
  Widget _buildPostHeader(Map<String, dynamic> post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리 태그
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            post["category"] ?? "자유",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 제목
        Text(
          post["title"],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        // 사용자 정보 및 시간
        Row(
          children: [
            const Icon(Icons.person_rounded, size: 18, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              post["user"],
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const Text(" | ", style: TextStyle(color: Colors.grey)),
            Text(
              post["time"],
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  // 리액션 버튼 (좋아요/댓글) - onTap 콜백 추가
  Widget _buildReactionButton({
    required IconData icon,
    required int count,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 8),
          Text(
            NumberFormat('#,###').format(count),
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 댓글 타일 위젯 (CommentEntity 기반)
  Widget _buildCommentTile(CommentEntity comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: _secondaryColor,
            child: Icon(Icons.person, size: 20, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatTime(comment.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 댓글 입력창 위젯
  Widget _buildCommentInputField(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        // 키보드에 가려지지 않도록 패딩 조정
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: "댓글을 입력하세요...",
                border: InputBorder.none,
                contentPadding:
                EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
              ),
              minLines: 1,
              maxLines: 4,
            ),
          ),
          IconButton(
            onPressed: () => _addComment(context),
            icon: const Icon(Icons.send_rounded),
            color: _primaryColor,
            disabledColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}
