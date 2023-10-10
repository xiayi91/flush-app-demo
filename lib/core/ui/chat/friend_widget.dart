import 'package:flutter/material.dart';
import 'package:instaflutter/core/model/user.dart';
import 'package:instaflutter/core/utils/helper.dart';

class FriendWidget extends StatelessWidget {
  final User friend;

  const FriendWidget({Key? key, required this.friend}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 4, right: 4),
      child: Column(
        children: [
          displayCircleImage(friend.profilePictureURL, 50, false),
          Expanded(
            child: SizedBox(
              width: 75,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8, right: 8),
                child: Text(
                  friend.firstName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
