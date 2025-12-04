import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<List<Map<String, dynamic>>> _fetchMyLikedPosts() async {
    // 1) 내가 좋아요 누른 post_id 목록 가져오기
    final likeRows = await _client
        .from('community_post_likes')
        .select('post_id')
        .match({'user_id': widget.userId});

    final postIds = (likeRows as List)
        .map<String>((row) => row['post_id'] as String)
        .toList();

    if (postIds.isEmpty) return [];

    // 2) post_id 하나씩 돌면서 게시글 조회
    final List<Map<String, dynamic>> posts = [];

    for (final postId in postIds) {
      final post = await _client.from('community_posts').select().match({
        'id': postId,
      }).maybeSingle();

      if (post != null) {
        posts.add(post as Map<String, dynamic>);
      }
    }

    // 3) created_at 기준 내림차순 정렬 (최신순)
    posts.sort((a, b) {
      final aTime = a['created_at']?.toString() ?? '';
      final bTime = b['created_at']?.toString() ?? '';
      return bTime.compareTo(aTime);
    });

    return posts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내가 좋아요한 게시글')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('에러: ${snapshot.error}'));
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return const Center(child: Text('좋아요한 게시글이 없습니다.'));
          }

          return ListView.separated(
            itemCount: posts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = posts[index];
              final title = p['title'] ?? '(제목 없음)';
              final content = p['content'] ?? '';
              final createdAtStr = p['created_at']?.toString() ?? '';

              return ListTile(
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  createdAtStr.split('T').first,
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  // TODO: 커뮤니티 상세 보기로 이동하고 싶으면 여기서 처리 (post id: p['id'])
                },
              );
            },
          );
        },
      ),
    );
  }
}
