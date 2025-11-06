import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartmoney/screens/widgets/PostDetailScreen.dart';

// ✨ 테마 색상 정의 (다른 화면과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 긍정/강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색
const Color _expenseColor = Color(0xFFEF5350); // 지출/경고 (빨간색 계열)

// ✅ 커뮤니티 메인 화면 (Community Screen) - StatefulWidget으로 변경
// ----------------------------------------------------
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // ✅ 더미 게시글 데이터 (mutable list로 변경)
  List<Map<String, dynamic>> _posts = [
    {
      "title": "이번 달 식비 15만원으로 줄인 꿀팁!",
      "user": "절약왕머니",
      "time": "5분 전",
      "likes": 45,
      "comments": 12,
      "category": "절약팁",
    },
    {
      "title": "자녀 용돈 계좌, 어떤 은행이 좋을까요?",
      "user": "초보맘",
      "time": "1시간 전",
      "likes": 28,
      "comments": 5,
      "category": "재테크",
    },
    {
      "title": "가계부 꾸준히 쓰는 법 (작심삼일 극복!)",
      "user": "스마티",
      "time": "어제",
      "likes": 102,
      "comments": 35,
      "category": "가계부",
    },
    {
      "title": "최근 주식 시장 전망 공유합니다.",
      "user": "월급루팡",
      "time": "2일 전",
      "likes": 8,
      "comments": 2,
      "category": "자유",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("커뮤니티"),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: _secondaryColor,
        elevation: 0.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.black54),
            onPressed: () {
              // 검색 기능
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(_posts[index], context); // context 전달
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 새 글 작성 화면으로 이동
          _showPostWriteSheet(context);
        },
        backgroundColor: _primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 게시글 카드 위젯 (수정: onTap 추가)
  // ----------------------------------------------------
  Widget _buildPostCard(Map<String, dynamic> post, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 3,
      color: Colors.white,
      child: InkWell(
        onTap: () {
          // 2. 글 내용 보기 기능: 상세 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: post),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 태그
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  post["category"],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 제목
              Text(
                post["title"],
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // 사용자 정보 및 시간
              Row(
                children: [
                  const Icon(Icons.person_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    post["user"],
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const Text(" | ", style: TextStyle(color: Colors.grey)),
                  Text(
                    post["time"],
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 20),

              // 좋아요 및 댓글 수
              Row(
                children: [
                  _buildReactionIcon(Icons.thumb_up_alt_outlined, post["likes"], _primaryColor),
                  const SizedBox(width: 15),
                  _buildReactionIcon(Icons.comment_outlined, post["comments"], Colors.blueGrey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 좋아요/댓글 아이콘 헬퍼 위젯 (이전과 동일)
  Widget _buildReactionIcon(IconData icon, int count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          NumberFormat('#,###').format(count),
          style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // ✅ 새 글 작성 BottomSheet (수정: 데이터 처리 로직 추가)
  // ----------------------------------------------------
  void _showPostWriteSheet(BuildContext context) {
    String title = '';
    String content = '';
    String category = '자유'; // 기본 카테고리

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "새 글 작성",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 20, thickness: 1),
                  // 제목 입력
                  TextField(
                    onChanged: (value) => title = value,
                    decoration: const InputDecoration(
                      hintText: "제목을 입력하세요",
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // 내용 입력
                  TextField(
                    onChanged: (value) => content = value,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: "내용을 입력하세요...",
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // 3. 글 등록 기능: 새 게시글을 목록에 추가
                        if (title.isNotEmpty && content.isNotEmpty) {
                          _addPost(title, content, category);
                          Navigator.pop(context);
                        } else {
                          // TODO: 제목이나 내용이 비었을 때 알림
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('제목과 내용을 모두 입력해 주세요.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("등록하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ 글 등록 처리 함수
  void _addPost(String title, String content, String category) {
    final newPost = {
      "title": title,
      "content": content,
      "user": "현재 사용자", // 실제 사용자 이름으로 대체해야 함
      "time": "방금 전",
      "likes": 0,
      "comments": 0,
      "category": category,
    };

    setState(() {
      // 가장 최근 글이 위에 오도록 목록 맨 앞에 추가
      _posts.insert(0, newPost);
    });
  }
}