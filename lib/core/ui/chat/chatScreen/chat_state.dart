part of 'chat_bloc.dart';

const imageMediaType = 'image';
const videoMediaType = 'video';
const audioMediaType = 'audio';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class TextUpdateState extends ChatState {
  bool isTextEmpty;

  TextUpdateState({required this.isTextEmpty});
}

class UpdateAppBarState extends ChatState {
  String appBarTitle;

  UpdateAppBarState({required this.appBarTitle});
}

class RestartStream extends ChatState {
  ChannelDataModel channelDataModel;

  RestartStream({required this.channelDataModel});
}

class MediaSelectedState extends ChatState {
  File mediaFile;
  String mediaType;

  MediaSelectedState({required this.mediaFile, required this.mediaType});
}

class ChatErrorState extends ChatState {
  String errorMessage;

  ChatErrorState({required this.errorMessage});
}

class MediaUploadDoneState extends ChatState {}

class RecordingViewVisibleState extends ChatState {}

class RecordingViewHiddenState extends ChatState {}

class RecordingAudioState extends ChatState {}

class RecordTimerUpdateState extends ChatState {
  String updatedAudioTime;

  RecordTimerUpdateState({required this.updatedAudioTime});
}

class RecordCancelState extends ChatState {}

class RecordSentState extends ChatState {}

class UserReportDoneState extends ChatState {
  String message;

  UserReportDoneState(this.message);
}

class MessagesPageErrorState extends ChatState {
  dynamic error;

  MessagesPageErrorState({required this.error});
}

class NewMessagesPageState extends ChatState {
  List<ChatFeedContent> newPage;
  int oldPageKey;

  NewMessagesPageState({required this.newPage, required this.oldPageKey});
}

class UpdateLiveMessagesState extends ChatState {
  List<ChatFeedContent> liveMessages;

  UpdateLiveMessagesState({required this.liveMessages});
}

class ChannelUpdatedStream extends ChatState {
  ChannelDataModel channelDataModel;

  ChannelUpdatedStream({required this.channelDataModel});
}

class ParticipantsUpdatedStream extends ChatState {
  User updatedUser;

  ParticipantsUpdatedStream({required this.updatedUser});
}
