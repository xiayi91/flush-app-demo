import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart' as geo;
import 'package:location/location.dart' as loc;

import 'package:progress_dialog/progress_dialog.dart';

String? validateName(String? value) {
  String pattern = r'(^[a-zA-Z ]*$)';
  RegExp regExp = RegExp(pattern);
  if (value?.isEmpty ?? true) {
    return 'Name is required'.tr();
  } else if (!regExp.hasMatch(value ?? '')) {
    return 'Name must be valid'.tr();
  }
  return null;
}

String? validateMobile(String? value) {
  String pattern = r'(^\+?[0-9]*$)';
  RegExp regExp = RegExp(pattern);
  if (value?.isEmpty ?? true) {
    return 'Mobile is required'.tr();
  } else if (!regExp.hasMatch(value ?? '')) {
    return 'Mobile Number must be digits'.tr();
  }
  return null;
}

String? validatePassword(String? value) {
  if ((value?.length ?? 0) < 6) {
    return 'Password must be more than 5 characters'.tr();
  } else {
    return null;
  }
}

String? validateEmail(String? value) {
  String pattern =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  RegExp regex = RegExp(pattern);
  if (!regex.hasMatch(value ?? '')) {
    return 'Enter valid E-mail'.tr();
  } else {
    return null;
  }
}

String? validateConfirmPassword(String? password, String? confirmPassword) {
  if (password != confirmPassword) {
    return 'Password doesn\'t match'.tr();
  } else if (confirmPassword?.isEmpty ?? true) {
    return 'Confirm password is required'.tr();
  } else {
    return null;
  }
}

//helper method to show progress
ProgressDialog? progressDialog;

showProgress(BuildContext context, String message, bool isDismissible,
    Color colorPrimary) async {
  progressDialog = ProgressDialog(context,
      type: ProgressDialogType.Normal, isDismissible: true);
  progressDialog!.style(
      message: message,
      borderRadius: 10.0,
      backgroundColor: colorPrimary,
      progressWidget: Container(
          padding: const EdgeInsets.all(8.0),
          child: CircularProgressIndicator.adaptive(
            backgroundColor: Colors.white,
            valueColor: AlwaysStoppedAnimation(colorPrimary),
          )),
      elevation: 10.0,
      insetAnimCurve: Curves.easeInOut,
      messageTextStyle: const TextStyle(
          color: Colors.white, fontSize: 19.0, fontWeight: FontWeight.w600));
  await progressDialog!.show();
}

updateProgress(String message) {
  progressDialog?.update(message: message);
}

hideProgress() async {
  await progressDialog?.hide();
}

//helper method to show alert dialog
showAlertDialog(BuildContext context, String title, String content) async {
  if (Platform.isIOS) {
    await showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              child: const Text('OK').tr(),
              onPressed: () => Navigator.pop(context))
        ],
      ),
    );
  } else {
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              child: const Text('OK').tr(),
              onPressed: () => Navigator.pop(context))
        ],
      ),
    );
  }
}

pushReplacement(BuildContext context, Widget destination) async =>
    await Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => destination));

push(BuildContext context, Widget destination) async =>
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => destination));

pushAndRemoveUntil(
        BuildContext context, Widget destination, bool predict) async =>
    await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => destination),
        (Route<dynamic> route) => predict);

String formatReviewTimestamp(int seconds) {
  var format = DateFormat('yMd');
  var date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  return format.format(date);
}

String formatTimestamp(int seconds, {bool lastSeen = false}) {
  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  DateTime now = DateTime.now();
  DateTime justNow = now.subtract(const Duration(minutes: 1));
  DateTime localDateTime = dateTime.toLocal();
  if (!localDateTime.difference(justNow).isNegative) {
    return 'Just now'.tr();
  }
  String roughTimeString = DateFormat('jm').format(dateTime);
  if (localDateTime.day == now.day &&
      localDateTime.month == now.month &&
      localDateTime.year == now.year) {
    return '${lastSeen ? 'on '.tr() : ''}$roughTimeString';
  }
  if (now.difference(localDateTime).inDays < 4) {
    String weekday = DateFormat('EEE').format(localDateTime);
    return '${lastSeen ? 'on '.tr() : ''}$weekday';
  }
  String date = DateFormat('MMM d').format(localDateTime);
  return '${lastSeen ? 'on '.tr() : ''}$date';
}

Widget displayImage(String picUrl, {bool hideErrorWidget = false}) {
  if (picUrl.isNotEmpty) {
    return CachedNetworkImage(
        imageBuilder: (context, imageProvider) =>
            _getFlatImageProvider(imageProvider),
        imageUrl: picUrl,
        placeholder: (context, url) => _getFlatPlaceholderOrErrorImage(true),
        errorWidget: (context, url, error) => hideErrorWidget
            ? Container()
            : _getFlatPlaceholderOrErrorImage(false));
  } else {
    return _getFlatPlaceholderOrErrorImage(false);
  }
}

Widget _getFlatPlaceholderOrErrorImage(bool placeholder) => SizedBox(
      child: placeholder
          ? const Center(child: CircularProgressIndicator.adaptive())
          : Image.asset(
              'assets/images/error_image.png',
              fit: BoxFit.cover,
            ),
    );

