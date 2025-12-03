import '../datasources/community_remote_datasource.dart';
import '../../domain/entities/community_post_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/community_repository.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityRemoteDataSource remoteDataSource;

  CommunityRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CommunityPostEntity>> getPosts({
    int? limit,
    int? offset,
    String? category,
  }) async {
    return await remoteDataSource.getPosts(
      limit: limit,
      offset: offset,
      category: category,
    );
  }

  @override
  Future<CommunityPostEntity?> getPostById(String postId) async {
    return await remoteDataSource.getPostById(postId);
  }

  @override
  Future<CommunityPostEntity> createPost({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    String category = '자유',
  }) async {
    return await remoteDataSource.createPost(
      title: title,
      content: content,
      authorId: authorId,
      authorName: authorName,
      category: category,
    );
  }

  @override
  Future<CommunityPostEntity> updatePost({
    required String postId,
    String? title,
    String? content,
    String? category,
  }) async {
    return await remoteDataSource.updatePost(
      postId: postId,
      title: title,
      content: content,
      category: category,
    );
  }

  @override
  Future<bool> deletePost(String postId) async {
    return await remoteDataSource.deletePost(postId);
  }

  @override
  Future<List<CommentEntity>> getComments(String postId) async {
    return await remoteDataSource.getComments(postId);
  }

  @override
  Future<CommentEntity> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    return await remoteDataSource.addComment(
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      content: content,
    );
  }

  @override
  Future<bool> deleteComment(String commentId) async {
    return await remoteDataSource.deleteComment(commentId);
  }

  @override
  Future<bool> toggleLike({
    required String postId,
    required String userId,
  }) async {
    return await remoteDataSource.toggleLike(
      postId: postId,
      userId: userId,
    );
  }

  @override
  Future<bool> isLiked({
    required String postId,
    required String userId,
  }) async {
    return await remoteDataSource.isLiked(
      postId: postId,
      userId: userId,
    );
  }
}

