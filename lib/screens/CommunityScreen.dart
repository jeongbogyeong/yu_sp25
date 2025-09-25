import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/community_controller.dart';
import '../data/community_repository.dart';
import '../models/author.dart';
import '../models/post.dart';
import '../utils/password_hash.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = CommunityController(repository: CommunityRepository());
        controller.load();
        return controller;
      },
      child: const _CommunityView(),
    );
  }
}

class _CommunityView extends StatelessWidget {
  const _CommunityView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CommunityController>();
    final posts = controller.posts;

    return Scaffold(
      appBar: AppBar(
        title: Text('커뮤니티 (${posts.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            onPressed: () => _openCompose(context),
          ),
          IconButton(
            tooltip: '더미 글 추가(테스트)',
            icon: const Icon(Icons.bolt),
            onPressed: () async {
              final author = const Author(type: AuthorType.anonymous);
              await context.read<CommunityController>().createPost(
                author: author,
                text: '테스트 글 ' + DateTime.now().toIso8601String(),
              );
            },
          ),
        ],
      ),
      body: posts.isEmpty
          ? const Center(child: Text('첫 글을 작성해보세요.'))
          : ListView.separated(
              itemCount: posts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final post = posts[index];
                return ListTile(
                  title: Text(post.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(_metaOf(post)),
                  trailing: IconButton(
                    icon: Icon(post.likedByMe ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                    onPressed: () => controller.toggleLike(post.id),
                  ),
                  onTap: () {
                    // TODO: navigate to detail
                  },
                );
              },
            ),
    );
  }

  String _metaOf(Post p) {
    final name = p.author.type == AuthorType.anonymous ? '익명' : (p.author.nickname ?? '닉네임');
    final time = p.createdAt.toLocal();
    return '$name · ${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} · ❤ ${p.likeCount}';
  }

  Future<void> _openCompose(BuildContext context) async {
    final textCtrl = TextEditingController();
    final nickCtrl = TextEditingController();
    final pwCtrl = TextEditingController();
    AuthorType selected = AuthorType.anonymous;
    bool setPassword = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('새 글 작성', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: textCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '내용',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<AuthorType>(
                            value: selected,
                            items: const [
                              DropdownMenuItem(value: AuthorType.anonymous, child: Text('익명')),
                              DropdownMenuItem(value: AuthorType.nickname, child: Text('닉네임')),
                            ],
                            onChanged: (v) => setState(() => selected = v ?? AuthorType.anonymous),
                            decoration: const InputDecoration(labelText: '작성자'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (selected == AuthorType.nickname)
                          Expanded(
                            child: TextField(
                              controller: nickCtrl,
                              decoration: const InputDecoration(labelText: '닉네임'),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('비밀번호 설정(수정/삭제용)'),
                      value: setPassword,
                      onChanged: (v) => setState(() => setPassword = v),
                    ),
                    if (setPassword)
                      TextField(
                        controller: pwCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: '비밀번호'),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final author = Author(
                            type: selected,
                            nickname: selected == AuthorType.nickname ? (nickCtrl.text.trim().isEmpty ? null : nickCtrl.text.trim()) : null,
                          );
                          final text = textCtrl.text.trim();
                          if (text.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('내용을 입력해주세요.')));
                            return;
                          }

                          String? hash;
                          if (setPassword && pwCtrl.text.isNotEmpty) {
                            final salt = PasswordHash.generateSalt();
                            hash = PasswordHash.hash(pwCtrl.text, salt);
                          }

                          try {
                            await context.read<CommunityController>().createPost(
                              author: author,
                              text: text,
                              passwordHash: hash,
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('등록되었습니다.')));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
                            }
                          }
                        },
                        child: const Text('등록'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}


