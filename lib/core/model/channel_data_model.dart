import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instaflutter/core/model/chat_feed_model.dart';
import 'package:instaflutter/core/model/user.dart';

class ChannelDataModel {
  String channelID;
  String creatorID;
  String id;
  int lastMessageDate;
  String lastMessageSenderId;
  String lastThreadMessageId;
  String name;
  dynamic lastMessage;
  List<ChatFeedParticipantProfilePictureURL> participantProfilePictureURLs;
  List<User> participants;
  List<String> readUserIDs;
  List<String>? admins;
  bool isGroupChat;

  ChannelDataModel({
    this.channelID = '',
    this.creatorID = '',
    this.id = '',
    this.lastMessage,
    this.lastMessageDate = 0,
    this.lastMessageSenderId = '',
    this.lastThreadMessageId = '',
    name,
    this.participantProfilePictureURLs = const [],
    this.participants = const [],
    readUserIDs,
    this.admins,
  })  : readUserIDs = readUserIDs ?? [],
        name = !channelID.contains(creatorID) || channelID.isNotEmpty
            ? name ?? ''
            : participants.first.fullName(),
        isGroupChat = (participants).length > 1;

  factory ChannelDataModel.fromJson(
      Map<String, dynamic> parsedJson, String currentUserID) {
    return ChannelDataModel(
      channelID: parsedJson['id'] ?? '',
      creatorID: parsedJson['creatorID'] ?? '',
      id: parsedJson['id'] ?? '',
      lastMessage: (parsedJson['lastMessage'] ?? '') is String
          ? parsedJson['lastMessage'] ?? ''
          : ChatFeedContent.fromJson(parsedJson['lastMessage'] ?? {}),
      lastMessageDate: (parsedJson['lastMessageDate'] ?? 0) is Timestamp
          ? (parsedJson['lastMessageDate'] as Timestamp).seconds
          : 0,
      lastMessageSenderId: parsedJson['lastMessageSenderId'] ?? '',
      lastThreadMessageId: parsedJson['lastThreadMessageId'] ?? '',
      name: parsedJson['name'] ?? '',
      participantProfilePictureURLs:
          ((parsedJson['participantProfilePictureURLs'] ?? []) as Iterable)
              .map((e) => ChatFeedParticipantProfilePictureURL.fromJson(e))
              .toList(),
      participants: ((parsedJson['participants'] ?? []) as Iterable)
          .map((e) => User.fromJson(e))
          .toList()
        ..removeWhere((element) => element.userID == currentUserID),
      readUserIDs: List<String>.from(parsedJson['readUserIDs'] ?? []),
      admins: parsedJson.containsKey('admins') && parsedJson['admins'] != null
          ? List<String>.from(parsedJson['admins'])
          : null,
    );
  }

  Map<String, dynamic> toJson(User currentUser) {
    List<User>? fullParticipants;
    if (participants
        .where((element) => element.userID == currentUser.userID)
        .isEmpty) {
      fullParticipants = [...participants, currentUser];
    }
    return {
      'channelID': channelID,
      'creatorID': creatorID,
      'id': id,
      'lastMessage': lastMessage is ChatFeedContent
          ? (lastMessage as ChatFeedContent).toJson()
          : lastMessage,
      'lastMessageDate': lastMessageDate,
      'lastMessageSenderId': lastMessageSenderId,
      'lastThreadMessageId': lastThreadMessageId,
      'name': name,
      'participantProfilePictureURLs':
          participantProfilePictureURLs.map((e) => e.toJson()).toList(),
      'participants': fullParticipants?.map((e) => e.toJson()).toList() ??
          participants.map((e) => e.toJson()).toList(),
      'readUserIDs': readUserIDs,
      'admins': admins,
    };
  }
}
