import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/community_repository.dart';

class GetCommentsUseCase {
  final CommunityRepository repository;

  GetCommentsUseCase(this.repository);

  Future<List<CommentEntity>> call(String postId) async {
    return await repository.getComments(postId);
  }
}

