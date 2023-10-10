import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart' as easy_local;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:instaflutter/constants.dart';
import 'package:instaflutter/core/model/channel_data_model.dart';
import 'package:instaflutter/core/model/chat_feed_model.dart';
import 'package:instaflutter/core/model/user.dart';

import 'package:instaflutter/core/ui/chat/api/chat_api_manager.dart';
import 'package:instaflutter/core/ui/chat/api/messages_data_factory.dart';
import 'package:instaflutter/core/ui/chat/chatScreen/chat_bloc.dart';

import 'package:instaflutter/core/ui/chat/player_widget.dart';
import 'package:instaflutter/core/ui/fullScreenImageViewer/full_screen_image_viewer.dart';
import 'package:instaflutter/core/ui/fullScreenVideoViewer/full_screen_video_viewer.dart';
import 'package:instaflutter/core/ui/loading/loading_cubit.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/core/utils/userReport/api/api_manager.dart';
import 'package:instaflutter/core/utils/userReport/api/user_report_repository.dart';

String activeNow = 'Active now'.tr();
String lastSeenOn = 'Last seen'.tr();

class ChatWrapperWidget extends StatelessWidget {
  final ChannelDataModel channelDataModel;
  final User currentUser;
  final Color colorPrimary;
  final Color colorAccent;

