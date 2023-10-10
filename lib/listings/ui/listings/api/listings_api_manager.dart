// ignore_for_file: unused_import

import 'package:instaflutter/listings/ui/listings/api/customBackend/listings_custom_backend.dart';
import 'package:instaflutter/listings/ui/listings/api/firebase/listings_firebase.dart';
import 'package:instaflutter/listings/ui/listings/api/local/listings_local_data.dart';

/// Uncomment these if you want to remove firebase and add local data:
// var listingApiManager = ListingsLocalData();

/// Uncomment these if you want to remove firebase and add your own custom backend:
// var listingApiManager = ListingsCustomBackendUtils();

/// Remove these lines if you want to remove firebase and add your own custom backend:
var listingApiManager = ListingsFirebaseUtils();
