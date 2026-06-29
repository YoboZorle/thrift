import 'package:url_launcher/url_launcher.dart';

import '../constants/app_config.dart';

/// Opens a direct WhatsApp chat with the admin for support and reporting.
/// No backend involved — it just deep-links into WhatsApp with a pre-filled
/// message the user can send straight to the admin.
class Support {
  Support._();

  static Future<bool> contactAdmin({String message = ''}) async {
    final query = message.isEmpty ? '' : '?text=${Uri.encodeComponent(message)}';
    final uri = Uri.parse('https://wa.me/${AppConfig.adminWhatsAppNumber}$query');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static String generalHelp() =>
      'Hi ${AppConfig.supportName}, I need help with ThriftSwap.';

  static String reportUser(String name, String id) =>
      'Hi ${AppConfig.supportName}, I want to report a user on ThriftSwap.\n'
      'User: $name (id: $id)\n'
      'Reason: ';

  static String reportListing(String title, String id) =>
      'Hi ${AppConfig.supportName}, I want to report a listing on ThriftSwap.\n'
      'Item: $title (id: $id)\n'
      'Reason: ';
}
