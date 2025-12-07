import 'package:flutter/foundation.dart';
import '../../domain/entities/community_post_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/usecases/get_community_posts_usecase.dart';
import '../../domain/usecases/get_post_detail_usecase.dart';
import '../../domain/usecases/create_post_usecase.dart';
import '../../domain/usecases/update_post_usecase.dart';
import '../../domain/usecases/delete_post_usecase.dart';
import '../../domain/usecases/get_comments_usecase.dart';
import '../../domain/usecases/add_comment_usecase.dart';
import '../../domain/usecases/delete_comment_usecase.dart';
import '../../domain/usecases/toggle_like_usecase.dart';
import '../../domain/usecases/is_liked_usecase.dart';

class CommunityViewModel with ChangeNotifier {
  // UseCases
  final GetCommunityPostsUseCase getCommunityPostsUseCase;
  final GetPostDetailUseCase getPostDetailUseCase;
  final CreatePostUseCase createPostUseCase;
  final UpdatePostUseCase updatePostUseCase;
  final DeletePostUseCase deletePostUseCase;
  final GetCommentsUseCase getCommentsUseCase;
  final AddCommentUseCase addCommentUseCase;
  final DeleteCommentUseCase deleteCommentUseCase;
  final ToggleLikeUseCase toggleLikeUseCase;
  final IsLikedUseCase isLikedUseCase;

  CommunityViewModel({
    required this.getCommunityPostsUseCase,
    required this.getPostDetailUseCase,
    required this.createPostUseCase,
    required this.updatePostUseCase,
    required this.deletePostUseCase,
    required this.getCommentsUseCase,
    required this.addCommentUseCase,
    required this.deleteCommentUseCase,
    required this.toggleLikeUseCase,
    required this.isLikedUseCase,
  });

  // 상태 변수들
  bool _isLoading = false;
  String? _errorMessage;
  List<CommunityPostEntity> _posts = [];
  CommunityPostEntity? _selectedPost;
  List<CommentEntity> _comments = [];
  Map<String, bool> _likedPosts = {}; // postId -> isLiked

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<CommunityPostEntity> get posts => _posts;
  CommunityPostEntity? get selectedPost => _selectedPost;
  List<CommentEntity> get comments => _comments;
  bool isPostLiked(String postId) => _likedPosts[postId] ?? false;

