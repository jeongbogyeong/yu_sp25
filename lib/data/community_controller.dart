import 'package:flutter/foundation.dart';
import '../models/author.dart';
import '../models/post.dart';
import '../data/community_repository.dart';

class CommunityController extends ChangeNotifier {
  final CommunityRepository repository;

  CommunityController({required this.repository});

  List<Post> _posts = const [];
  List<Post> get posts => _posts;

  void load() {
    _posts = repository.getAllPostsNewestFirst();
    // debug
    // ignore: avoid_print
    print('[CommunityController] load: posts=${_posts.length}');
    notifyListeners();
  }

  Future<void> createPost({
    required Author author,
    required String text,
    List<String>? imagePaths,
    String? passwordHash,
  }) async {
    final post = Post(
      id: repository.generateId(),
      author: author,
      createdAt: DateTime.now(),
      text: text,
      imagePaths: imagePaths,
      passwordHash: passwordHash,
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
}


