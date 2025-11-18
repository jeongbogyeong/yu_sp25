import '../../domain/repositories/community_repository.dart';

class DeleteCommentUseCase {
  final CommunityRepository repository;

  DeleteCommentUseCase(this.repository);

  Future<bool> call(String commentId) async {
    return await repository.deleteComment(commentId);
  }
}

