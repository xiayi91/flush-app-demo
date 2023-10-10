part of 'chat_bloc.dart';

const cameraMediaSource = 'camera';
const galleryMediaSource = 'gallery';

enum RecordingState { hidden, visible, recording }

abstract class ChatEvent {}

class TextUpdateEvent extends ChatEvent {
  bool isTextEmpty;

  TextUpdateEvent({required this.isTextEmpty});
}

class UpdateAppBarEvent extends ChatEvent {
  ChannelDataModel channelDataModel;

  UpdateAppBarEvent({required this.channelDataModel});
}

class SendTextMessageEvent extends ChatEvent {
  String messageContent;

  SendTextMessageEvent({required this.messageContent});
}

class SendImageMessageEvent extends ChatEvent {
  File image;

  SendImageMessageEvent({required this.image});
}

class SendVideoMessageEvent extends ChatEvent {
  File video;

  SendVideoMessageEvent({required this.video});
}

class SendAudioMessageEvent extends ChatEvent {}

class SetupChatListeners extends ChatEvent {
  ChannelDataModel channelDataModel;

  SetupChatListeners({required this.channelDataModel});
}

class AddMediaToChatEvent extends ChatEvent {
  String mediaType;
  String mediaSource;

  AddMediaToChatEvent({required this.mediaType, required this.mediaSource});
}

class MicClickedEvent extends ChatEvent {
  RecordingState recordingState;

  MicClickedEvent({required this.recordingState});
}

class StartRecordingEvent extends ChatEvent {}

class RecordTickEvent extends ChatEvent {
  int tick;

  RecordTickEvent(this.tick);
}

class RecordCancelEvent extends ChatEvent {}

class BlockUserEvent extends ChatEvent {
  User targetUser;
  String action;

  BlockUserEvent({
    required this.targetUser,
    required this.action,
  });
}

class FetchMessagesPageEvent extends ChatEvent {
  int page;
  int size;

  FetchMessagesPageEvent({required this.page, required this.size});
}

class MarkChatAsReadEvent extends ChatEvent {
  String channelID;
  String currentUserID;
  String messageID;
  List<String> readUserIDs;

  MarkChatAsReadEvent({
    required this.channelID,
    required this.currentUserID,
    required this.messageID,
    required this.readUserIDs,
  });
}