Widget _getFlatImageProvider(ImageProvider provider) {
  return SizedBox(
    child: FadeInImage(
        fit: BoxFit.cover,
        placeholder: Image.asset(
          'assets/images/img_placeholder.png',
          fit: BoxFit.cover,
        ).image,
        image: provider),
  );
}

Widget displayCircleImage(String picUrl, double size, hasBorder) {
  if (picUrl.isNotEmpty) {
    return CachedNetworkImage(
        height: size,
        width: size,
        imageBuilder: (context, imageProvider) =>
            _getCircularImageProvider(imageProvider, size, false),
        imageUrl: picUrl,
        placeholder: (context, url) =>
            _getPlaceholderOrErrorImage(size, hasBorder),
        errorWidget: (context, url, error) =>
            _getPlaceholderOrErrorImage(size, hasBorder));
  } else {
    return _getPlaceholderOrErrorImage(size, hasBorder);
  }
}

Widget _getPlaceholderOrErrorImage(double size, hasBorder) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(size / 2)),
        border: Border.all(
          color: Colors.white,
          style: hasBorder ? BorderStyle.solid : BorderStyle.none,
          width: 2.0,
        ),
      ),
      child: ClipOval(
          child: Image.asset(
        'assets/images/placeholder.jpg',
        fit: BoxFit.cover,
        height: size,
        width: size,
      )),
    );

Widget _getCircularImageProvider(
    ImageProvider provider, double size, bool hasBorder) {
  return ClipOval(
      child: Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(size / 2)),
        border: Border.all(
          color: Colors.white,
          style: hasBorder ? BorderStyle.solid : BorderStyle.none,
          width: 2.0,
        ),
        image: DecorationImage(
          image: provider,
          fit: BoxFit.cover,
        )),
  ));
}

bool isDarkMode(BuildContext context) =>
    Theme.of(context).brightness != Brightness.light;

Future<geo.Position?> getCurrentLocation() async {
  bool serviceEnabled;
  geo.LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    loc.Location location = loc.Location();
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      return null;
      // Future.error('Location services are disabled.'.tr());
    }
  }

  permission = await geo.Geolocator.checkPermission();
  if (permission == geo.LocationPermission.denied) {
    permission = await geo.Geolocator.requestPermission();
    if (permission == geo.LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return null;
      // Future.error('Location permissions are denied'.tr());
    }
  }

  if (permission == geo.LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return null;
    // Future.error(
    //     'Location permissions are permanently denied, we cannot request permissions.'
    //         .tr());
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  geo.Position? position;
  try {
    position = await geo.Geolocator.getCurrentPosition(
        forceAndroidLocationManager: true,
        timeLimit: const Duration(seconds: 5),
        desiredAccuracy: geo.LocationAccuracy.best);
  } catch (e) {
    try {
      loc.Location location = loc.Location();
      var locationResult = await location.getLocation();
      position = geo.Position(
        accuracy: locationResult.accuracy ?? 0,
        altitude: locationResult.altitude ?? 0,
        heading: locationResult.heading ?? 0,
        latitude: locationResult.latitude ?? 0,
        longitude: locationResult.longitude ?? 0,
        speed: locationResult.speed ?? 0,
        speedAccuracy: locationResult.speedAccuracy ?? 0,
        timestamp: DateTime.now(),
      );
    } catch (e, s) {
      debugPrint('Couldn\'t get user current location $e $s');
    }
  }
  return position;
}

String updateTime(int timer) {
  Duration callDuration = Duration(seconds: timer);
  String twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }

  String twoDigitsHours(int n) {
    if (n >= 10) return '$n:';
    if (n == 0) return '';
    return '0$n:';
  }

  String twoDigitMinutes = twoDigits(callDuration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(callDuration.inSeconds.remainder(60));
  return '${twoDigitsHours(callDuration.inHours)}$twoDigitMinutes:$twoDigitSeconds';
}

Widget showEmptyState(String title, String description,
    {String? buttonTitle,
    bool? isDarkMode,
    VoidCallback? action,
    Color? colorPrimary}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(height: 30),
      Text(title,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
      const SizedBox(height: 15),
      Text(
        description,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 17),
      ),
      const SizedBox(height: 25),
      if (action != null)
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: double.infinity),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  backgroundColor: colorPrimary ?? Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: action,
                child: Text(
                  buttonTitle ?? 'Empty State Action',
                  style: TextStyle(
                      color: isDarkMode ?? false ? Colors.black : Colors.white,
                      fontSize: 18),
                )),
          ),
        ),
    ],
  );
}

InputDecoration getInputDecoration(
    {required String hint,
    required bool darkMode,
    required Color errorColor,
    required Color colorPrimary}) {
  return InputDecoration(
    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    fillColor: darkMode ? Colors.black54 : Colors.white,
    hintText: hint,
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: BorderSide(color: colorPrimary, width: 2.0)),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: errorColor),
      borderRadius: BorderRadius.circular(25.0),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: errorColor),
      borderRadius: BorderRadius.circular(25.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade200),
      borderRadius: BorderRadius.circular(25.0),
    ),
  );
}

showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
}

String orderDate(Timestamp timestamp) {
  return DateFormat('EEE MMM d yyyy').format(
      DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch));
}

// SHOPERTINO_FLAG_ENABLED_END
extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
// SHOPERTINO_FLAG_ENABLED_END
