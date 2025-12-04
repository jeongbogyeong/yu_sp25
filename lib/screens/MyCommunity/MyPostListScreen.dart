import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<List<Map<String, dynamic>>> _fetchMyPosts() async {
    final result = await _client
        .from('community_posts')
        .select()
        // 🔥 여기! user_id → author_id
        .match({'author_id': widget.userId})
        .order('created_at', ascending: false);

    return (result as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내가 쓴 게시물')),
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
            return const Center(child: Text('작성한 게시글이 없습니다.'));
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
                  // TODO: 게시글 상세 화면으로 이동
                  // final postId = p['id'];
                },
              );
            },
          );
        },
      ),
    );
  }
}
