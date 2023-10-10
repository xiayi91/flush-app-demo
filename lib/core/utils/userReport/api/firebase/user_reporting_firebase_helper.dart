import 'package:cloud_functions/cloud_functions.dart';
import 'package:instaflutter/core/model/user.dart';
import 'package:instaflutter/core/utils/userReport/api/user_report_repository.dart';

class UserReportingFireStoreUtils extends UserReportRepository {
  FirebaseFunctions functions = FirebaseFunctions.instance;

  @override
  Future<bool> markAbuse(
      {required String destUserID,
      required String abuseType,
      required String sourceUserID}) async {
    HttpsCallableResult result = await functions
        .httpsCallable('markAbuse')
        .call({
      'sourceUserID': sourceUserID,
      'destUserID': destUserID,
      'abuseType': abuseType
    });
    return result.data['success'] ?? false;
  }

  @override
  Future<bool> unblockUser(
      {required String destUserID, required String sourceUserID}) async {
    HttpsCallableResult result =
        await functions.httpsCallable('unblockUser').call({
      'sourceUserID': sourceUserID,
      'destUserID': destUserID,
    });
    return result.data['success'] ?? false;
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
