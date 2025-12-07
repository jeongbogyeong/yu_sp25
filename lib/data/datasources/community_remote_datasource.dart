import '../../domain/entities/community_post_entity.dart';
import '../../domain/entities/comment_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityRemoteDataSource {
  final SupabaseClient client;
  CommunityRemoteDataSource(this.client);

  // 게시글 목록 조회 (페이지네이션 지원)
  Future<List<CommunityPostEntity>> getPosts({
    int? limit,
    int? offset,
    String? category,
  }) async {
    try {
      // ★ 타입 싸움 안 나게 그냥 dynamic으로 받자
      dynamic query = client.from('community_posts').select();

      if (category != null && category.isNotEmpty) {
        // eq 말고 match만 사용
        query = query.match({'category': category});
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      // 정렬은 제일 마지막에
      query = query.order('created_at', ascending: false);

      final result = await query;

      return (result as List).map<CommunityPostEntity>((item) {
        return CommunityPostEntity(
          id: item['id'],
          title: item['title'],
          content: item['content'],
          authorId: item['author_id'],
          authorName: item['author_name'],
          category: item['category'] ?? '자유',
          likesCount: item['likes_count'] ?? 0,
          commentsCount: item['comments_count'] ?? 0,
          createdAt: DateTime.parse(item['created_at']),
          updatedAt: DateTime.parse(item['updated_at'] ?? item['created_at']),
        );
      }).toList();
    } catch (e) {
      print('❌ getPosts error: $e');
      rethrow;
    }
  }

  // 특정 게시글 조회
  Future<CommunityPostEntity?> getPostById(String postId) async {
    try {
      final result = await client.from('community_posts').select().match({
        'id': postId,
      }).maybeSingle();

      if (result == null) return null;

      return CommunityPostEntity(
        id: result['id'],
        title: result['title'],
        content: result['content'],
        authorId: result['author_id'],
        authorName: result['author_name'],
        category: result['category'] ?? '자유',
        likesCount: result['likes_count'] ?? 0,
        commentsCount: result['comments_count'] ?? 0,
        createdAt: DateTime.parse(result['created_at']),
        updatedAt: DateTime.parse(result['updated_at'] ?? result['created_at']),
      );
    } catch (e) {
      print('❌ getPostById error: $e');
      rethrow;
    }
  }

  // 게시글 생성
  Future<CommunityPostEntity> createPost({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    String category = '자유',
  }) async {
    try {
      final result = await client
          .from('community_posts')
          .insert({
            'title': title,
            'content': content,
            'author_id': authorId,
            'author_name': authorName,
            'category': category,
            'likes_count': 0,
            'comments_count': 0,
          })
          .select()
          .single();

      return CommunityPostEntity(
        id: result['id'],
        title: result['title'],
        content: result['content'],
        authorId: result['author_id'],
        authorName: result['author_name'],
        category: result['category'] ?? '자유',
        likesCount: result['likes_count'] ?? 0,
        commentsCount: result['comments_count'] ?? 0,
        createdAt: DateTime.parse(result['created_at']),
        updatedAt: DateTime.parse(result['updated_at'] ?? result['created_at']),
      );
    } catch (e) {
      print('❌ createPost error: $e');
      rethrow;
    }
  }

  // 게시글 수정
  Future<CommunityPostEntity> updatePost({
    required String postId,
    String? title,
    String? content,
    String? category,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (category != null) updateData['category'] = category;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final result = await client
          .from('community_posts')
          .update(updateData)
          .match({'id': postId})
          .select()
          .single();

      return CommunityPostEntity(
        id: result['id'],
        title: result['title'],
        content: result['content'],
        authorId: result['author_id'],
        authorName: result['author_name'],
        category: result['category'] ?? '자유',
        likesCount: result['likes_count'] ?? 0,
        commentsCount: result['comments_count'] ?? 0,
        createdAt: DateTime.parse(result['created_at']),
        updatedAt: DateTime.parse(result['updated_at'] ?? result['created_at']),
      );
    } catch (e) {
      print('❌ updatePost error: $e');
      rethrow;
    }
  }

  // 게시글 삭제
  Future<bool> deletePost(String postId) async {
    try {
      await client.from('community_posts').delete().match({'id': postId});
      return true;
    } catch (e) {
      print('❌ deletePost error: $e');
      return false;
    }
  }

  // 댓글 목록 조회
  Future<List<CommentEntity>> getComments(String postId) async {
    try {
      final result = await client
          .from('community_comments')
          .select()
          .match({'post_id': postId})
          .order('created_at', ascending: true);

      return (result as List).map<CommentEntity>((item) {
        return CommentEntity(
          id: item['id'],
          postId: item['post_id'],
          authorId: item['author_id'],
          authorName: item['author_name'],
          content: item['content'],
          createdAt: DateTime.parse(item['created_at']),
        );
      }).toList();
    } catch (e) {
      print('❌ getComments error: $e');
      rethrow;
    }
  }

  // 댓글 추가
  Future<CommentEntity> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    try {
      final result = await client
          .from('community_comments')
          .insert({
            'post_id': postId,
            'author_id': authorId,
            'author_name': authorName,
            'content': content,
          })
          .select()
          .single();

      // 댓글 수 증가 (직접 계산)
      final comments = await client.from('community_comments').select('id').match({
        'post_id': postId,
      });

      await client
          .from('community_posts')
          .update({'comments_count': (comments as List).length})
          .match({'id': postId});

      return CommentEntity(
        id: result['id'],
        postId: result['post_id'],
        authorId: result['author_id'],
        authorName: result['author_name'],
        content: result['content'],
        createdAt: DateTime.parse(result['created_at']),
      );
    } catch (e) {
      print('❌ addComment error: $e');
      rethrow;
    }
  }

  // 댓글 삭제
  Future<bool> deleteComment(String commentId) async {
    try {
      await client.from('community_comments').delete().match({'id': commentId});
      return true;
    } catch (e) {
      print('❌ deleteComment error: $e');
      return false;
    }
  }

  // 좋아요 토글
  Future<bool> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      // 이미 좋아요가 있는지 확인
      final existingLike = await client.from('community_post_likes').select().match({
        'post_id': postId,
        'user_id': userId,
      }).maybeSingle();

      if (existingLike != null) {
        // 좋아요 취소
        await client.from('community_post_likes').delete().match({
          'post_id': postId,
          'user_id': userId,
        });

        // 좋아요 수 감소 (직접 계산)
        final likesCount = await client.from('community_post_likes').select('id').match({
          'post_id': postId,
        });

        await client
            .from('community_posts')
            .update({'likes_count': (likesCount as List).length})
            .match({'id': postId});

        return false; // 좋아요 취소됨
      } else {
        // 좋아요 추가
        await client.from('community_post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });

        // 좋아요 수 증가 (직접 계산)
        final likesCount = await client.from('community_post_likes').select('id').match({
          'post_id': postId,
        });

        await client
            .from('community_posts')
            .update({'likes_count': (likesCount as List).length})
            .match({'id': postId});

        return true; // 좋아요 추가됨
      }
    } catch (e) {
      print('❌ toggleLike error: $e');
      rethrow;
    }
  }

  // 사용자가 좋아요를 눌렀는지 확인
  Future<bool> isLiked({required String postId, required String userId}) async {
    try {
      final result = await client.from('community_post_likes').select().match({
        'post_id': postId,
        'user_id': userId,
      }).maybeSingle();

      return result != null;
    } catch (e) {
      print('❌ isLiked error: $e');
      return false;
    }
  }
}
