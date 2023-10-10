// ignore_for_file: unused_import

import 'package:instaflutter/core/utils/userReport/api/customBackend/user_reporting_custom_backend.dart';
import 'package:instaflutter/core/utils/userReport/api/firebase/user_reporting_firebase_helper.dart';
import 'package:instaflutter/core/utils/userReport/api/local/user_reporting_local_data.dart';

/// Uncomment these if you want to remove firebase and add local data:
// var userReportingApiManager = UserReportingLocalData();

/// Uncomment these if you want to remove firebase and add your own custom backend:
// var userReportingApiManager = UserReportingCustomBackend();

/// Remove these lines if you want to remove firebase and add your own custom backend:
var userReportingApiManager = UserReportingFireStoreUtils();
