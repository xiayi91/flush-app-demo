import 'dart:async';
import 'dart:io';

import 'package:instaflutter/core/model/channel_data_model.dart';
import 'package:instaflutter/core/model/chat_feed_model.dart';
import 'package:instaflutter/core/model/media_container.dart';
import 'package:instaflutter/core/model/user.dart';
import 'package:instaflutter/core/ui/chat/api/chat_repository.dart';

class ChatLocalData extends ChatRepository {
  @override
  cleanChatStreams() {
    // TODO: implement cleanChatStreams
    throw UnimplementedError();
  }

  @override
  cleanConversationStreams() {
    // TODO: implement cleanConversationStreams
    throw UnimplementedError();
  }

  @override
  Future<User?> getUserByID(String userID) {
    // TODO: implement getUserByID
    throw UnimplementedError();
  }

  @override
  Future<MediaContainer> uploadAudioFileToBackend(File file) {
    // TODO: implement uploadAudioFileToBackend
    throw UnimplementedError();
  }

  @override
  Future<MediaContainer> uploadChatImageToBackend(File image) {
    // TODO: implement uploadChatImageToBackend
    throw UnimplementedError();
  }

  @override
  Future<MediaContainer> uploadChatVideoToBackend(File video) {
    // TODO: implement uploadChatVideoToBackend
    throw UnimplementedError();
  }

  @override
  Stream<List<ChatFeedModel>> listenToConversations({required String userID}) {
    // TODO: implement listenToConversations
    throw UnimplementedError();
  }

  @override
  Future<List<ChatFeedModel>> fetchConversations(
      {required String userID, required int page, required int size}) {
    // TODO: implement fetchConversations
    throw UnimplementedError();
  }

  @override
  Future<ChannelDataModel> getChannelById(
      String channelID, List<User> channelParticipants, String currentUserID) {
    // TODO: implement getChannelByIdOrNull
    throw UnimplementedError();
  }

  @override
  Future<List<ChatFeedContent>> fetchOldMessages(
      {required String channelID, required int page, required int size}) {
    // TODO: implement fetchOldMessages
    throw UnimplementedError();
  }

  @override
  Stream<List<ChatFeedContent>> listenToMessages({required String channelID}) {
    // TODO: implement listenToMessages
    throw UnimplementedError();
  }

  @override
  createChannel(
      {required ChannelDataModel channelDataModel, required User currentUser}) {
    // TODO: implement createChannel
    throw UnimplementedError();
  }

  @override
  sendMessage(
      {required ChannelDataModel channelDataModel,
      required ChatFeedContent message,
      required User currentUser}) {
    // TODO: implement sendMessage
    throw UnimplementedError();
  }

  @override
  Stream<ChannelDataModel> listenToChannelChanges({
    required ChannelDataModel channelDataModel,
    required String currentUserID,
  }) {
    // TODO: implement listenToChannelChanges
    throw UnimplementedError();
  }

  @override
  Stream<User> listenToChatParticipants({
    required ChannelDataModel channelDataModel,
    required String currentUserID,
  }) {
    // TODO: implement listenToChatParticipants
    throw UnimplementedError();
  }

  @override
  markAsRead(
      {required String channelID,
      required String currentUserID,
      required String messageID,
      required List<String> readUserIDs}) {
    // TODO: implement markAsRead
    throw UnimplementedError();
  }
}
