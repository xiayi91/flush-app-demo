import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instaflutter/core/model/user.dart';
import 'package:instaflutter/listings/listings_app_config.dart';

class ListingsUser extends User {
  bool isAdmin;

  List<String> likedListingsIDs;

  ListingsUser({
    email = '',
    userID = '',
    profilePictureURL = '',
    firstName = '',
    phoneNumber = '',
    lastName = '',
    active = false,
    lastOnlineTimestamp,
    settings,
    pushToken = '',
    this.isAdmin = false,
    this.likedListingsIDs = const [],
  }) : super(
          firstName: firstName,
          lastName: lastName,
          userID: userID,
          active: active,
          email: email,
          pushToken: pushToken,
          phoneNumber: phoneNumber,
          profilePictureURL: profilePictureURL,
          settings: settings ?? UserSettings(),
          lastOnlineTimestamp: lastOnlineTimestamp is int
              ? lastOnlineTimestamp
              : Timestamp.now().seconds,
          appIdentifier: '$appName ${Platform.operatingSystem}',
        );

  factory ListingsUser.fromJson(Map<String, dynamic> parsedJson) {
    return ListingsUser(
      email: parsedJson['email'] ?? '',
      firstName: parsedJson['firstName'] ?? '',
      lastName: parsedJson['lastName'] ?? '',
      active: parsedJson['active'] ?? false,
      lastOnlineTimestamp: parsedJson['lastOnlineTimestamp'] is Timestamp
          ? (parsedJson['lastOnlineTimestamp'] as Timestamp).seconds
          : parsedJson['lastOnlineTimestamp'],
      settings: parsedJson.containsKey('settings')
          ? UserSettings.fromJson(parsedJson['settings'])
          : UserSettings(),
      phoneNumber: parsedJson['phoneNumber'] ?? '',
      userID: parsedJson['id'] ?? parsedJson['userID'] ?? '',
      profilePictureURL: parsedJson['profilePictureURL'] ?? '',
      pushToken: parsedJson['pushToken'] ?? '',
      isAdmin: parsedJson['isAdmin'] ?? false,
      likedListingsIDs:
          List<String>.from(parsedJson['likedListingsIDs'] ?? const []),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'settings': settings.toJson(),
      'phoneNumber': phoneNumber,
      'id': userID,
      'active': active,
      'lastOnlineTimestamp': lastOnlineTimestamp,
      'profilePictureURL': profilePictureURL,
      'appIdentifier': appIdentifier,
      'pushToken': pushToken,
      'isAdmin': isAdmin,
      'likedListingsIDs': likedListingsIDs,
    };
  }
}
