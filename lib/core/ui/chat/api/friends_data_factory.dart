import 'package:instaflutter/core/model/user.dart';

class FriendsDataFactory {
  List<User> liveFriends = [];
  List<User> historicalFriends = [];

  FriendsDataFactory({this.liveFriends = const [], historicalFriends})
      : historicalFriends = historicalFriends ?? [];

  set newLiveFriends(List<User> value) {
    historicalFriends.removeWhere((element) => value
        .where((liveElement) => liveElement.userID == element.userID)
        .isNotEmpty);
    liveFriends = value;
  }

  appendHistoricalFriends(List<User> value) {
    historicalFriends.removeWhere((element) => value
        .where((liveElement) => liveElement.userID == element.userID)
        .isNotEmpty);
    historicalFriends.addAll(value);
  }

  List<User> getAllFriends() => [...liveFriends + historicalFriends];
}
