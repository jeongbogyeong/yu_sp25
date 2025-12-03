import '../entities/comment_entity.dart';
import '../repositories/community_repository.dart';

class GetCommentsUseCase {
  final CommunityRepository repository;

  GetCommentsUseCase(this.repository);

  Future<List<CommentEntity>> call(String postId) async {
    return await repository.getComments(postId);
  }
}

