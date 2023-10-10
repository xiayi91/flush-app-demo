import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          String url = 'tel:12345678';
          launchUrl(Uri.parse(url));
        },
        backgroundColor: Color(colorAccent),
        child: Icon(
          Icons.call,
          color: isDarkMode(context) ? Colors.black : Colors.white,
        ),
      ),
      appBar: AppBar(
        backgroundColor: Color(colorPrimary),
        iconTheme: IconThemeData(
            color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white),
        title: Text(
          'Contact Us',
          style: TextStyle(
              color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white,
              fontWeight: FontWeight.bold),
        ).tr(),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Material(
            elevation: 2,
            color: isDarkMode(context) ? Colors.black54 : Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(right: 16.0, left: 16, top: 16),
                  child: Text(
                    'Our Address',
                    style: TextStyle(
                        color:
                            isDarkMode(context) ? Colors.white : Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ).tr(),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      right: 16.0, left: 16, top: 16, bottom: 16),
                  child: const Text(
                          '1412 Steiner Street, San Francisco, CA, 94115')
                      .tr(),
                ),
                ListTile(
                  onTap: () async {
                    var url =
                        'mailto:support@instamobile.zendesk.com?subject=Instaflutter-contact-ticket';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    } else {
                      if (!mounted) return;
                      showAlertDialog(context, 'Couldn\'t send email'.tr(),
                          'There is no mailing app installed'.tr());
                    }
                  },
                  title: Text(
                    'E-mail us',
                    style: TextStyle(
                        color:
                            isDarkMode(context) ? Colors.white : Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ).tr(),
                  subtitle: const Text('support@instamobile.zendesk.com'),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color:
                        isDarkMode(context) ? Colors.white54 : Colors.black54,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
