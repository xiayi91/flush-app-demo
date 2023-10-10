// ignore_for_file: unused_import

import 'package:instaflutter/core/ui/chat/api/customBackend/chat_custom_backend.dart';
import 'package:instaflutter/core/ui/chat/api/firebase/chat_firebase.dart';
import 'package:instaflutter/core/ui/chat/api/local/chat_local_data.dart';

/// Uncomment these if you want to remove firebase and add local data:
// var chatApiManager = ChatLocalData();

/// Uncomment these if you want to remove firebase and add your own custom backend:
// var chatApiManager = ChatCustomBackend();

/// Remove these lines if you want to remove firebase and add your own custom backend:
var chatApiManager = ChatFireStoreUtils();
