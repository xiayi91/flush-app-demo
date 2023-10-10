import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/container/container_bloc.dart';
import 'package:instaflutter/listings/ui/conversationsScreen/conversations_screen.dart';
import 'package:instaflutter/listings/ui/listings/addListing/add_listing_screen.dart';
import 'package:instaflutter/listings/ui/listings/categories/categories_screen.dart';
import 'package:instaflutter/listings/ui/listings/home/home_screen.dart';
import 'package:instaflutter/listings/ui/listings/mapView/map_view_screen.dart';
import 'package:instaflutter/listings/ui/listings/search/search_screen.dart';
import 'package:instaflutter/listings/ui/profile/profileScreen/profile_screen.dart';
import 'package:provider/provider.dart';

enum DrawerSelection { home, conversations, categories, search, profile }

class ContainerWrapperWidget extends StatelessWidget {
  final ListingsUser currentUser;

  const ContainerWrapperWidget({Key? key, required this.currentUser})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ContainerBloc(),
        ),
      ],
      child: ContainerScreen(user: currentUser),
    );
  }
}

class ContainerScreen extends StatefulWidget {
  final ListingsUser user;

  const ContainerScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ContainerScreen> createState() {
    return _ContainerState();
  }
}

class _ContainerState extends State<ContainerScreen> {
  late ListingsUser currentUser;
  DrawerSelection _drawerSelection = DrawerSelection.home;
  String _appBarTitle = 'Home'.tr();

