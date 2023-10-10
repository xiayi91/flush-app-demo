import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:instaflutter/constants.dart';
import 'package:instaflutter/core/model/chat_feed_model.dart';
import 'package:instaflutter/core/ui/chat/api/chat_api_manager.dart';
import 'package:instaflutter/core/ui/chat/api/conversations_data_factory.dart';
import 'package:instaflutter/core/ui/chat/conversationBloc/conversation_bloc.dart';
import 'package:instaflutter/core/ui/chat/group_conversation_tile.dart';
import 'package:instaflutter/core/ui/chat/private_conversation_tile.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/model/listings_user.dart';

class ConversationsWrapperWidget extends StatelessWidget {
  const ConversationsWrapperWidget({Key? key, required this.user})
      : super(key: key);
  final ListingsUser user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => ConversationsBloc(
            chatRepository: chatApiManager, currentUser: user),
        child: ConversationsScreen(user: user));
  }
}

class ConversationsScreen extends StatefulWidget {
  final ListingsUser user;

  const ConversationsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State createState() {
    return _ConversationsState();
  }
}

class _ConversationsState extends State<ConversationsScreen> {
  late ListingsUser user;
  final PagingController<int, ChatFeedModel> _conversationsController =
      PagingController(firstPageKey: -1, invisibleItemsThreshold: 5);
  bool isFirstConversationsPage = true;
  ConversationsDataFactory conversationsDataFactory =
      ConversationsDataFactory();
  int pageSize = pageSizeLimit;

  @override
  void initState() {
    super.initState();
    user = widget.user;
    _conversationsController.addPageRequestListener((pageKey) {
      context.read<ConversationsBloc>().add(FetchConversationsPageEvent(
          page: isFirstConversationsPage ? pageKey : pageKey + 1,
          size: pageSize));
      if (isFirstConversationsPage) {
        isFirstConversationsPage = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConversationsBloc, ConversationsState>(
      listener: (context, state) {
        if (state is UpdateLiveConversationsState) {
          conversationsDataFactory.newLiveConversations =
              state.liveConversations;
          _conversationsController.itemList =
              conversationsDataFactory.getAllConversations();
        } else if (state is NewConversationsPageState) {
          final isLastPage = state.newPage.length < pageSize;
          _conversationsController.itemList?.removeWhere((element) => state
              .newPage
              .where((newElement) => element.id == newElement.id)
              .isNotEmpty);
          if (isLastPage) {
            _conversationsController.appendLastPage(state.newPage);
          } else {
            _conversationsController.appendPage(
                state.newPage, state.oldPageKey);
          }
          conversationsDataFactory.appendHistoricalConversations(state.newPage);
        } else if (state is ConversationsPageErrorState) {
          _conversationsController.error = state.error;
        }
      },
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            final FocusScopeNode currentScope = FocusScope.of(context);
            if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
              FocusManager.instance.primaryFocus!.unfocus();
            }
          },
          child: RefreshIndicator(
            onRefresh: () async {
              isFirstConversationsPage = true;
              _conversationsController.refresh();
            },
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                PagedSliverList<int, ChatFeedModel>.separated(
                    pagingController: _conversationsController,
                    builderDelegate: PagedChildBuilderDelegate(
                      animateTransitions: true,
                      noItemsFoundIndicatorBuilder: (context) => Center(
                        child: const Text(
                          'No Conversations Found.',
                          style: TextStyle(fontSize: 18),
                        ).tr(),
                      ),
                      firstPageProgressIndicatorBuilder: (context) =>
                          const Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                      itemBuilder: (context, conversation, index) =>
                          _buildConversationRow(conversation),
                    ),
                    separatorBuilder: (context, index) => const Divider()),
              ],
            ),
          ),
        );
      },
    );
  }

  _buildConversationRow(ChatFeedModel chatFeedModel) {
    String user1Image = '';
    String user2Image = '';
    if (chatFeedModel.participants.length >= 2) {
      user1Image = chatFeedModel.participants.first.profilePictureURL;
      user2Image = chatFeedModel.participants.elementAt(1).profilePictureURL;
    }
    if (chatFeedModel.isGroupChat) {
      return GroupConversationTile(
        colorAccent: Color(colorAccent),
        colorPrimary: Color(colorPrimary),
        currentUser: user,
        chatFeedModel: chatFeedModel,
        membersImages: [user1Image, user2Image],
      );
    } else {
      return PrivateConversationTile(
        colorAccent: Color(colorAccent),
        colorPrimary: Color(colorPrimary),
        currentUser: user,
        chatFeedModel: chatFeedModel,
      );
    }
  }

  @override
  void dispose() {
    _conversationsController.dispose();
    super.dispose();
  }
}
