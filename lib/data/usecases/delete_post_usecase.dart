import '../../domain/repositories/community_repository.dart';

class DeletePostUseCase {
  final CommunityRepository repository;

  DeletePostUseCase(this.repository);

  Future<bool> call(String postId) async {
    return await repository.deletePost(postId);
  }
}

