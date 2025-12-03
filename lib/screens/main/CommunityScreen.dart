import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:smartmoney/screens/widgets/PostDetailScreen.dart';
import 'package:smartmoney/screens/viewmodels/CommunityViewModel.dart';
import 'package:smartmoney/screens/viewmodels/UserViewModel.dart';
import 'package:smartmoney/domain/entities/community_post_entity.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Provider에서 ViewModel 두 개 꺼내오기
      final communityVm = Provider.of<CommunityViewModel>(context, listen: false);
      final userVm = Provider.of<UserViewModel>(context, listen: false);

      final user = userVm.user;
      if (user == null) {
        // 로그인 안 돼 있으면 일단 로드 안 함 (필요하면 스낵바 띄우기)
        return;
      }

      // 로그인한 유저의 id를 같이 넘겨서 로드
      communityVm.loadPosts(
        limit: 20,
        userId: user.id,
      );
    });
  }

  // 날짜 포맷팅 헬퍼 함수
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

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CommunityViewModel>(context);
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
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
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final user = userViewModel.user;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('로그인이 필요합니다.')),
                          );
                          return;
                        }

                        await viewModel.loadPosts(
                          limit: 20,
                          userId: user.id,
                        );
                      },
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              )
              : viewModel.posts.isEmpty
                  ? const Center(
                      child: Text(
                        '아직 게시글이 없습니다.\n첫 게시글을 작성해보세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                    onRefresh: () async {
                      final user = userViewModel.user;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('로그인이 필요합니다.')),
                        );
                        return;
                      }

                      await viewModel.loadPosts(
                        limit: 20,
                        userId: user.id,
                      );
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: viewModel.posts.length,
                      itemBuilder: (context, index) {
                        return _buildPostCard(viewModel.posts[index], context);
                      },
                    ),
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
  // ✅ 게시글 카드 위젯 (Entity 사용)
  // ----------------------------------------------------
  Widget _buildPostCard(CommunityPostEntity post, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 3,
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: post.id),
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
                  post.category,
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
                post.title,
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
                    post.authorName,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const Text(" | ", style: TextStyle(color: Colors.grey)),
                  Text(
                    _formatTime(post.createdAt),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 20),

              // 좋아요 및 댓글 수
              Row(
                children: [
                  _buildReactionIcon(Icons.thumb_up_alt_outlined, post.likesCount, _primaryColor),
                  const SizedBox(width: 15),
                  _buildReactionIcon(Icons.comment_outlined, post.commentsCount, Colors.blueGrey),
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
  // ✅ 새 글 작성 BottomSheet (ViewModel 사용)
  // ----------------------------------------------------
  void _showPostWriteSheet(BuildContext context) {
    final viewModel = Provider.of<CommunityViewModel>(context, listen: false);
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    
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
                      onPressed: () async {
                        if (title.isNotEmpty && content.isNotEmpty) {
                          final user = userViewModel.user;
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('로그인이 필요합니다.')),
                            );
                            Navigator.pop(context);
                            return;
                          }

                          final success = await viewModel.createPost(
                            title: title,
                            content: content,
                            authorId: user.id,
                            authorName: user.name,
                            category: category,
                          );

                          if (success) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('게시글이 작성되었습니다.')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(viewModel.errorMessage ?? '게시글 작성에 실패했습니다.'),
                              ),
                            );
                          }
                        } else {
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

}