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

  Future<void> updatePost(String postId, String newText) async {
    final post = _postBox.get(postId);
    if (post != null) {
      post.text = newText;
      await post.save();
    }
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

  // 댓글 관련 메서드들
  List<Comment> getCommentsForPost(String postId) {
    final comments = _commentBox.values
        .where((comment) => comment.postId == postId)
        .toList();
    comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return comments;
  }

  Future<void> addComment(Comment comment) async {
    await _commentBox.put(comment.id, comment);
  }

  Future<void> deleteComment(String commentId) async {
    await _commentBox.delete(commentId);
  }

  Future<void> updateComment(String commentId, String newText) async {
    final comment = _commentBox.get(commentId);
    if (comment != null) {
      comment.text = newText;
      await comment.save();
    }
  }

  Future<void> toggleCommentLike(String commentId) async {
    final comment = _commentBox.get(commentId);
    if (comment == null) return;
    if (comment.likedByMe) {
      comment.likeCount = (comment.likeCount - 1).clamp(0, 1 << 31);
      comment.likedByMe = false;
    } else {
      comment.likeCount = comment.likeCount + 1;
      comment.likedByMe = true;
    }
    await comment.save();
  }

  // 댓글 ID 생성
  String generateCommentId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rnd = Random().nextInt(1 << 32);
    return 'c_${now}_$rnd';
  }
}



