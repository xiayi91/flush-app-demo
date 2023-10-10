// ignore_for_file: unused_import

import 'package:instaflutter/listings/ui/profile/api/customBackend/profile_custom_backend.dart';
import 'package:instaflutter/listings/ui/profile/api/firebase/profile_firebase.dart';
import 'package:instaflutter/listings/ui/profile/api/local/profile_local_data.dart';

/// Uncomment these if you want to remove firebase and add local data:
// var profileApiManager = ProfileLocalData();

/// Uncomment these if you want to remove firebase and add your own custom backend:
// var profileApiManager = ProfileCustomBackendUtils();

/// Remove these lines if you want to remove firebase and add your own custom backend:
var profileApiManager = ProfileFirebaseUtils();
