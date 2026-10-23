import 'package:flutter_test/flutter_test.dart';
import 'package:ecolearning_app/data/models/user.dart';
import 'package:ecolearning_app/data/repositories/profile_repository.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';

class Profile extends ProfileRepository {
  String saved = 'https://example.com/old.png';
  @override
  Future<String> uploadAvatar(String path) async =>
      'https://example.com/new.png';
  @override
  Future<User> me() async =>
      User(id: 'u', fullName: 'Ngọc', email: '', avatarUrl: saved);
}

void main() {
  test(
    'avatar upload rejects stale profile and accepts the server persisted URL',
    () async {
      final repo = Profile();
      await expectLater(
        repo.uploadAvatarAndReload('photo.png'),
        throwsA(isA<ApiException>()),
      );
      repo.saved = 'https://example.com/new.png';
      final updated = await repo.uploadAvatarAndReload('photo.png');
      expect(updated.avatarUrl, (await repo.me()).avatarUrl);
    },
  );
}
