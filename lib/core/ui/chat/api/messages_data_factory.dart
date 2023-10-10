import 'package:instaflutter/constants.dart';
import 'package:instaflutter/core/model/chat_feed_model.dart';

class MessagesDataFactory {
  List<ChatFeedContent> liveMessages = [];
  List<ChatFeedContent> historicalMessages = [];

  MessagesDataFactory({this.liveMessages = const [], historicalMessages})
      : historicalMessages = historicalMessages ?? [];

  set newLiveMessages(List<ChatFeedContent> value) {
    if (value.length == liveCollectionLimit) {
      historicalMessages.insertAll(0, liveMessages);
      historicalMessages.removeWhere((element) => value
          .where((liveElement) => liveElement.id == element.id)
          .isNotEmpty);
    }
    liveMessages = value;
  }

  appendHistoricalMessages(List<ChatFeedContent> value) {
    historicalMessages.removeWhere((element) =>
        value.where((liveElement) => liveElement.id == element.id).isNotEmpty);
    historicalMessages.addAll(value);
  }

  List<ChatFeedContent> getAllMessages() =>
      [...liveMessages + historicalMessages];
}
