part of 'conversation_bloc.dart';

abstract class ConversationsState {}

class ConversationInitial extends ConversationsState {}

class FriendTapState extends ConversationsState {
  ChannelDataModel channelDataModel;

  FriendTapState({required this.channelDataModel});
}

class SearchConversationResultState extends ConversationsState {
  List<ChatFeedModel> conversationsQueryResult;
  List<User> friendsQueryResult;

  SearchConversationResultState(
      {required this.conversationsQueryResult,
      required this.friendsQueryResult});
}

class ConversationNewMessageState extends ConversationsState {
  List<ChatFeedModel> listOfConversations;

  ConversationNewMessageState({required this.listOfConversations});
}

class NewFriendsPageState extends ConversationsState {
  List<User> newPage;
  int oldPageKey;

  NewFriendsPageState({required this.newPage, required this.oldPageKey});
}

class UpdateLiveFriendsState extends ConversationsState {
  List<User> liveFriends;

  UpdateLiveFriendsState({required this.liveFriends});
}

class FriendsPageErrorState extends ConversationsState {
  dynamic error;

  FriendsPageErrorState({required this.error});
}

class NewConversationsPageState extends ConversationsState {
  List<ChatFeedModel> newPage;
  int oldPageKey;

  NewConversationsPageState({required this.newPage, required this.oldPageKey});
}

class UpdateLiveConversationsState extends ConversationsState {
  List<ChatFeedModel> liveConversations;

  UpdateLiveConversationsState({required this.liveConversations});
}

class ConversationsPageErrorState extends ConversationsState {
  dynamic error;

  ConversationsPageErrorState({required this.error});
}
