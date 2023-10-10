import 'dart:io';

import 'package:flutter/material.dart';
import 'package:instaflutter/core/model/channel_data_model.dart';
import 'package:instaflutter/core/model/chat_feed_model.dart';
import 'package:instaflutter/core/model/user.dart';
import 'package:instaflutter/core/utils/helper.dart';

import 'chatScreen/chat_screen.dart';

class PrivateConversationTile extends StatefulWidget {
  final ChatFeedModel chatFeedModel;
  final User currentUser;
  final Color colorPrimary;
  final Color colorAccent;

  const PrivateConversationTile({
    Key? key,
    required this.chatFeedModel,
    required this.currentUser,
    required this.colorPrimary,
    required this.colorAccent,
  }) : super(key: key);

  @override
  State<PrivateConversationTile> createState() =>
      _PrivateConversationTileState();
}

class _PrivateConversationTileState extends State<PrivateConversationTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
      child: InkWell(
        onTap: () {
          push(
            context,
            ChatWrapperWidget(
              channelDataModel: ChannelDataModel(
                  id: widget.chatFeedModel.id,
                  participants: widget.chatFeedModel.participants,
                  participantProfilePictureURLs: widget.chatFeedModel
                      .chatFeedContent.participantProfilePictureURLs,
                  name: widget.chatFeedModel.title,
                  channelID: widget.chatFeedModel.id,
                  lastMessage: widget.chatFeedModel.chatFeedContent,
                  lastMessageDate:
                      widget.chatFeedModel.chatFeedContent.createdAt,
                  lastThreadMessageId: widget.chatFeedModel.chatFeedContent.id),
              currentUser: widget.currentUser,
              colorPrimary: widget.colorPrimary,
              colorAccent: widget.colorAccent,
            ),
          );
        },
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                displayCircleImage(
                    widget.chatFeedModel.participants.first.profilePictureURL,
                    60,
                    false),
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  end: 2.4,
                  bottom: 2.4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: widget.chatFeedModel.participants.first.active
                            ? Colors.green
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: isDarkMode(context)
                                ? const Color(0xFF303030)
                                : Colors.white,
                            width: 1.6)),
                  ),
                )
              ],
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsetsDirectional.only(top: 8, end: 8, start: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      widget.chatFeedModel.title,
                      style: TextStyle(
                          fontWeight: widget.chatFeedModel.markedAsRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                          fontSize: 17,
                          color:
                              isDarkMode(context) ? Colors.white : Colors.black,
                          fontFamily: Platform.isIOS ? 'sanFran' : 'Roboto'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.chatFeedModel.chatFeedContent.content,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                  fontWeight: widget.chatFeedModel.markedAsRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.grey),
                            ),
                          ),
                          Text(
                            '• ${formatTimestamp(widget.chatFeedModel.createdAt)}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
