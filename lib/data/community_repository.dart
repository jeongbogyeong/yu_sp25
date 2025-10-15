import 'dart:math';
import '../models/post.dart';
import '../models/comment.dart';
import '../database/database_helper.dart';

class CommunityRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Post>> getAllPostsNewestFirst() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'posts',
      orderBy: 'created_at DESC',
    );

    final List<Post> posts = [];
    for (var map in maps) {
      // 작성자 정보 조회
      final authorMap = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [map['author_id']],
      );
      
      if (authorMap.isNotEmpty) {
        final author = Author(
          email: authorMap.first['email'],
          userId: authorMap.first['id'].toString(),
          displayName: authorMap.first['name'],
        );
        
        final post = Post(
          id: map['id'],
          author: author,
          createdAt: DateTime.parse(map['created_at']),
          text: map['text'],
          likeCount: map['like_count'] ?? 0,
          likedByMe: (map['liked_by_me'] ?? 0) == 1,
          category: map['category'] ?? '자유',
        );
        posts.add(post);
      }
    }
    return posts;
  }

  Future<void> putPost(Post post) async {
    final db = await _db.database;
    await db.insert('posts', {
      'id': post.id,
      'author_id': post.author.userId,
      'text': post.text,
      'category': post.category,
      'created_at': post.createdAt.toIso8601String(),
      'updated_at': post.createdAt.toIso8601String(),
      'like_count': post.likeCount,
      'liked_by_me': post.likedByMe ? 1 : 0,
    });
  }

  Future<void> deletePost(String postId) async {
    final db = await _db.database;
    await db.delete(
      'posts',
      where: 'id = ?',
      whereArgs: [postId],
    );
    
    // 관련 댓글도 삭제
    await db.delete(
      'comments',
      where: 'post_id = ?',
      whereArgs: [postId],
    );
  }

  Future<void> updatePost(String postId, String newText) async {
    final db = await _db.database;
    await db.update(
      'posts',
      {
        'text': newText,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [postId],
    );
  }

  Future<Post?> getPost(String postId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'posts',
      where: 'id = ?',
      whereArgs: [postId],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      final authorMap = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [map['author_id']],
      );
      
      if (authorMap.isNotEmpty) {
        final author = Author(
          email: authorMap.first['email'],
          userId: authorMap.first['id'].toString(),
          displayName: authorMap.first['name'],
        );
        
        return Post(
          id: map['id'],
          author: author,
          createdAt: DateTime.parse(map['created_at']),
          text: map['text'],
          likeCount: map['like_count'] ?? 0,
          likedByMe: (map['liked_by_me'] ?? 0) == 1,
        );
      }
    }
    return null;
  }

  Future<void> togglePostLike(String postId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'posts',
      where: 'id = ?',
      whereArgs: [postId],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      final currentLikeCount = map['like_count'] ?? 0;
      final currentLikedByMe = (map['liked_by_me'] ?? 0) == 1;
      
      final newLikeCount = currentLikedByMe 
          ? (currentLikeCount - 1).clamp(0, 1 << 31)
          : currentLikeCount + 1;
      final newLikedByMe = !currentLikedByMe;

      await db.update(
        'posts',
        {
          'like_count': newLikeCount,
          'liked_by_me': newLikedByMe ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [postId],
      );
    }
  }

  // Simple id generator without extra deps
  String generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rnd = Random().nextInt(1 << 32);
    return 'p_${now}_$rnd';
  }

  // 댓글 관련 메서드들
  Future<List<Comment>> getCommentsForPost(String postId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'comments',
      where: 'post_id = ?',
      whereArgs: [postId],
      orderBy: 'created_at ASC',
    );

    final List<Comment> comments = [];
    for (var map in maps) {
      final authorMap = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [map['author_id']],
      );
      
      if (authorMap.isNotEmpty) {
        final author = Author(
          email: authorMap.first['email'],
          userId: authorMap.first['id'].toString(),
          displayName: authorMap.first['name'],
        );
        
        final comment = Comment(
          id: map['id'],
          postId: map['post_id'],
          parentCommentId: map['parent_comment_id'],
          author: author,
          createdAt: DateTime.parse(map['created_at']),
          text: map['text'],
          likeCount: 0, // 댓글 좋아요 기능은 추후 구현
          likedByMe: false,
        );
        comments.add(comment);
      }
    }
    return comments;
  }

  Future<void> addComment(Comment comment) async {
    final db = await _db.database;
    await db.insert('comments', {
      'id': comment.id,
      'post_id': comment.postId,
      'parent_comment_id': comment.parentCommentId,
      'author_id': comment.author.userId,
      'text': comment.text,
      'created_at': comment.createdAt.toIso8601String(),
      'updated_at': comment.createdAt.toIso8601String(),
    });
  }

  Future<void> deleteComment(String commentId) async {
    final db = await _db.database;
    await db.delete(
      'comments',
      where: 'id = ?',
      whereArgs: [commentId],
    );
  }

  Future<void> updateComment(String commentId, String newText) async {
    final db = await _db.database;
    await db.update(
      'comments',
      {
        'text': newText,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [commentId],
    );
  }

  Future<void> toggleCommentLike(String commentId) async {
    // 댓글 좋아요 기능은 추후 구현
    // 현재는 빈 메서드로 유지
  }

  // 댓글 ID 생성
  String generateCommentId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rnd = Random().nextInt(1 << 32);
    return 'c_${now}_$rnd';
  }
}



