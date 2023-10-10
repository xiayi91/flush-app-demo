// ignore_for_file: unused_import

import 'package:instaflutter/listings/ui/auth/api/customBackend/auth_custom_backend.dart';
import 'package:instaflutter/listings/ui/auth/api/firebase/auth_firebase.dart';
import 'package:instaflutter/listings/ui/auth/api/local/auth_local_data.dart';

/// Uncomment these if you want to remove firebase and add local data:
// var authApiManager = AuthLocalData();

/// Uncomment these if you want to remove firebase and add your own custom backend:
// var authApiManager = AuthCustomBackendUtils();

/// Remove these lines if you want to remove firebase and add your own custom backend:
var authApiManager = AuthFirebaseUtils();
