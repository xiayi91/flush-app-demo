import 'dart:io';

import 'package:instaflutter/core/model/channel_data_model.dart';
import 'package:instaflutter/core/model/chat_feed_model.dart';
import 'package:instaflutter/core/model/media_container.dart';
import 'package:instaflutter/core/model/user.dart';

abstract class ChatRepository {
  /// A stream to this [homeConversationModel], should listen to the conversation model updates
  /// [currentUser] current logged in user
  Stream<List<ChatFeedContent>> listenToMessages({required String channelID});

  Future<List<ChatFeedContent>> fetchOldMessages(
      {required String channelID, required int page, required int size});

  /// Gets the user object by his userID [userID] field.
  /// Returns user object if found, and null if not found.
  Future<User?> getUserByID(String userID);

  /// Listens to new messages sent to conversations which this [userID] is member in
  Stream<List<ChatFeedModel>> listenToConversations({required String userID});

  Future<List<ChatFeedModel>> fetchConversations(
      {required String userID, required int page, required int size});

  /// removes conversations streams that are no longer needed
  cleanConversationStreams();

  /// Create a new channel between two or more users, using [channelDataModel].
  /// [currentUser] is the currently logged in user
  createChannel({
    required ChannelDataModel channelDataModel,
    required User currentUser,
  });

  /// Uploads image [image] to the server
  /// Returns [MediaContainer] model that contains the file url on the server.
  Future<MediaContainer> uploadChatImageToBackend(File image);

  /// Sends a new [message] to [channelID],
  sendMessage({
    required ChannelDataModel channelDataModel,
    required ChatFeedContent message,
    required User currentUser,
  });

  /// Uploads video [video] to the server
  /// Returns [MediaContainer] model that contains the file url on the server and url for the video thumbnail.
  Future<MediaContainer> uploadChatVideoToBackend(File video);

  /// Uploads audio [file] to the server
  /// Returns [MediaContainer] model that contains the file url on the server.
  Future<MediaContainer> uploadAudioFileToBackend(File file);

  /// removes chat streams that are no longer needed
  cleanChatStreams();

  /// Returns [ChannelDataModel] by [channelID],
  /// [channelParticipant] is the other user in the chat
  /// [currentUserID] is our currently logged in user ID
  /// Returns null if it doesn't exist
  Future<ChannelDataModel> getChannelById(
      String channelID, List<User> channelParticipants, String currentUserID);

  /// listens to [channelDataModel] changes in the database
  /// [currentUserID] is our currently logged in user ID
  /// returns a stream of [ChannelDataModel] which is triggered whenever the channel is updated
  Stream<ChannelDataModel> listenToChannelChanges({
    required ChannelDataModel channelDataModel,
    required String currentUserID,
  });

  /// listens to chat members user objects changes
  /// to update the ui accordingly, such as the last seen and active indicator dot
  /// [channelDataModel] channel of the chat
  /// [currentUserID] is our currently logged in user ID
  /// returns a stream of the updated user
  Stream<User> listenToChatParticipants({
    required ChannelDataModel channelDataModel,
    required String currentUserID,
  });

  markAsRead(
      {required String channelID,
      required String currentUserID,
      required String messageID,
      required List<String> readUserIDs});
}
