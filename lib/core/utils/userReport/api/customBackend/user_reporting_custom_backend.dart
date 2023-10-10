import 'package:instaflutter/core/model/user.dart';
import 'package:instaflutter/core/utils/userReport/api/user_report_repository.dart';

class UserReportingCustomBackend extends UserReportRepository {
  @override
  Future<bool> markAbuse(
      {required String destUserID,
      required String abuseType,
      required String sourceUserID}) {
    // TODO: implement markAbuse
    throw UnimplementedError();
  }

  @override
  Future<bool> unblockUser(
      {required String destUserID, required String sourceUserID}) {
    // TODO: implement unblockUser
    throw UnimplementedError();
  }

  @override
  Future<List<User>> fetchBlockedUsers(
      {required String userID, required int page, required int size}) {
    // TODO: implement fetchBlockedUsers
    throw UnimplementedError();
  }

  @override
  Future<List<User>> listenToBlockedUsers({required String userID}) {
    // TODO: implement listenToBlockedUsers
    throw UnimplementedError();
  }
}