  int _selectedTapIndex = 0;
  GlobalKey<HomeScreenState> homeKey = GlobalKey();
  late Widget _currentWidget;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _currentWidget = HomeWrapperWidget(
      currentUser: currentUser,
      homeKey: homeKey,
    );
    FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ListingsUser>.value(
      value: currentUser,
      child: BlocConsumer<ContainerBloc, ContainerState>(
        listener: (context, state) {
          if (state is TabSelectedState) {
            _currentWidget = state.currentWidget;
            _selectedTapIndex = state.currentTabIndex;
            _appBarTitle = state.appBarTitle;
            _drawerSelection = state.drawerSelection;
          }
        },
        builder: (context, state) {
          return Scaffold(
            bottomNavigationBar: Platform.isIOS
                ? BottomNavigationBar(
                    currentIndex: _selectedTapIndex,
                    onTap: (index) {
                      switch (index) {
                        case 0:
                          context.read<ContainerBloc>().add(TabSelectedEvent(
                                appBarTitle: 'Home'.tr(),
                                currentTabIndex: 0,
                                drawerSelection: DrawerSelection.home,
                                currentWidget: HomeWrapperWidget(
                                  currentUser: currentUser,
                                  homeKey: homeKey,
                                ),
                              ));
                          break;
                        case 1:
                          context.read<ContainerBloc>().add(TabSelectedEvent(
                                appBarTitle: 'Categories'.tr(),
                                currentTabIndex: 1,
                                drawerSelection: DrawerSelection.categories,
                                currentWidget: CategoriesWrapperWidget(
                                  currentUser: currentUser,
                                ),
                              ));
                          break;
                        case 2:
                          context.read<ContainerBloc>().add(TabSelectedEvent(
                                appBarTitle: 'Conversations'.tr(),
                                currentTabIndex: 2,
                                drawerSelection: DrawerSelection.conversations,
                                currentWidget: ConversationsWrapperWidget(
                                  user: currentUser,
                                ),
                              ));
                          break;
                        case 3:
                          context.read<ContainerBloc>().add(TabSelectedEvent(
                                appBarTitle: 'Search'.tr(),
                                currentTabIndex: 3,
                                drawerSelection: DrawerSelection.search,
                                currentWidget: SearchWrapperWidget(
                                    currentUser: currentUser),
                              ));
                          break;
                      }
                    },
                    unselectedItemColor: Colors.grey,
                    selectedItemColor: Color(colorPrimary),
                    items: [
                        BottomNavigationBarItem(
                            icon: const Icon(Icons.home), label: 'Home'.tr()),
                        BottomNavigationBarItem(
                            icon: const Icon(Icons.category),
                            label: 'Categories'.tr()),
                        BottomNavigationBarItem(
                            icon: const Icon(Icons.message),
                            label: 'Conversations'.tr()),
                        BottomNavigationBarItem(
                            icon: const Icon(Icons.search),
                            label: 'Search'.tr()),
                      ])
                : null,
            drawer: Platform.isAndroid
                ? Drawer(
                    child: ListTileTheme(
                      data: ListTileThemeData(
                        style: ListTileStyle.drawer,
                        selectedColor: Color(colorPrimary),
                      ),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          Consumer<ListingsUser>(
                            builder: (context, user, _) {
                              return DrawerHeader(
                                decoration: BoxDecoration(
                                  color: Color(colorPrimary),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    displayCircleImage(
                                        user.profilePictureURL, 75, false),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        user.fullName(),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        user.email,
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          ListTile(
                            selected: _drawerSelection == DrawerSelection.home,
                            title: Text('Home'.tr()),
                            onTap: () {
                              Navigator.pop(context);
                              context.read<ContainerBloc>().add(
                                    TabSelectedEvent(
                                      appBarTitle: 'Home'.tr(),
                                      currentTabIndex: 0,
                                      drawerSelection: DrawerSelection.home,
                                      currentWidget: HomeWrapperWidget(
                                        homeKey: homeKey,
                                        currentUser: currentUser,
                                      ),
                                    ),
                                  );
                            },
                            leading: const Icon(Icons.home),
                          ),
                          ListTile(
                            selected:
                                _drawerSelection == DrawerSelection.categories,
                            leading: const Icon(Icons.category),
                            title: Text('Categories'.tr()),
                            onTap: () {
                              Navigator.pop(context);
                              context.read<ContainerBloc>().add(
                                    TabSelectedEvent(
                                      appBarTitle: 'Categories'.tr(),
                                      currentTabIndex: 1,
                                      drawerSelection:
                                          DrawerSelection.categories,
                                      currentWidget: CategoriesWrapperWidget(
                                          currentUser: currentUser),
                                    ),
                                  );
                            },
                          ),
                          ListTile(
                            selected: _drawerSelection ==
                                DrawerSelection.conversations,
                            leading: const Icon(Icons.message),
                            title: Text('Conversations'.tr()),
                            onTap: () {
                              Navigator.pop(context);
                              context.read<ContainerBloc>().add(
                                    TabSelectedEvent(
                                      appBarTitle: 'Conversations'.tr(),
                                      currentTabIndex: 2,
                                      drawerSelection:
                                          DrawerSelection.conversations,
                                      currentWidget: ConversationsWrapperWidget(
                                          user: currentUser),
                                    ),
                                  );
                            },
                          ),
                          ListTile(
                            selected:
                                _drawerSelection == DrawerSelection.search,
                            title: Text('Search'.tr()),
                            leading: const Icon(Icons.search),
                            onTap: () {
                              Navigator.pop(context);
                              context.read<ContainerBloc>().add(
                                    TabSelectedEvent(
                                      appBarTitle: 'Search'.tr(),
                                      currentTabIndex: 3,
                                      drawerSelection: DrawerSelection.search,
                                      currentWidget: SearchWrapperWidget(
                                          currentUser: currentUser),
                                    ),
                                  );
                            },
                          ),
                          ListTile(
                            selected:
                                _drawerSelection == DrawerSelection.profile,
                            title: Text('Profile'.tr()),
                            leading: const Icon(Icons.account_circle),
                            onTap: () {
                              Navigator.pop(context);
                              context.read<ContainerBloc>().add(
                                    TabSelectedEvent(
                                      appBarTitle: 'Profile'.tr(),
                                      currentTabIndex: 3,
                                      drawerSelection: DrawerSelection.profile,
                                      currentWidget: ProfileScreen(
                                          currentUser: currentUser),
                                    ),
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
            appBar: AppBar(
              leading: Platform.isIOS
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                          onTap: () => push(
                              context, ProfileScreen(currentUser: currentUser)),
                          child: displayCircleImage(
                              currentUser.profilePictureURL, 2, false)),
                    )
                  : null,
              actions: [
                if (_currentWidget is HomeWrapperWidget)
                  IconButton(
                    tooltip: 'Add Listing'.tr(),
                    icon: const Icon(
                      Icons.add,
                    ),
                    onPressed: () => push(context,
                        AddListingWrappingWidget(currentUser: currentUser)),
                  ),
                if (_currentWidget is HomeWrapperWidget)
                  IconButton(
                    tooltip: 'Map'.tr(),
                    icon: const Icon(
                      Icons.map,
                    ),
                    onPressed: () => push(
                      context,
                      MapViewScreen(
                        listings: homeKey.currentState?.listings ?? [],
                        fromHome: true,
                        currentUser: currentUser,
                      ),
                    ),
                  ),
              ],
              title: Text(
                _appBarTitle,
              ),
            ),
            body: _currentWidget,
          );
        },
      ),
    );
  }
}