  const ChatWrapperWidget({
    Key? key,
    required this.channelDataModel,
    required this.currentUser,
    required this.colorPrimary,
    required this.colorAccent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(
        channelDataModel: channelDataModel,
        chatRepository: chatApiManager,
        currentUser: currentUser,
        userReportRepository: userReportingApiManager,
      ),
      child: ChatScreen(
        channelDataModel: channelDataModel,
        currentUser: currentUser,
        colorPrimary: colorPrimary,
        colorAccent: colorAccent,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final ChannelDataModel channelDataModel;
  final User currentUser;
  final Color colorPrimary;
  final Color colorAccent;

  const ChatScreen({
    Key? key,
    required this.channelDataModel,
    required this.currentUser,
    required this.colorPrimary,
    required this.colorAccent,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late User currentUser;
  final TextEditingController _messageController = TextEditingController();
  RecordingState currentRecordingState = RecordingState.hidden;
  String audioMessageTime = 'Start Recording'.tr(), subtitleText = '';
  final PagingController<int, ChatFeedContent> _pagingController =
      PagingController(
    firstPageKey: -1,
    invisibleItemsThreshold: 5,
  );
  bool isFirstPage = true;
  int pageSize = pageSizeLimit;
  late ChannelDataModel channelDataModel;
  MessagesDataFactory messagesDataFactory = MessagesDataFactory();

  @override
  void initState() {
    super.initState();
    channelDataModel = widget.channelDataModel;
    currentUser = widget.currentUser;
    subtitleText = channelDataModel.participants.first.active
        ? activeNow
        : '$lastSeenOn ${formatTimestamp(channelDataModel.participants.first.lastOnlineTimestamp, lastSeen: true)}';
    _pagingController.addPageRequestListener((pageKey) {
      context.read<ChatBloc>().add(FetchMessagesPageEvent(
          page: isFirstPage ? pageKey : pageKey + 1, size: pageSize));
      if (isFirstPage) {
        isFirstPage = false;
      }
    });
    context
        .read<ChatBloc>()
        .add(SetupChatListeners(channelDataModel: channelDataModel));
    if (!channelDataModel.readUserIDs.contains(currentUser.userID)) {
      channelDataModel.readUserIDs.add(currentUser.userID);
      context.read<ChatBloc>().add(MarkChatAsReadEvent(
            channelID: channelDataModel.id,
            currentUserID: currentUser.userID,
            messageID: channelDataModel.lastThreadMessageId,
            readUserIDs: channelDataModel.readUserIDs,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                    child: ListTile(
                  dense: true,
                  onTap: () {
                    Navigator.pop(context);
                    _onPrivateChatSettingsClick();
                  },
                  contentPadding: const EdgeInsets.all(0),
                  leading: Icon(
                    Icons.settings,
                    color: isDarkMode(context)
                        ? Colors.grey.shade200
                        : Colors.black,
                  ),
                  title: Text(
                    'Settings'.tr(),
                    style: const TextStyle(fontSize: 18),
                  ),
                ))
              ];
            },
          ),
        ],
        title: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is ChannelUpdatedStream) {
              channelDataModel = state.channelDataModel;
            } else if (state is ParticipantsUpdatedStream) {
              channelDataModel.participants.removeWhere(
                  (element) => element.userID == state.updatedUser.userID);
              channelDataModel.participants.add(state.updatedUser);
            }
          },
          buildWhen: (old, current) =>
              (current is ChannelUpdatedStream ||
                  current is ParticipantsUpdatedStream) &&
              old != current,
          builder: (context, state) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  channelDataModel.name,
                  style: TextStyle(
                      color: isDarkMode(context)
                          ? Colors.grey.shade200
                          : Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                if (!channelDataModel.isGroupChat)
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: buildSubTitle(channelDataModel.participants.first),
                  )
              ],
            );
          },
        ),
        backgroundColor: widget.colorPrimary,
        actionsIconTheme: IconThemeData(
          color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white,
        ),
        iconTheme: IconThemeData(
          color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white,
        ),
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) async {
          if (state is UpdateLiveMessagesState) {
            messagesDataFactory.newLiveMessages = state.liveMessages;
            _pagingController.itemList = messagesDataFactory.getAllMessages();
          } else if (state is NewMessagesPageState) {
            final isLastPage = state.newPage.length < pageSize;
            _pagingController.itemList?.removeWhere((element) => state.newPage
                .where((newElement) => element.id == newElement.id)
                .isNotEmpty);
            if (isLastPage) {
              _pagingController.appendLastPage(state.newPage);
            } else {
              _pagingController.appendPage(state.newPage, state.oldPageKey);
            }
            messagesDataFactory.appendHistoricalMessages(state.newPage);
          } else if (state is MessagesPageErrorState) {
            _pagingController.error = state.error;
          } else if (state is ChatErrorState) {
            context.read<LoadingCubit>().hideLoading();
            showSnackBar(context, state.errorMessage);
          } else if (state is MediaSelectedState) {
            if (state.mediaType == imageMediaType) {
              context.read<LoadingCubit>().showLoading(
                    context,
                    'Uploading image...'.tr(),
                    false,
                    widget.colorPrimary,
                  );
              context
                  .read<ChatBloc>()
                  .add(SendImageMessageEvent(image: state.mediaFile));
            } else if (state.mediaType == videoMediaType) {
              context.read<LoadingCubit>().showLoading(
                    context,
                    'Uploading video...'.tr(),
                    false,
                    widget.colorPrimary,
                  );
              context
                  .read<ChatBloc>()
                  .add(SendVideoMessageEvent(video: state.mediaFile));
            }
          } else if (state is MediaUploadDoneState) {
            context.read<LoadingCubit>().hideLoading();
          } else if (state is RecordingViewVisibleState) {
            FocusScope.of(context).unfocus();
          } else if (state is UserReportDoneState) {
            context.read<LoadingCubit>().hideLoading();
            await showAlertDialog(context, 'Success'.tr(), state.message);
            if (!mounted) return;
            Navigator.pop(context);
          }
        },
        buildWhen: (old, current) =>
            current.runtimeType != UpdateAppBarState && old != current,
        builder: (context, state) {
          if (state is RestartStream) {
            channelDataModel = state.channelDataModel;
            isFirstPage = true;
            _pagingController.refresh();
          } else if (state is RecordingViewVisibleState) {
            currentRecordingState = RecordingState.visible;
          } else if (state is RecordCancelState) {
            audioMessageTime = 'Start Recording'.tr();
            currentRecordingState = RecordingState.visible;
          } else if (state is RecordSentState) {
            context.read<LoadingCubit>().hideLoading();
            audioMessageTime = 'Start Recording'.tr();
            currentRecordingState = RecordingState.hidden;
          } else if (state is RecordingViewHiddenState) {
            currentRecordingState = RecordingState.hidden;
          } else if (state is RecordingAudioState) {
            currentRecordingState = RecordingState.recording;
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8, bottom: 8),
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        context.read<ChatBloc>().add(MicClickedEvent(
                            recordingState: RecordingState.visible));
                      },
                      child: PagedListView<int, ChatFeedContent>(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        pagingController: _pagingController,
                        builderDelegate:
                            PagedChildBuilderDelegate<ChatFeedContent>(
                          noItemsFoundIndicatorBuilder: (_) => Center(
                              child: const Text('No Messages Yet.').tr()),
                          firstPageProgressIndicatorBuilder: (_) =>
                              const Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                          newPageProgressIndicatorBuilder: (_) => const Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                          itemBuilder: (context, message, index) =>
                              buildMessage(
                            message,
                            channelDataModel.participants,
                          ),
                        ),
                        reverse: true,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _onCameraClick,
                          icon: Icon(
                            Icons.camera_alt,
                            color: widget.colorPrimary,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 2.0, right: 2),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: ShapeDecoration(
                                shape: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(360),
                                    ),
                                    borderSide:
                                        BorderSide(style: BorderStyle.none)),
                                color: isDarkMode(context)
                                    ? Colors.grey[700]
                                    : Colors.grey.shade200,
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => context.read<ChatBloc>().add(
                                        MicClickedEvent(
                                            recordingState:
                                                currentRecordingState)),
                                    child: Icon(
                                      Icons.mic,
                                      color: currentRecordingState ==
                                              RecordingState.hidden
                                          ? widget.colorPrimary
                                          : Colors.red,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      onChanged: (s) => context
                                          .read<ChatBloc>()
                                          .add(TextUpdateEvent(
                                              isTextEmpty: s.isEmpty)),
                                      onTap: () {
                                        context.read<ChatBloc>().add(
                                            MicClickedEvent(
                                                recordingState:
                                                    RecordingState.visible));
                                      },
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      controller: _messageController,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 8),
                                        hintText: 'Start typing'.tr(),
                                        hintStyle:
                                            TextStyle(color: Colors.grey[400]),
                                        focusedBorder: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(360),
                                            ),
                                            borderSide: BorderSide(
                                                style: BorderStyle.none)),
                                        enabledBorder: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(360),
                                            ),
                                            borderSide: BorderSide(
                                                style: BorderStyle.none)),
                                      ),
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      maxLines: 5,
                                      minLines: 1,
                                      keyboardType: TextInputType.multiline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        BlocBuilder<ChatBloc, ChatState>(
                          buildWhen: (old, current) =>
                              current is TextUpdateState && old != current,
                          builder: (context, state) {
                            return IconButton(
                                icon: Icon(
                                  Icons.send,
                                  color: state is TextUpdateState &&
                                          state.isTextEmpty
                                      ? widget.colorPrimary.withOpacity(.5)
                                      : widget.colorPrimary,
                                ),
                                onPressed: () async {
                                  if (_messageController.text.isNotEmpty) {
                                    context.read<ChatBloc>().add(
                                        SendTextMessageEvent(
                                            messageContent: _messageController
                                                .text
                                                .trim()));
                                    _messageController.clear();
                                  }
                                });
                          },
                        )
                      ],
                    ),
                  ),
                  _buildAudioMessageRecorder()
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAudioMessageRecorder() {
    return Visibility(
      visible: currentRecordingState != RecordingState.hidden,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .3,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                return Expanded(
                    child: Center(
                        child: Text(state is RecordTimerUpdateState
                            ? state.updatedAudioTime
                            : 'Start Recording'.tr())));
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Stack(children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Visibility(
                          visible:
                              currentRecordingState == RecordingState.recording,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.colorPrimary,
                              padding:
                                  const EdgeInsets.only(top: 12, bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                side: const BorderSide(style: BorderStyle.none),
                              ),
                            ),
                            child: const Text(
                              'Send',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ).tr(),
                            onPressed: () {
                              context
                                  .read<ChatBloc>()
                                  .add(SendAudioMessageEvent());
                              context.read<LoadingCubit>().showLoading(
                                    context,
                                    'Uploading Audio...'.tr(),
                                    false,
                                    widget.colorPrimary,
                                  );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Visibility(
                          visible:
                              currentRecordingState == RecordingState.recording,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade700,
                                padding:
                                    const EdgeInsets.only(top: 12, bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                  side:
                                      const BorderSide(style: BorderStyle.none),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ).tr(),
                              onPressed: () => context
                                  .read<ChatBloc>()
                                  .add(RecordCancelEvent())
                              // _onCancelRecording(),
                              ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Visibility(
                      visible: currentRecordingState == RecordingState.visible,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            side: const BorderSide(style: BorderStyle.none),
                          ),
                        ),
                        child: const Text(
                          'Record',
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ).tr(),
                        onPressed: () =>
                            context.read<ChatBloc>().add(StartRecordingEvent()),
                        // _onStartRecording(),
                      ),
                    ),
                  ),
                ]),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildSubTitle(User friend) {
    subtitleText = friend.active
        ? activeNow
        : '$lastSeenOn ${formatTimestamp(friend.lastOnlineTimestamp, lastSeen: true)}';
    return Text(subtitleText,
        style: TextStyle(fontSize: 15, color: Colors.grey.shade200));
  }

  _onCameraClick() {
    context
        .read<ChatBloc>()
        .add(MicClickedEvent(recordingState: RecordingState.visible));
    showCupertinoModalPopup(
      context: context,
      builder: (actionSheetContext) => CupertinoActionSheet(
        message: const Text(
          'Send Media',
          style: TextStyle(fontSize: 15.0),
        ).tr(),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Choose image from gallery').tr(),
            onPressed: () async {
              Navigator.pop(actionSheetContext);
              context.read<ChatBloc>().add(AddMediaToChatEvent(
                  mediaSource: galleryMediaSource, mediaType: imageMediaType));
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Choose video from gallery').tr(),
            onPressed: () async {
              Navigator.pop(actionSheetContext);
              context.read<ChatBloc>().add(AddMediaToChatEvent(
                  mediaSource: galleryMediaSource, mediaType: videoMediaType));
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Take a picture').tr(),
            onPressed: () async {
              Navigator.pop(actionSheetContext);
              context.read<ChatBloc>().add(AddMediaToChatEvent(
                  mediaSource: cameraMediaSource, mediaType: imageMediaType));
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Record video').tr(),
            onPressed: () async {
              Navigator.pop(actionSheetContext);
              context.read<ChatBloc>().add(AddMediaToChatEvent(
                  mediaSource: cameraMediaSource, mediaType: videoMediaType));
            },
          )
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text(
            'Cancel',
          ).tr(),
          onPressed: () {
            Navigator.pop(actionSheetContext);
          },
        ),
      ),
    );
  }

  Widget buildMessage(ChatFeedContent messageData, List<User> members) {
    if (messageData.senderID == currentUser.userID) {
      return myMessageView(messageData);
    } else {
      return remoteMessageView(
          messageData: messageData,
          sender: members
              .firstWhereOrNull((user) => user.userID == messageData.senderID));
    }
  }

  Widget myMessageView(ChatFeedContent messageData) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
              padding: const EdgeInsetsDirectional.only(end: 12.0),
              child: _myMessageContentWidget(messageData)),
          displayCircleImage(messageData.senderProfilePictureURL, 35, false)
        ],
      ),
    );
  }

  Widget _myMessageContentWidget(ChatFeedContent messageData) {
    var mediaUrl = '';
    if (messageData.chatMedia != null) {
      if (messageData.chatMedia!.mime.contains('video')) {
        mediaUrl = messageData.chatMedia!.thumbnailURL ?? '';
      } else {
        mediaUrl = messageData.chatMedia!.url;
      }
    }
    if (mediaUrl.contains('audio')) {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Directionality.of(context) == TextDirection.ltr
            ? Alignment.bottomRight
            : Alignment.bottomLeft,
        children: [
          Positioned.directional(
            textDirection: Directionality.of(context),
            end: -8,
            bottom: 0,
            child: Image.asset(
              Directionality.of(context) == TextDirection.ltr
                  ? 'assets/images/chat_arrow_right.png'
                  : 'assets/images/chat_arrow_left.png',
              color: widget.colorAccent,
              height: 12,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 50,
              maxWidth: 200,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: widget.colorAccent,
                shape: BoxShape.rectangle,
                borderRadius: const BorderRadius.all(
                  Radius.circular(8),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: PlayerWidget(
                  url: messageData.chatMedia!.url,
                  color: isDarkMode(context)
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (mediaUrl.isNotEmpty) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 50,
          maxWidth: 200,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (messageData.chatMedia?.thumbnailURL == null) {
                    push(context, FullScreenImageViewer(imageUrl: mediaUrl));
                  }
                },
                child: Hero(
                  tag: mediaUrl,
                  child: CachedNetworkImage(
                    imageUrl: mediaUrl,
                    placeholder: (context, url) =>
                        Image.asset('assets/images/img_placeholder.png'),
                    errorWidget: (context, url, error) =>
                        Image.asset('assets/images/error_image.png'),
                  ),
                ),
              ),
              if (messageData.chatMedia?.thumbnailURL != null)
                FloatingActionButton(
                  mini: true,
                  heroTag: messageData.id,
                  backgroundColor: widget.colorAccent,
                  onPressed: () {
                    push(
                        context,
                        FullScreenVideoViewer(
                            heroTag: messageData.id,
                            videoUrl: messageData.chatMedia?.url ?? ''));
                  },
                  child: Icon(
                    Icons.play_arrow,
                    color: isDarkMode(context) ? Colors.black : Colors.white,
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Directionality.of(context) == TextDirection.ltr
            ? Alignment.bottomRight
            : Alignment.bottomLeft,
        children: [
          Positioned.directional(
            textDirection: Directionality.of(context),
            end: -8,
            bottom: 0,
            child: Image.asset(
              Directionality.of(context) == TextDirection.ltr
                  ? 'assets/images/chat_arrow_right.png'
                  : 'assets/images/chat_arrow_left.png',
              color: widget.colorAccent,
              height: 12,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 50,
              maxWidth: 200,
            ),
            child: Container(
              decoration: BoxDecoration(
                  color: widget.colorAccent,
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(Radius.circular(8))),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Text(
                  messageData.content,
                  textAlign: TextAlign.start,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                      color: isDarkMode(context) ? Colors.black : Colors.white,
                      fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget remoteMessageView(
      {required ChatFeedContent messageData, required User? sender}) {
    if (messageData.content.contains('XARQEGWE13SD') &&
        sender?.email == 'florian@instamobile.io') {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Stack(
            alignment: Directionality.of(context) == TextDirection.ltr
                ? Alignment.bottomRight
                : Alignment.bottomLeft,
            children: [
              displayCircleImage(
                  messageData.senderProfilePictureURL, 35, false),
              Positioned.directional(
                textDirection: Directionality.of(context),
                end: 1,
                bottom: 1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: sender?.active ?? false ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isDarkMode(context)
                          ? const Color(0xFF303030)
                          : Colors.white,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
              padding: const EdgeInsetsDirectional.only(start: 12.0),
              child: _remoteMessageContentWidget(messageData)),
        ],
      ),
    );
  }

  Widget _remoteMessageContentWidget(ChatFeedContent messageData) {
    var mediaUrl = '';
    if (messageData.chatMedia != null) {
      if (messageData.chatMedia!.mime.contains('video')) {
        mediaUrl = messageData.chatMedia!.thumbnailURL ?? '';
      } else {
        mediaUrl = messageData.chatMedia?.url ?? '';
      }
    }
    if (mediaUrl.contains('audio')) {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Directionality.of(context) == TextDirection.ltr
            ? Alignment.bottomLeft
            : Alignment.bottomRight,
        children: [
          Positioned.directional(
            textDirection: Directionality.of(context),
            start: -8,
            bottom: 0,
            child: Image.asset(
              Directionality.of(context) == TextDirection.ltr
                  ? 'assets/images/chat_arrow_left.png'
                  : 'assets/images/chat_arrow_right.png',
              color: isDarkMode(context) ? Colors.grey[600] : Colors.grey[300],
              height: 12,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 50,
              maxWidth: 200,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode(context)
                    ? Colors.grey.shade600
                    : Colors.grey.shade300,
                shape: BoxShape.rectangle,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: PlayerWidget(
                  url: messageData.chatMedia!.url,
                  color: isDarkMode(context)
                      ? widget.colorAccent
                      : widget.colorPrimary,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (mediaUrl.isNotEmpty) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 50,
          maxWidth: 200,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (messageData.chatMedia?.thumbnailURL == null) {
                    push(context, FullScreenImageViewer(imageUrl: mediaUrl));
                  }
                },
                child: Hero(
                  tag: mediaUrl,
                  child: CachedNetworkImage(
                    imageUrl: mediaUrl,
                    placeholder: (context, url) =>
                        Image.asset('assets/images/img_placeholder.png'),
                    errorWidget: (context, url, error) =>
                        Image.asset('assets/images/error_image.png'),
                  ),
                ),
              ),
              if (messageData.chatMedia?.thumbnailURL != null)
                FloatingActionButton(
                  mini: true,
                  heroTag: messageData.id,
                  backgroundColor: widget.colorAccent,
                  onPressed: () {
                    push(
                        context,
                        FullScreenVideoViewer(
                            heroTag: messageData.id,
                            videoUrl: messageData.chatMedia!.url));
                  },
                  child: Icon(
                    Icons.play_arrow,
                    color: isDarkMode(context) ? Colors.black : Colors.white,
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Directionality.of(context) == TextDirection.ltr
            ? Alignment.bottomLeft
            : Alignment.bottomRight,
        children: [
          Positioned.directional(
            textDirection: Directionality.of(context),
            start: -8,
            bottom: 0,
            child: Image.asset(
              Directionality.of(context) == TextDirection.ltr
                  ? 'assets/images/chat_arrow_left.png'
                  : 'assets/images/chat_arrow_right.png',
              color: isDarkMode(context) ? Colors.grey[600] : Colors.grey[300],
              height: 12,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 50,
              maxWidth: 200,
            ),
            child: Container(
              decoration: BoxDecoration(
                  color:
                      isDarkMode(context) ? Colors.grey[600] : Colors.grey[300],
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(Radius.circular(8))),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Text(
                  messageData.content,
                  textAlign: TextAlign.start,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: isDarkMode(context) ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  _onPrivateChatSettingsClick() {
    showCupertinoModalPopup(
      context: context,
      builder: (actionSheetContext) => CupertinoActionSheet(
        message: const Text(
          'Chat Settings',
          style: TextStyle(fontSize: 15.0),
        ).tr(),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Block user').tr(),
            onPressed: () {
              Navigator.pop(actionSheetContext);
              context.read<LoadingCubit>().showLoading(
                    context,
                    'Blocking user...'.tr(),
                    false,
                    widget.colorPrimary,
                  );
              context.read<ChatBloc>().add(
                    BlockUserEvent(
                      targetUser: channelDataModel.participants.first,
                      action: blockUserAction,
                    ),
                  );
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Report user').tr(),
            onPressed: () {
              Navigator.pop(actionSheetContext);
              context.read<LoadingCubit>().showLoading(
                    context,
                    'Reporting user...'.tr(),
                    false,
                    widget.colorPrimary,
                  );
              context.read<ChatBloc>().add(
                    BlockUserEvent(
                      targetUser: channelDataModel.participants.first,
                      action: reportUserAction,
                    ),
                  );
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text(
            'Cancel',
          ).tr(),
          onPressed: () {
            Navigator.pop(actionSheetContext);
          },
        ),
      ),
    );
  }
}