  // ==================================================
  // 게시글 목록 불러오기
  // ==================================================
  Future<void> loadPosts({
    int? limit,
    int? offset,
    String? category,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await getCommunityPostsUseCase.call(
        limit: limit,
        offset: offset,
        category: category,
      );
      
      // 각 게시글의 좋아요 상태 확인
      for (var post in _posts) {
        await _checkLikeStatus(post.id);
      }
    } catch (e) {
      _errorMessage = "게시글을 불러오는 중 오류가 발생했습니다: $e";
      print('❌ loadPosts error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================
  // 게시글 상세 불러오기
  // ==================================================
  Future<void> loadPostDetail(String postId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedPost = await getPostDetailUseCase.call(postId);
      
      if (_selectedPost != null) {
        // 댓글도 함께 불러오기
        await loadComments(postId);
        // 좋아요 상태 확인
        await _checkLikeStatus(postId);
      }
    } catch (e) {
      _errorMessage = "게시글을 불러오는 중 오류가 발생했습니다: $e";
      print('❌ loadPostDetail error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================
  // 게시글 작성
  // ==================================================
  Future<bool> createPost({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    String category = '자유',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newPost = await createPostUseCase.call(
        title: title,
        content: content,
        authorId: authorId,
        authorName: authorName,
        category: category,
      );
      
      // 새 게시글을 목록 맨 앞에 추가
      _posts.insert(0, newPost);
      return true;
    } catch (e) {
      _errorMessage = "게시글 작성 중 오류가 발생했습니다: $e";
      print('❌ createPost error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================
  // 게시글 수정
  // ==================================================
  Future<bool> updatePost({
    required String postId,
    String? title,
    String? content,
    String? category,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedPost = await updatePostUseCase.call(
        postId: postId,
        title: title,
        content: content,
        category: category,
      );
      
      // 목록에서 해당 게시글 찾아서 업데이트
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = updatedPost;
      }
      
      // 선택된 게시글도 업데이트
      if (_selectedPost?.id == postId) {
        _selectedPost = updatedPost;
      }
      
      return true;
    } catch (e) {
      _errorMessage = "게시글 수정 중 오류가 발생했습니다: $e";
      print('❌ updatePost error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================
  // 게시글 삭제
  // ==================================================
  Future<bool> deletePost(String postId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await deletePostUseCase.call(postId);
      
      if (success) {
        // 목록에서 제거
        _posts.removeWhere((p) => p.id == postId);
        
        // 선택된 게시글이면 초기화
        if (_selectedPost?.id == postId) {
          _selectedPost = null;
          _comments = [];
        }
        
        // 좋아요 상태도 제거
        _likedPosts.remove(postId);
      }
      
      return success;
    } catch (e) {
      _errorMessage = "게시글 삭제 중 오류가 발생했습니다: $e";
      print('❌ deletePost error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================
  // 댓글 목록 불러오기
  // ==================================================
  Future<void> loadComments(String postId) async {
    try {
      _comments = await getCommentsUseCase.call(postId);
      notifyListeners();
    } catch (e) {
      _errorMessage = "댓글을 불러오는 중 오류가 발생했습니다: $e";
      print('❌ loadComments error: $e');
      notifyListeners();
    }
  }

  // ==================================================
  // 댓글 추가
  // ==================================================
  Future<bool> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    try {
      final newComment = await addCommentUseCase.call(
        postId: postId,
        authorId: authorId,
        authorName: authorName,
        content: content,
      );
      
      // 댓글 목록에 추가
      _comments.add(newComment);
      
      // 게시글의 댓글 수 업데이트
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        _posts[postIndex] = CommunityPostEntity(
          id: post.id,
          title: post.title,
          content: post.content,
          authorId: post.authorId,
          authorName: post.authorName,
          category: post.category,
          likesCount: post.likesCount,
          commentsCount: post.commentsCount + 1,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
        );
      }
      
      // 선택된 게시글도 업데이트
      if (_selectedPost?.id == postId) {
        final post = _selectedPost!;
        _selectedPost = CommunityPostEntity(
          id: post.id,
          title: post.title,
          content: post.content,
          authorId: post.authorId,
          authorName: post.authorName,
          category: post.category,
          likesCount: post.likesCount,
          commentsCount: post.commentsCount + 1,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
        );
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "댓글 작성 중 오류가 발생했습니다: $e";
      print('❌ addComment error: $e');
      notifyListeners();
      return false;
    }
  }

  // ==================================================
  // 댓글 삭제
  // ==================================================
  Future<bool> deleteComment(String commentId) async {
    try {
      final success = await deleteCommentUseCase.call(commentId);
      
      if (success) {
        // 댓글 목록에서 제거
        _comments.removeWhere((c) => c.id == commentId);
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _errorMessage = "댓글 삭제 중 오류가 발생했습니다: $e";
      print('❌ deleteComment error: $e');
      notifyListeners();
      return false;
    }
  }

  // ==================================================
  // 좋아요 토글
  // ==================================================
  Future<bool> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      final isLiked = await toggleLikeUseCase.call(
        postId: postId,
        userId: userId,
      );
      
      // 좋아요 상태 업데이트
      _likedPosts[postId] = isLiked;
      
      // 게시글의 좋아요 수 업데이트
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        _posts[postIndex] = CommunityPostEntity(
          id: post.id,
          title: post.title,
          content: post.content,
          authorId: post.authorId,
          authorName: post.authorName,
          category: post.category,
          likesCount: isLiked ? post.likesCount + 1 : post.likesCount - 1,
          commentsCount: post.commentsCount,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
        );
      }
      
      // 선택된 게시글도 업데이트
      if (_selectedPost?.id == postId) {
        final post = _selectedPost!;
        _selectedPost = CommunityPostEntity(
          id: post.id,
          title: post.title,
          content: post.content,
          authorId: post.authorId,
          authorName: post.authorName,
          category: post.category,
          likesCount: isLiked ? post.likesCount + 1 : post.likesCount - 1,
          commentsCount: post.commentsCount,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
        );
      }
      
      notifyListeners();
      return isLiked;
    } catch (e) {
      _errorMessage = "좋아요 처리 중 오류가 발생했습니다: $e";
      print('❌ toggleLike error: $e');
      notifyListeners();
      return false;
    }
  }

  // ==================================================
  // 좋아요 상태 확인 (내부 메서드)
  // ==================================================
  Future<void> _checkLikeStatus(String postId) async {
    try {
      // 현재 사용자 ID는 나중에 UserViewModel에서 가져올 수 있음
      // 일단 기본값으로 처리
      final isLiked = await isLikedUseCase.call(
        postId: postId,
        userId: '', // TODO: 실제 사용자 ID로 교체 필요
      );
      _likedPosts[postId] = isLiked;
    } catch (e) {
      // 에러가 나도 계속 진행
      _likedPosts[postId] = false;
    }
  }

  // ==================================================
  // 상태 초기화
  // ==================================================
  void clearSelectedPost() {
    _selectedPost = null;
    _comments = [];
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}


