import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/teritory_theme.dart';

class InfoSection {
  final String heading;
  final String body;

  const InfoSection(this.heading, this.body);
}

/// Static About / Terms / Privacy copy. Facts only: what the app does and which
/// data the backend stores today.
class InfoPageScreen extends StatelessWidget {
  const InfoPageScreen({
    super.key,
    required this.title,
    required this.sections,
  });

  final String title;
  final List<InfoSection> sections;

  factory InfoPageScreen.about() {
    return const InfoPageScreen(
      title: 'About Teritory',
      sections: [
        InfoSection(
          'Your map, your crew',
          'Teritory is a travel-footprint app. You drop flags on places you have '
              'been, plan trips with your clans and see where friends have been.',
        ),
        InfoSection(
          'What is live today',
          'Explore, clans, communities and chat, trip planning and tracking, '
              'rankings, profiles and friends all read and write through the '
              'Teritory API.',
        ),
        InfoSection(
          'Version',
          'Build ${AppConfig.appVersion}. The map uses OpenStreetMap tiles; '
              'place data comes from the Teritory backend.',
        ),
      ],
    );
  }

  factory InfoPageScreen.terms() {
    return const InfoPageScreen(
      title: 'Terms of Service',
      sections: [
        InfoSection(
          'Using Teritory',
          'Sign in with a phone number you control. You are responsible for '
              'what you post: flag notes, chat messages, clan and community '
              'content.',
        ),
        InfoSection(
          'Content you add',
          'Flags, notes and messages you add are visible to other travelers '
              'according to your profile privacy setting and the community you '
              'post in.',
        ),
        InfoSection(
          'Location',
          'Flags store the coordinates you choose. Teritory does not track your '
              'position in the background; trip waypoint checks use the '
              'coordinates submitted by your device.',
        ),
        InfoSection(
          'Changes',
          'Features and these terms can change as the app is developed. '
              'Questions: support@teritory.app.',
        ),
      ],
    );
  }

  factory InfoPageScreen.privacy() {
    return const InfoPageScreen(
      title: 'Privacy Policy',
      sections: [
        InfoSection(
          'What we store',
          'Your phone number and handle, the profile fields you fill in, flags '
              'and comments you create, your clan and community memberships, '
              'trips and trip plans, and friendship relationships.',
        ),
        InfoSection(
          'Who can see it',
          'Your profile and footprint are visible to other travelers unless the '
              'private profile switch is on. Chat is limited to community '
              'members.',
        ),
        InfoSection(
          'Sign-in data',
          'Sessions use short-lived access tokens plus a refresh token stored on '
              'this device. Logging out revokes the refresh token server-side.',
        ),
        InfoSection(
          'Deleting data',
          'The backend does not expose account deletion yet, so the Delete '
              'Account action in Settings stays disabled. Contact '
              'support@teritory.app to remove an account.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          for (final section in sections) ...[
            Text(
              section.heading,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              section.body,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.55,
                color: TeritoryColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
