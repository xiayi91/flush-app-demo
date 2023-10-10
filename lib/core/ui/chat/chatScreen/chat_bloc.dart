// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instaflutter/core/model/channel_data_model.dart';
import 'package:instaflutter/core/model/chat_feed_model.dart';
import 'package:instaflutter/core/model/media_container.dart';
import 'package:instaflutter/core/model/user.dart';
import 'package:instaflutter/core/ui/chat/api/chat_repository.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/core/utils/userReport/api/user_report_repository.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

part 'chat_event.dart';

part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  final User currentUser;
  final UserReportRepository userReportRepository;

  final ImagePicker _imagePicker = ImagePicker();
  FlutterSoundRecorder? recorder;
  ChannelDataModel channelDataModel;
  Timer? audioMessageTimer;
  String? tempPathForAudioMessages;
  StreamSubscription? messagesStreamSub;
  StreamSubscription? channelStreamSub;
  StreamSubscription? participantsStreamSub;
  List<ChatFeedContent> actualMessages = [];

  ChatBloc({
    required this.chatRepository,
    required this.currentUser,
    required this.channelDataModel,
    required this.userReportRepository,
  }) : super(ChatInitial()) {
    on<FetchMessagesPageEvent>((event, emit) async {
      try {
        if (event.page == -1) {
          if (channelDataModel.channelID.isNotEmpty) {
            messagesStreamSub = chatRepository
                .listenToMessages(channelID: channelDataModel.channelID)
                .listen((listOfLiveMessages) {
              updateLiveMessages(listOfLiveMessages);
            });
          } else {
            emit(UpdateLiveMessagesState(liveMessages: []));
          }
        } else {
          List<ChatFeedContent> newMessagesPage =
              await chatRepository.fetchOldMessages(
                  channelID: channelDataModel.channelID,
                  page: event.page,
                  size: event.size);
          emit(NewMessagesPageState(
              newPage: newMessagesPage, oldPageKey: event.page));
        }
      } catch (e, s) {
        debugPrint('ChatBloc.ChatBloc $e $s');
        emit(MessagesPageErrorState(error: e));
      }
    });
    on<SetupChatListeners>((event, emit) async {
      if (event.channelDataModel.isGroupChat) {
        channelStreamSub = chatRepository
            .listenToChannelChanges(
                channelDataModel: event.channelDataModel,
                currentUserID: currentUser.userID)
            .listen((newChannelDataModel) {
          channelDataModel = newChannelDataModel;
          updateChannel(newChannelDataModel);
        });
      }
      participantsStreamSub = chatRepository
          .listenToChatParticipants(
              channelDataModel: event.channelDataModel,
              currentUserID: currentUser.userID)
          .listen((updatedUser) {
        updateParticipants(updatedUser);
      });
    });

    on<UpdateAppBarEvent>((event, emit) {
      channelDataModel = event.channelDataModel;
      emit(UpdateAppBarState(appBarTitle: event.channelDataModel.name));
    });
    on<TextUpdateEvent>(
        (event, emit) => emit(TextUpdateState(isTextEmpty: event.isTextEmpty)));
    on<SendTextMessageEvent>((event, emit) async {
      await _sendMessage(event.messageContent, null);
    });

    on<AddMediaToChatEvent>((event, emit) async {
      XFile? mediaFile;
      if (event.mediaSource == galleryMediaSource) {
        if (event.mediaType == imageMediaType) {
          mediaFile = await _imagePicker.pickImage(source: ImageSource.gallery);
        } else if (event.mediaType == videoMediaType) {
          mediaFile = await _imagePicker.pickVideo(source: ImageSource.gallery);
        }
      } else if (event.mediaSource == cameraMediaSource) {
        if (event.mediaType == imageMediaType) {
          mediaFile = await _imagePicker.pickImage(source: ImageSource.camera);
        } else if (event.mediaType == videoMediaType) {
          mediaFile = await _imagePicker.pickVideo(source: ImageSource.camera);
        }
      }

      if (mediaFile != null) {
        emit(MediaSelectedState(
            mediaFile: File(mediaFile.path), mediaType: event.mediaType));
      }
    });

    on<SendImageMessageEvent>((event, emit) async {
      MediaContainer url =
          await chatRepository.uploadChatImageToBackend(event.image);
      updateProgress('Almost done...'.tr());
      await _sendMessage(
          '{} sent an image'.tr(args: [currentUser.firstName]), url);
      emit(MediaUploadDoneState());
    });

    on<SendVideoMessageEvent>((event, emit) async {
      MediaContainer videoContainer =
          await chatRepository.uploadChatVideoToBackend(event.video);
      updateProgress('Almost done...'.tr());
      await _sendMessage(
          '{} sent a video'.tr(args: [currentUser.firstName]), videoContainer);
      emit(MediaUploadDoneState());
    });

    on<SendAudioMessageEvent>((event, emit) async {
      await recorder?.stopRecorder();
      audioMessageTimer?.cancel();
      MediaContainer url = await chatRepository
          .uploadAudioFileToBackend(File(tempPathForAudioMessages ?? ''));
      await _sendMessage(
          '{} sent a voice record'.tr(args: [currentUser.firstName]), url);
      emit(RecordSentState());
    });

    on<MicClickedEvent>((event, emit) async {
      if (event.recordingState == RecordingState.hidden) {
        recorder =
            await FlutterSoundRecorder(logLevel: Level.off).openRecorder();
        Directory tempDir = await getTemporaryDirectory();
        var uniqueID = const Uuid().v4();
        tempPathForAudioMessages = '${tempDir.path}/$uniqueID';
        audioMessageTimer?.cancel();
        emit(RecordingViewVisibleState());
      } else if (event.recordingState == RecordingState.visible) {
        await recorder?.closeRecorder();
        recorder = null;
        audioMessageTimer?.cancel();
        emit(RecordingViewHiddenState());
      }
    });

    on<StartRecordingEvent>((event, emit) async {
      var status = await Permission.microphone.request();
      if (status == PermissionStatus.granted) {
        await recorder?.startRecorder(
            toFile: tempPathForAudioMessages, codec: Codec.defaultCodec);
        audioMessageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          add(RecordTickEvent(timer.tick));
        });

        emit(RecordingAudioState());
      }
    });
    on<RecordTickEvent>((event, emit) {
      emit(RecordTimerUpdateState(updatedAudioTime: updateTime(event.tick)));
    });
    on<RecordCancelEvent>((event, emit) async {
      await recorder?.stopRecorder();
      audioMessageTimer?.cancel();
      emit(RecordCancelState());
    });

    on<BlockUserEvent>((event, emit) async {
      bool isSuccessful = await userReportRepository.markAbuse(
          destUserID: event.targetUser.userID,
          abuseType: event.action,
          sourceUserID: currentUser.userID);
      if (isSuccessful) {
        emit(UserReportDoneState(
          event.action == reportUserAction
              ? '{} has been blocked.'.tr(args: [event.targetUser.fullName()])
              : '{} has been reported and blocked.'
                  .tr(args: [event.targetUser.fullName()]),
        ));
      } else {
        emit(ChatErrorState(
          errorMessage: event.action == reportUserAction
              ? 'Couldn\'t block {}, please try again later.'.tr(args: [
                  event.targetUser.fullName(),
                ])
              : 'Couldn\'t report {}, please try again later.'
                  .tr(args: [event.targetUser.fullName()]),
        ));
      }
    });
    on<MarkChatAsReadEvent>((event, emit) async {
      await chatRepository.markAsRead(
        channelID: event.channelID,
        currentUserID: event.currentUserID,
        messageID: event.messageID,
        readUserIDs: event.readUserIDs,
      );
    });
  }

  @override
  Future<void> close() async {
    await recorder?.closeRecorder();
    audioMessageTimer?.cancel();
    recorder = null;
    await messagesStreamSub?.cancel();
    await channelStreamSub?.cancel();
    await participantsStreamSub?.cancel();
    await chatRepository.cleanChatStreams();
    super.close();
  }

  _sendMessage(String content, MediaContainer? mediaContainer) async {
    if (channelDataModel.channelID.isEmpty) {
      await _createChatChannel();
    }

    ChatFeedContent message = ChatFeedContent(
      content: content,
      createdAt: Timestamp.now().seconds,
      senderID: currentUser.userID,
      senderFirstName: currentUser.firstName,
      senderLastName: currentUser.lastName,
      senderProfilePictureURL: currentUser.profilePictureURL,
      id: const Uuid().v4(),
      participantProfilePictureURLs: channelDataModel.participants
          .map(
            (e) => ChatFeedParticipantProfilePictureURL.fromJson({
              'profilePictureURL': e.profilePictureURL,
              'participantId': e.userID
            }),
          )
          .toList(),
      chatMedia: mediaContainer,
    );
    if (!channelDataModel.isGroupChat) {
      message.recipientID = channelDataModel.participants.first.userID;
      message.recipientFirstName =
          channelDataModel.participants.first.firstName;
      message.recipientLastName = channelDataModel.participants.first.lastName;
      message.recipientProfilePictureURL =
          channelDataModel.participants.first.profilePictureURL;
    }
    actualMessages.insert(0, message);
    updateLiveMessages(actualMessages);
    await chatRepository.sendMessage(
      message: message,
      channelDataModel: channelDataModel,
      currentUser: currentUser,
    );
  }

  _createChatChannel() async {
    String channelID;
    User friend = channelDataModel.participants.first;
    if (friend.userID.compareTo(currentUser.userID) < 0) {
      channelID = friend.userID + currentUser.userID;
    } else {
      channelID = currentUser.userID + friend.userID;
    }
    channelDataModel.channelID = channelID;
    channelDataModel.creatorID = currentUser.userID;
    channelDataModel.id = channelID;
    await chatRepository.createChannel(
      channelDataModel: channelDataModel,
      currentUser: currentUser,
    );
    emit(RestartStream(channelDataModel: channelDataModel));
  }

  updateLiveMessages(List<ChatFeedContent> listOfLiveMessages) {
    actualMessages = listOfLiveMessages;
    emit(UpdateLiveMessagesState(liveMessages: listOfLiveMessages));
  }

  updateParticipants(User updatedUser) =>
      emit(ParticipantsUpdatedStream(updatedUser: updatedUser));

  updateChannel(ChannelDataModel newChannelDataModel) =>
      emit(ChannelUpdatedStream(channelDataModel: newChannelDataModel));
}
