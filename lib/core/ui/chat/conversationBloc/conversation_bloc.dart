// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:instaflutter/core/model/channel_data_model.dart';
import 'package:instaflutter/core/model/chat_feed_model.dart';
import 'package:instaflutter/core/model/user.dart';
import 'package:instaflutter/core/ui/chat/api/chat_repository.dart';

part 'conversation_event.dart';

part 'conversation_state.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final ChatRepository chatRepository;
  final User currentUser;
  StreamSubscription? friendsStreamSub, conversationsStreamSub;

  ConversationsBloc({
    required this.chatRepository,
    required this.currentUser,
  }) : super(ConversationInitial()) {
    on<FetchConversationsPageEvent>((event, emit) async {
      try {
        if (event.page == -1) {
          conversationsStreamSub = chatRepository
              .listenToConversations(userID: currentUser.userID)
              .listen((listOfLiveConversations) {
            updateLiveConversations(listOfLiveConversations);
          });
        } else {
          List<ChatFeedModel> newConversationsPage =
              await chatRepository.fetchConversations(
                  userID: currentUser.userID,
                  page: event.page,
                  size: event.size);
          emit(NewConversationsPageState(
              newPage: newConversationsPage, oldPageKey: event.page));
        }
      } catch (e, s) {
        debugPrint('ConversationsBloc.ConversationsBloc $e $s');
        emit(ConversationsPageErrorState(error: e));
      }
    });

    on<SearchConversationsEvent>((event, emit) {
      if (event.query.isEmpty) {
        emit(SearchConversationResultState(
            conversationsQueryResult: [], friendsQueryResult: []));
      } else {
        List<User> friendsSearchResult = [];
        List<ChatFeedModel> conversationsSearchResult = [];

        for (var friend in event.friends) {
          if (friend
              .fullName()
              .toLowerCase()
              .contains(event.query.toLowerCase())) {
            friendsSearchResult.add(friend);
          }
        }

        for (var conversation in event.conversations) {
          if (conversation.title
              .toLowerCase()
              .contains(event.query.toLowerCase())) {
            conversationsSearchResult.add(conversation);
          }
        }
        emit(SearchConversationResultState(
            conversationsQueryResult: conversationsSearchResult,
            friendsQueryResult: friendsSearchResult));
      }
    });

    on<FriendTapEvent>((event, emit) async {
      String channelID;
      if (event.friend.userID.compareTo(currentUser.userID) < 0) {
        channelID = event.friend.userID + currentUser.userID;
      } else {
        channelID = currentUser.userID + event.friend.userID;
      }
      ChannelDataModel channelDataModel = await chatRepository.getChannelById(
          channelID, [event.friend], currentUser.userID);
      emit(FriendTapState(channelDataModel: channelDataModel));
    });
    on<FetchFriendByIDEvent>((event, emit) async {
      User? friend = await chatRepository.getUserByID(event.friendID);
      if (friend != null) {
        String channelID;
        if (friend.userID.compareTo(currentUser.userID) < 0) {
          channelID = friend.userID + currentUser.userID;
        } else {
          channelID = currentUser.userID + friend.userID;
        }
        ChannelDataModel channelDataModel = await chatRepository.getChannelById(
            channelID, [friend], currentUser.userID);
        emit(FriendTapState(channelDataModel: channelDataModel));
      }
    });
  }

  @override
  Future<void> close() async {
    chatRepository.cleanConversationStreams();
    // friendsStreamSub?.cancel();
    conversationsStreamSub?.cancel();
    super.close();
  }

  updateLiveFriends(List<User> listOfLiveFriends) =>
      emit(UpdateLiveFriendsState(liveFriends: listOfLiveFriends));

  updateLiveConversations(List<ChatFeedModel> listOfLiveConversations) => emit(
      UpdateLiveConversationsState(liveConversations: listOfLiveConversations));
}
