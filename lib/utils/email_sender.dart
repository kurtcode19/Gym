import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

Future<void> sendExpiryEmail({
  required String email,
  required String memberName,
  required DateTime expiryDate,
}) async {
  final formatted = DateFormat('MMM d, yyyy').format(expiryDate);

  final subject = Uri.encodeComponent("Membership Expiring Soon");
  final body = Uri.encodeComponent("""
Dear $memberName,

We hope you're doing well!

This is a friendly reminder that your gym membership is expiring soon.
Your current membership will officially expire on $formatted.

To avoid interruption in access to the gym facilities, please visit the front desk or contact us any time to renew.

Thank you!
- Gym Management
""");

  final uri = "mailto:$email?subject=$subject&body=$body";

  if (await canLaunchUrl(Uri.parse(uri))) {
    await launchUrl(Uri.parse(uri));
  } else {
    throw "Could not open email client.";
  }
}
