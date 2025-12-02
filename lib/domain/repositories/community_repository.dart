import '../entities/community_post_entity.dart';
import '../entities/comment_entity.dart';

abstract class CommunityRepository {
  // 게시글 관련
  Future<List<CommunityPostEntity>> getPosts({
    int? limit,
    int? offset,
    String? category,
  });
  
  Future<CommunityPostEntity?> getPostById(String postId);
  
  Future<CommunityPostEntity> createPost({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    String category,
  });
  
  Future<CommunityPostEntity> updatePost({
    required String postId,
    String? title,
    String? content,
    String? category,
  });
  
  Future<bool> deletePost(String postId);

  // 댓글 관련
  Future<List<CommentEntity>> getComments(String postId);
  
  Future<CommentEntity> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  });
  
  Future<bool> deleteComment(String commentId);

  // 좋아요 관련
  Future<bool> toggleLike({
    required String postId,
    required String userId,
  });
  
  Future<bool> isLiked({
    required String postId,
    required String userId,
  });
}

