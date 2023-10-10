import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instaflutter/core/model/channel_data_model.dart';
import 'package:instaflutter/core/ui/chat/chatScreen/chat_screen.dart';
import 'package:instaflutter/core/ui/chat/player_widget.dart';
import 'package:instaflutter/core/ui/loading/loading_cubit.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/ui/auth/api/auth_api_manager.dart';
import 'package:instaflutter/listings/ui/auth/authentication_bloc.dart';
import 'package:instaflutter/listings/ui/auth/launcherScreen/launcher_screen.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_api_manager.dart';

runListings() {
  appName = 'Flutter Universal Listings';
  colorAccent = 0xFFff8e94;
  colorPrimaryDark = 0xFFc61f3c;
  colorPrimary = 0xFFff5a66;
  categoriesCollection = 'universal_categories';
  listingsCollection = 'universal_listings';
  reviewCollection = 'universal_reviews';
  filtersCollection = 'universal_filters';
  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('ar')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    useFallbackTranslations: true,
    useOnlyLangCode: true,
    child: MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
            create: (_) =>
                AuthenticationBloc(authenticationRepository: authApiManager)),
        RepositoryProvider(create: (_) => LoadingCubit()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late StreamSubscription tokenStream;

  /// this key is used to navigate to the appropriate screen when the
  /// notification is clicked from the system tray
  final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey(debugLabel: 'Main Navigator');

  // Set default `_initialized` and `_error` state to false
  bool _initialized = false;
  bool _error = false;

  // Define an async function to initialize FlutterFire
  initializeFlutterFire() async {
    try {
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        if (!mounted) return;
        _handleNotification(initialMessage.data, navigatorKey, context);
      }
      FirebaseMessaging.onMessageOpenedApp
          .listen((RemoteMessage? remoteMessage) {
        if (remoteMessage != null) {
          _handleNotification(remoteMessage.data, navigatorKey, context);
        }
      });
      if (!Platform.isIOS) {
        FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);
      }
      tokenStream = FirebaseMessaging.instance.onTokenRefresh.listen((event) {
        if (BlocProvider.of<AuthenticationBloc>(context).user != null) {
          debugPrint('token $event');
          BlocProvider.of<AuthenticationBloc>(context).user!.pushToken = event;
          profileApiManager.updateCurrentUser(
              BlocProvider.of<AuthenticationBloc>(context).user!);
        }
      });
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      // Set `_error` state to true if Firebase initialization fails
      setState(() {
        _error = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Color(colorPrimaryDark)));
    initializeFlutterFire();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    // Show error message if initialization failed
    if (_error) {
      return Container(
        color: Colors.white,
        child: const Center(
            child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 25,
            ),
            SizedBox(height: 16),
            Text(
              'Failed to initialise firebase!',
              style: TextStyle(color: Colors.red, fontSize: 25),
            ),
          ],
        )),
      );
    }

    // Show a loader until FlutterFire is initialized
    if (!_initialized) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }

    return MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        title: appName.tr(),
        theme: ThemeData(
          snackBarTheme: const SnackBarThemeData(
              contentTextStyle: TextStyle(color: Colors.white)),
          sliderTheme: SliderThemeData(
              trackShape: CustomTrackShape(),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          brightness: Brightness.light,
          textSelectionTheme:
              TextSelectionThemeData(cursorColor: Color(colorPrimaryDark)),
          primaryColor: Color(colorPrimary),
          colorScheme: ColorScheme.fromSwatch().copyWith(
              primary: Color(colorPrimary),
              secondary: Color(colorAccent),
              brightness: Brightness.light),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            color: Platform.isIOS ? Colors.transparent : Color(colorPrimary),
            elevation: Platform.isIOS ? 0 : null,
            actionsIconTheme: Platform.isIOS
                ? IconThemeData(color: Color(colorPrimary))
                : null,
            iconTheme: Platform.isIOS
                ? IconThemeData(color: Color(colorPrimary))
                : const IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
                color: Platform.isIOS ? Color(colorPrimary) : Colors.white,
                fontSize: 20.0,
                letterSpacing: 0,
                fontWeight: FontWeight.w500),
            systemOverlayStyle: Platform.isAndroid
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
          ),
          // Platform.isAndroid ? _lightAndroidBar : _lightIOSBar,
          bottomSheetTheme:
              BottomSheetThemeData(backgroundColor: Colors.grey.shade50),
        ),
        darkTheme: ThemeData(
          snackBarTheme: const SnackBarThemeData(
              contentTextStyle: TextStyle(color: Colors.white)),
          primaryColor: Color(colorPrimary),
          textSelectionTheme:
              TextSelectionThemeData(cursorColor: Color(colorPrimaryDark)),
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: Color(colorPrimary),
            secondary: Color(colorAccent),
            brightness: Brightness.dark,
          ),
          sliderTheme: SliderThemeData(
              trackShape: CustomTrackShape(),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            color: Platform.isIOS ? Colors.transparent : Color(colorPrimary),
            elevation: Platform.isIOS ? 0 : null,
            actionsIconTheme: Platform.isIOS
                ? IconThemeData(color: Color(colorPrimary))
                : null,
            iconTheme: Platform.isIOS
                ? IconThemeData(color: Color(colorPrimary))
                : const IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
                color: Platform.isIOS ? Color(colorPrimary) : Colors.black,
                fontSize: 20.0,
                letterSpacing: 0,
                fontWeight: FontWeight.w500),
            systemOverlayStyle: Platform.isAndroid
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light,
          ),
          // Platform.isAndroid ? _darkAndroidBar : _darkIOSBar,
          bottomSheetTheme:
              BottomSheetThemeData(backgroundColor: Colors.grey[850]),
        ),
        debugShowCheckedModeBanner: false,
        color: Color(colorPrimary),
        home: const LauncherScreen());
  }

  @override
  void dispose() {
    tokenStream.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (auth.FirebaseAuth.instance.currentUser != null &&
        BlocProvider.of<AuthenticationBloc>(context).user != null) {
      if (state == AppLifecycleState.paused) {
        //user offline
        tokenStream.pause();
        BlocProvider.of<AuthenticationBloc>(context).user!.active = false;
        BlocProvider.of<AuthenticationBloc>(context).user!.lastOnlineTimestamp =
            Timestamp.now().seconds;
        profileApiManager.updateCurrentUser(
            BlocProvider.of<AuthenticationBloc>(context).user!);
      } else if (state == AppLifecycleState.resumed) {
        //user online
        tokenStream.resume();
        BlocProvider.of<AuthenticationBloc>(context).user!.active = true;
        profileApiManager.updateCurrentUser(
            BlocProvider.of<AuthenticationBloc>(context).user!);
      }
    }
  }
}

/// this faction is called when the notification is clicked from system tray
/// when the app is in the background or completely killed
void _handleNotification(Map<String, dynamic> message,
    GlobalKey<NavigatorState> navigatorKey, BuildContext context) {
  /// right now we only handle click actions on chat messages only
  try {
    if (message.containsKey('channelDataModel')) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ChatWrapperWidget(
            channelDataModel: ChannelDataModel.fromJson(
                jsonDecode(message['channelDataModel']),
                navigatorKey.currentContext
                        ?.read<AuthenticationBloc>()
                        .user!
                        .userID ??
                    ''),
            currentUser: context.read<AuthenticationBloc>().user!,
            colorAccent: Color(colorAccent),
            colorPrimary: Color(colorPrimary),
          ),
        ),
      );
    }
  } catch (e, s) {
    debugPrint('MyAppState._handleNotification $e $s');
  }
}

Future<dynamic> backgroundMessageHandler(RemoteMessage remoteMessage) async {
  await Firebase.initializeApp();
  Map<dynamic, dynamic> message = remoteMessage.data;

  if (message.containsKey('notification')) {
    // Handle notification message
    // final dynamic notification = message['notification'];
    debugPrint('backgroundMessageHandler message.containsKey(notification)');
  }

  // Or do other work.
}
