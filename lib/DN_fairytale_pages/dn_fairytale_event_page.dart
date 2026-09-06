import 'package:flutter/material.dart';

import 'dn_fairytale_paycam_page.dart';

class DnFairytaleEventPage extends StatelessWidget {
  const DnFairytaleEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DnFairytalePayCamPage(
      pageTitle: 'Join Us Here',
      pageSubtitle: 'Select your flat ID to view event payment details.',
      heroTitle: 'Join Us Here',
      heroSubtitle: 'Celebrate together at DN Fairytale.',
      eventMode: true,
    );
  }
}
