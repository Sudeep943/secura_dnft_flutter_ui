import 'package:flutter/material.dart';

import 'dn_fairytale_paycam_page.dart';

class DnFairytaleEventPage extends StatelessWidget {
  const DnFairytaleEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DnFairytalePayCamPage(
      pageTitle: 'Dandiya Night',
      pageSubtitle: 'Coming Soon. More event details will be shared soon.',
      heroTitle: 'Dandiya Night',
      heroSubtitle: 'An evening of music, dance, and celebration.',
      eventMode: true,
    );
  }
}
