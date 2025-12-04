import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<List<Map<String, dynamic>>> _fetchMyComments() async {
    final result = await _client
        .from('comments') // 🔥 테이블 이름 맞춰주기
        .select()
        .match({
          'author_id': widget.userId, // 🔥 컬럼 이름도 author_id 로
        })
        .order('created_at', ascending: false);

    return (result as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내가 쓴 댓글')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('에러: ${snapshot.error}'));
          }

          final comments = snapshot.data ?? [];
          if (comments.isEmpty) {
            return const Center(child: Text('작성한 댓글이 없습니다.'));
          }

          return ListView.separated(
            itemCount: comments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = comments[index];
              final content = c['content'] ?? '';
              final createdAtStr = c['created_at']?.toString() ?? '';

              return ListTile(
                title: Text(
                  content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('작성일: $createdAtStr'),
                onTap: () {
                  // TODO: 해당 댓글이 달린 게시글로 이동하고 싶으면 여기서 처리
                  // final postId = c['post_id'];
                },
              );
            },
          );
        },
      ),
    );
  }
}
