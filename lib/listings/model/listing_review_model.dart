import 'package:cloud_firestore/cloud_firestore.dart';

class ListingReviewModel {
  String authorID;

  String content;

  int createdAt;

  String firstName;

  String lastName;

  String listingID;

  String profilePictureURL;

  double starCount;

  ListingReviewModel(
      {this.authorID = '',
      this.content = '',
      createdAt,
      this.firstName = '',
      this.lastName = '',
      this.listingID = '',
      this.profilePictureURL = '',
      this.starCount = 0})
      : createdAt = createdAt is int ? createdAt : Timestamp.now().seconds;

  String fullName() => '$firstName $lastName';

  factory ListingReviewModel.fromJson(Map<String, dynamic> parsedJson) {
    return ListingReviewModel(
        authorID: parsedJson['authorID'] ?? '',
        content: parsedJson['content'] ?? '',
        createdAt: parsedJson['createdAt'] is Timestamp
            ? (parsedJson['createdAt'] as Timestamp).seconds
            : parsedJson['createdAt'],
        firstName: parsedJson['firstName'] ?? '',
        lastName: parsedJson['lastName'] ?? '',
        listingID: parsedJson['listingID'] ?? '',
        profilePictureURL: parsedJson['profilePictureURL'] ?? '',
        starCount: parsedJson['starCount'] ?? 0.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'authorID': authorID,
      'content': content,
      'createdAt': createdAt,
      'firstName': firstName,
      'lastName': lastName,
      'listingID': listingID,
      'profilePictureURL': profilePictureURL,
      'starCount': starCount
    };
  }
}
