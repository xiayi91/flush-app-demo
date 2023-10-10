import 'package:instaflutter/core/model/chat_feed_model.dart';

class ConversationsDataFactory {
  List<ChatFeedModel> liveConversations = [];
  List<ChatFeedModel> historicalConversations = [];

  ConversationsDataFactory(
      {this.liveConversations = const [], historicalConversations})
      : historicalConversations = historicalConversations ?? [];

  set newLiveConversations(List<ChatFeedModel> value) {
    historicalConversations.removeWhere((element) =>
        value.where((liveElement) => liveElement.id == element.id).isNotEmpty);
    liveConversations = value;
  }

  appendHistoricalConversations(List<ChatFeedModel> value) {
    historicalConversations.removeWhere((element) =>
        value.where((liveElement) => liveElement.id == element.id).isNotEmpty);
    historicalConversations.addAll(value);
  }

  List<ChatFeedModel> getAllConversations() => [
        ...liveConversations + historicalConversations
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
