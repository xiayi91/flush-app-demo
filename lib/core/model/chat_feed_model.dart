import 'package:instaflutter/core/model/media_container.dart';
import 'package:instaflutter/core/model/user.dart';

class ChatFeedModel {
  ChatFeedContent chatFeedContent;
  int createdAt;
  String id;
  bool markedAsRead;
  List<User> participants;
  String title;
  bool isGroupChat;

  ChatFeedModel({
    chatFeedContent,
    this.createdAt = 0,
    this.id = '',
    this.markedAsRead = false,
    this.participants = const [],
    this.title = '',
  })  : chatFeedContent = chatFeedContent ?? ChatFeedContent(),
        isGroupChat = participants.length > 1;

  factory ChatFeedModel.fromJson(
      Map<String, dynamic> parsedJson, String currentUserID) {
    return ChatFeedModel(
      chatFeedContent: parsedJson.containsKey('content')
          ? parsedJson['content'] is String
              ? ChatFeedContent(content: parsedJson['content'])
              : ChatFeedContent.fromJson(
                  Map<String, dynamic>.from(parsedJson['content'] ?? {}))
          : ChatFeedContent(),
      createdAt: parsedJson['createdAt'] ?? 0,
      id: parsedJson['id'] ?? '',
      markedAsRead: parsedJson['markedAsRead'] ?? false,
      participants: ((parsedJson['participants'] ?? []) as Iterable)
          .map((e) => User.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..removeWhere((element) => element.userID == currentUserID),
      title: parsedJson['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': chatFeedContent.toJson(),
      'createdAt': createdAt,
      'id': id,
      'markedAsRead': markedAsRead,
      'participants': participants.map((e) => e.toJson()).toList(),
      'title': title,
    };
  }
}

class ChatFeedContent {
  String content;
  int createdAt;
  String id;
  List<ChatFeedParticipantProfilePictureURL> participantProfilePictureURLs;
  List<dynamic> readUserIDs;
  String recipientID;
  String recipientFirstName;
  String recipientLastName;
  String recipientProfilePictureURL;
  String senderID;
  String senderFirstName;
  String senderLastName;
  String senderProfilePictureURL;
  MediaContainer? chatMedia;

  ChatFeedContent({
    this.content = '',
    this.createdAt = 0,
    this.id = '',
    this.participantProfilePictureURLs = const [],
    this.readUserIDs = const [],
    this.recipientID = '',
    this.recipientFirstName = '',
    this.recipientLastName = '',
    this.recipientProfilePictureURL = '',
    this.senderID = '',
    this.senderFirstName = '',
    this.senderLastName = '',
    this.senderProfilePictureURL = '',
    this.chatMedia,
  });

  factory ChatFeedContent.fromJson(Map<String, dynamic> parsedJson) {
    List<ChatFeedParticipantProfilePictureURL> participantProfilePictureURLs =
        [];
    List<dynamic> jsonList = parsedJson['participantProfilePictureURLs'] ?? [];
    for (var item in jsonList) {
      ChatFeedParticipantProfilePictureURL modelItem =
          ChatFeedParticipantProfilePictureURL.fromJson(
              Map<String, dynamic>.from(item));
      participantProfilePictureURLs.add(modelItem);
    }

    return ChatFeedContent(
      content: parsedJson['content'] ?? '',
      createdAt: parsedJson['createdAt'] ?? 0,
      id: parsedJson['id'] ?? '',
      participantProfilePictureURLs: participantProfilePictureURLs,
      readUserIDs: (parsedJson['readUserIDs'] ?? []).cast<String>(),
      recipientID: parsedJson['recipientID'] ?? '',
      recipientFirstName: parsedJson['recipientFirstName'] ?? '',
      recipientLastName: parsedJson['recipientLastName'] ?? '',
      recipientProfilePictureURL:
          parsedJson['recipientProfilePictureURL'] ?? '',
      senderID: parsedJson['senderID'] ?? '',
      senderFirstName: parsedJson['senderFirstName'] ?? '',
      senderLastName: parsedJson['senderLastName'] ?? '',
      senderProfilePictureURL: parsedJson['senderProfilePictureURL'] ?? '',
      chatMedia: parsedJson.containsKey('url') && parsedJson['url'] != null
          ? MediaContainer.fromJson(
              Map<String, dynamic>.from(parsedJson['url']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'createdAt': createdAt,
      'id': id,
      'participantProfilePictureURLs':
          participantProfilePictureURLs.map((e) => e.toJson()).toList(),
      'readUserIDs': readUserIDs,
      'recipientID': recipientID,
      'recipientFirstName': recipientFirstName,
      'recipientLastName': recipientLastName,
      'recipientProfilePictureURL': recipientProfilePictureURL,
      'senderID': senderID,
      'senderFirstName': senderFirstName,
      'senderLastName': senderLastName,
      'senderProfilePictureURL': senderProfilePictureURL,
      'url': chatMedia?.toJson(),
    };
  }
}

class ChatFeedParticipantProfilePictureURL {
  String participantId;
  String profilePictureURL;

  ChatFeedParticipantProfilePictureURL(
      {this.participantId = '', this.profilePictureURL = ''});

  factory ChatFeedParticipantProfilePictureURL.fromJson(
      Map<String, dynamic> parsedJson) {
    return ChatFeedParticipantProfilePictureURL(
        participantId: parsedJson['participantId'] ?? '',
        profilePictureURL: parsedJson['profilePictureURL'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'participantId': participantId,
      'profilePictureURL': profilePictureURL
    };
  }
}
