import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ✨ 테마 색상 정의 (다른 화면과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 긍정/강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색
const Color _expenseColor = Color(0xFFEF5350); // 지출/경고 (빨간색 계열)

// ----------------------------------------------------
//  1. 게시글 상세 화면 (Post Detail Screen) - StatefulWidget으로 변경
// ----------------------------------------------------
class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  //  더미 댓글 목록 (Stateful로 관리)
  List<Map<String, dynamic>> _comments = [
    {
      "user": "재테크고수",
      "text": "맞아요! 용돈 계좌는 수수료가 적은 곳이 최고입니다.",
      "time": "1분 전",
    },
    {
      "user": "지나가는행인",
      "text": "꿀팁 감사합니다. 저도 식비 줄여봐야겠어요!",
      "time": "3시간 전",
    },
  ];

  final TextEditingController _commentController = TextEditingController();

  // ✅ 댓글 등록 함수
  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      final newComment = {
        "user": "댓글 작성자", // 현재 사용자 이름으로 대체해야 함
        "text": _commentController.text,
        "time": "방금 전",
      };

      setState(() {
        _comments.insert(0, newComment); // 최신 댓글을 맨 위에 추가
        widget.post['comments'] = (widget.post['comments'] ?? 0) + 1; // 게시글 댓글 수 업데이트
        _commentController.clear();
      });
      // 키보드 닫기
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 댓글이 등록될 때 게시글의 댓글 수도 업데이트되도록 widget.post를 사용합니다.
    final currentPost = widget.post;

    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        title: const Text("게시글 보기"),
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
                  // 제목, 정보 등 (기존 내용)
                  _buildPostHeader(currentPost),
                  const Divider(height: 30),

                  // 내용
                  Text(
                    currentPost["content"] ?? "이 글은 상세 내용을 포함하고 있습니다. 여기에 사용자가 작성한 본문 내용이 표시됩니다. 절약 팁이나 재테크 정보 등 다양한 내용을 공유할 수 있습니다.",
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 30),

                  // 좋아요 및 댓글 수 표시
                  Row(
                    children: [
                      _buildReactionButton(Icons.thumb_up_alt_outlined, currentPost["likes"], _primaryColor),
                      const SizedBox(width: 20),
                      // 댓글 수는 State에서 관리하는 댓글 목록의 길이로 표시
                      _buildReactionButton(Icons.comment_outlined, _comments.length, Colors.blueGrey),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // ----------------------------------------
                  // ✅ 댓글 섹션
                  // ----------------------------------------
                  const Text("댓글", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const Divider(height: 10),

                  ..._comments.map((comment) => _buildCommentTile(comment)),
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

  // 리액션 버튼 (좋아요/댓글)
  Widget _buildReactionButton(IconData icon, int count, Color color) {
    return InkWell(
      onTap: () {
        // 좋아요 기능 등
      },
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 8),
          Text(
            NumberFormat('#,###').format(count),
            style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ✅ 댓글 타일 위젯
  Widget _buildCommentTile(Map<String, dynamic> comment) {
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
                      comment["user"],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      comment["time"],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment["text"],
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
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
          top: 8
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "댓글을 입력하세요...",
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
              ),
              minLines: 1,
              maxLines: 4,
            ),
          ),
          IconButton(
            onPressed: _addComment,
            icon: const Icon(Icons.send_rounded),
            color: _primaryColor,
            disabledColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}