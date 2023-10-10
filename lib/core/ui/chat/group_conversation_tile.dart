import 'dart:io';

import 'package:flutter/material.dart';
import 'package:instaflutter/core/model/channel_data_model.dart';
import 'package:instaflutter/core/model/chat_feed_model.dart';
import 'package:instaflutter/core/model/user.dart';
import 'package:instaflutter/core/ui/chat/chatScreen/chat_screen.dart';
import 'package:instaflutter/core/utils/helper.dart';

class GroupConversationTile extends StatefulWidget {
  final ChatFeedModel chatFeedModel;
  final User currentUser;
  final Color colorPrimary;
  final Color colorAccent;
  final List<String> membersImages;

  const GroupConversationTile({
    Key? key,
    required this.chatFeedModel,
    required this.currentUser,
    required this.colorPrimary,
    required this.colorAccent,
    required this.membersImages,
  }) : super(key: key);

  @override
  State<GroupConversationTile> createState() => _GroupConversationTileState();
}

class _GroupConversationTileState extends State<GroupConversationTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
          start: 32.0, bottom: 20.8, top: 8, end: 16),
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
              clipBehavior: Clip.none,
              children: [
                displayCircleImage(widget.membersImages.first, 44, false),
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  start: -16,
                  bottom: -12.8,
                  child:
                      displayCircleImage(widget.membersImages.last, 44, false),
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
                        fontFamily: Platform.isIOS ? 'sanFran' : 'Roboto',
                      ),
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
