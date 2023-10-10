part of 'conversation_bloc.dart';

abstract class ConversationsEvent {}

class InitConversationsEvent extends ConversationsEvent {}

class FetchConversationsPageEvent extends ConversationsEvent {
  int page;
  int size;

  FetchConversationsPageEvent({required this.page, required this.size});
}

class FriendTapEvent extends ConversationsEvent {
  User friend;

  FriendTapEvent({required this.friend});
}

class FetchFriendByIDEvent extends ConversationsEvent {
  String friendID;

  FetchFriendByIDEvent({required this.friendID});
}

class SearchConversationsEvent extends ConversationsEvent {
  String query;
  List<ChatFeedModel> conversations;
  List<User> friends;

  SearchConversationsEvent(
      {required this.query,
      required this.conversations,
      required this.friends});
}
