// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:smartmoney/data/community_controller.dart';
// import 'package:smartmoney/data/community_repository.dart';
// import 'package:smartmoney/models/author.dart';
// import 'package:smartmoney/models/post.dart';
// import 'PostDetailScreen.dart';
//
// class CommunityScreen extends StatelessWidget {
//   const CommunityScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) {
//         final controller = CommunityController(repository: CommunityRepository());
//         controller.load();
//         return controller;
//       },
//       child: const _CommunityView(),
//     );
//   }
// }
//
// class _CommunityView extends StatelessWidget {
//   const _CommunityView();
//
//   @override
//   Widget build(BuildContext context) {
//     final controller = context.watch<CommunityController>();
//     final posts = controller.posts;
//     final currentUser = FirebaseAuth.instance.currentUser;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('커뮤니티 (${posts.length})'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add_comment),
//             onPressed: () => _openCompose(context),
//           ),
//           IconButton(
//             tooltip: '더미 글 추가(테스트)',
//             icon: const Icon(Icons.bolt),
//             onPressed: () async {
//               final author = currentUser != null
//                   ? Author.fromFirebaseUser(currentUser)
//                   : Author.anonymous();
//               await context.read<CommunityController>().createPost(
//                 author: author,
//                 text: '테스트 글 ' + DateTime.now().toIso8601String(),
//               );
//             },
//           ),
//         ],
//       ),
//       body: posts.isEmpty
//           ? const Center(child: Text('첫 글을 작성해보세요.'))
//           : ListView.separated(
//               itemCount: posts.length,
//               separatorBuilder: (_, __) => const Divider(height: 1),
//               itemBuilder: (context, index) {
//                 final post = posts[index];
//                 final isMyPost = currentUser?.uid == post.author.userId;
//
//                 return ListTile(
//                   title: Text(post.text, maxLines: 2, overflow: TextOverflow.ellipsis),
//                   subtitle: Text(_metaOf(post)),
//                   trailing: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: Icon(post.likedByMe ? Icons.favorite : Icons.favorite_border, color: Colors.red),
//                         onPressed: () => controller.toggleLike(post.id),
//                       ),
//                       if (isMyPost)
//                         PopupMenuButton<String>(
//                           onSelected: (value) {
//                             if (value == 'edit') {
//                               _openEditDialog(context, post);
//                             } else if (value == 'delete') {
//                               _confirmDelete(context, post.id);
//                             }
//                           },
//                           itemBuilder: (context) => [
//                             const PopupMenuItem(
//                               value: 'edit',
//                               child: Row(
//                                 children: [
//                                   Icon(Icons.edit),
//                                   SizedBox(width: 8),
//                                   Text('수정'),
//                                 ],
//                               ),
//                             ),
//                             const PopupMenuItem(
//                               value: 'delete',
//                               child: Row(
//                                 children: [
//                                   Icon(Icons.delete, color: Colors.red),
//                                   SizedBox(width: 8),
//                                   Text('삭제', style: TextStyle(color: Colors.red)),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                     ],
//                   ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => PostDetailScreen(post: post),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
//
//   String _metaOf(Post p) {
//     final name = p.author.maskedEmail;
//     final time = p.createdAt.toLocal();
//     return '$name · ${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} · ❤ ${p.likeCount}';
//   }
//
//   Future<void> _openCompose(BuildContext context) async {
//     final textCtrl = TextEditingController();
//     final currentUser = FirebaseAuth.instance.currentUser;
//
//     if (currentUser == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('로그인이 필요합니다.'))
//       );
//       return;
//     }
//
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (ctx) {
//         return Padding(
//           padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text('새 글 작성', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: textCtrl,
//                   maxLines: 4,
//                   decoration: const InputDecoration(
//                     labelText: '내용',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () async {
//                       final text = textCtrl.text.trim();
//                       if (text.isEmpty) {
//                         ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('내용을 입력해주세요.')));
//                         return;
//                       }
//
//                       try {
//                         final author = Author.fromFirebaseUser(currentUser);
//                         await context.read<CommunityController>().createPost(
//                           author: author,
//                           text: text,
//                         );
//                         if (ctx.mounted) Navigator.of(ctx).pop();
//                         if (context.mounted) {
//                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('등록되었습니다.')));
//                         }
//                       } catch (e) {
//                         if (context.mounted) {
//                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
//                         }
//                       }
//                     },
//                     child: const Text('등록'),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Future<void> _openEditDialog(BuildContext context, Post post) async {
//     final textCtrl = TextEditingController(text: post.text);
//
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (ctx) {
//         return Padding(
//           padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text('글 수정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: textCtrl,
//                   maxLines: 4,
//                   decoration: const InputDecoration(
//                     labelText: '내용',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () async {
//                       final text = textCtrl.text.trim();
//                       if (text.isEmpty) {
//                         ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('내용을 입력해주세요.')));
//                         return;
//                       }
//
//                       try {
//                         // TODO: 수정 기능 구현
//                         await context.read<CommunityController>().updatePost(post.id, text);
//                         if (ctx.mounted) Navigator.of(ctx).pop();
//                         if (context.mounted) {
//                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수정되었습니다.')));
//                         }
//                       } catch (e) {
//                         if (context.mounted) {
//                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
//                         }
//                       }
//                     },
//                     child: const Text('수정'),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Future<void> _confirmDelete(BuildContext context, String postId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('글 삭제'),
//         content: const Text('정말로 이 글을 삭제하시겠습니까?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: const Text('취소'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('삭제'),
//           ),
//         ],
//       ),
//     );
//
//     if (confirmed == true) {
//       try {
//         await context.read<CommunityController>().deletePost(postId);
//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
//         }
//       } catch (e) {
//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
//         }
//       }
//     }
//   }
// }