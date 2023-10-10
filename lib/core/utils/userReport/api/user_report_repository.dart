import 'package:instaflutter/core/model/user.dart';

const blockUserAction = 'block';
const reportUserAction = 'report';

abstract class UserReportRepository {
  /// Block/Report user using his [destUserID], [abuseType] should be either 'report' or 'block'
  /// [sourceUserID] current user's id
  /// returns ture if [destUserID] was blocked/reported successfully, otherwise false.
  Future<bool> markAbuse({
    required String destUserID,
    required String abuseType,
    required String sourceUserID,
  });

  /// Unblock user by his [destUserID]
  /// [sourceUserID] current user's id
  /// returns ture if [destUserID] was unblocked successfully, otherwise false.
  Future<bool> unblockUser({
    required String destUserID,
    required String sourceUserID,
  });

  Future<List<User>> listenToBlockedUsers({required String userID});

  Future<List<User>> fetchBlockedUsers(
      {required String userID, required int page, required int size});
}
