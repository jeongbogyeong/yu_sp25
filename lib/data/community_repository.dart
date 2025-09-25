import 'dart:math';
import 'package:hive/hive.dart';
import '../models/post.dart';
import '../models/comment.dart';

class CommunityRepository {
  Box<Post> get _postBox => Hive.box<Post>('community_posts');
  Box<Comment> get _commentBox => Hive.box<Comment>('community_comments');

  List<Post> getAllPostsNewestFirst() {
    final posts = _postBox.values.toList(growable: false);
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<void> putPost(Post post) async {
    await _postBox.put(post.id, post);
  }

  Future<void> deletePost(String postId) async {
    await _postBox.delete(postId);
  }

  Post? getPost(String postId) => _postBox.get(postId);

  Future<void> togglePostLike(String postId) async {
    final post = _postBox.get(postId);
    if (post == null) return;
    if (post.likedByMe) {
      post.likeCount = (post.likeCount - 1).clamp(0, 1 << 31);
      post.likedByMe = false;
    } else {
      post.likeCount = post.likeCount + 1;
      post.likedByMe = true;
    }
    await post.save();
  }

  // Simple id generator without extra deps
  String generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rnd = Random().nextInt(1 << 32);
    return 'p_${now}_$rnd';
  }
}


