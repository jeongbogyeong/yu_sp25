import 'package:flutter/foundation.dart';
import '../models/author.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../data/community_repository.dart';

class CommunityController extends ChangeNotifier {
  final CommunityRepository repository;

  CommunityController({required this.repository});

  List<Post> _posts = const [];
  List<Post> get posts => _posts;

  List<Comment> _comments = const [];
  List<Comment> get comments => _comments;

  Future<void> load() async {
    _posts = await repository.getAllPostsNewestFirst();
    // debug
    // ignore: avoid_print
    print('[CommunityController] load: posts=${_posts.length}');
    notifyListeners();
  }

  Future<void> createPost({
    required Author author,
    required String text,
    List<String>? imagePaths,
    String category = '자유',
  }) async {
    final post = Post(
      id: repository.generateId(),
      author: author,
      createdAt: DateTime.now(),
      text: text,
      imagePaths: imagePaths,
      category: category,
    );
    await repository.putPost(post);
    // debug
    // ignore: avoid_print
    print('[CommunityController] createPost: id=${post.id}');
    load();
  }

  Future<void> toggleLike(String postId) async {
    await repository.togglePostLike(postId);
    load();
  }

  Future<void> updatePost(String postId, String newText) async {
    await repository.updatePost(postId, newText);
    load();
  }

  Future<void> deletePost(String postId) async {
    await repository.deletePost(postId);
    load();
  }

  // 댓글 관련 메서드들
  Future<void> loadComments(String postId) async {
    _comments = await repository.getCommentsForPost(postId);
    notifyListeners();
  }

  Future<void> addComment({
    required String postId,
    required Author author,
    required String text,
    String? parentCommentId,
  }) async {
    final comment = Comment(
      id: repository.generateCommentId(),
      postId: postId,
      parentCommentId: parentCommentId,
      author: author,
      createdAt: DateTime.now(),
      text: text,
    );
    await repository.addComment(comment);
    loadComments(postId);
  }

  Future<void> deleteComment(String commentId, String postId) async {
    await repository.deleteComment(commentId);
    loadComments(postId);
  }

  Future<void> updateComment(String commentId, String newText, String postId) async {
    await repository.updateComment(commentId, newText);
    loadComments(postId);
  }

  Future<void> toggleCommentLike(String commentId, String postId) async {
    await repository.toggleCommentLike(commentId);
    loadComments(postId);
  }
}


