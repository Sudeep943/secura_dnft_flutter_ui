import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../pages/login_page.dart';
import 'dn_fairytale_paycam_page.dart';

class DnFairytaleLandingPage extends StatefulWidget {
  const DnFairytaleLandingPage({super.key});

  @override
  State<DnFairytaleLandingPage> createState() => _DnFairytaleLandingPageState();
}

class _DnFairytaleLandingPageState extends State<DnFairytaleLandingPage>
    with SingleTickerProviderStateMixin {
  static const Color _brandTeal = Color(0xFF0F8F82);
  static const Color _brandNavy = Color(0xFF112B3A);
  static const Color _brandGold = Color(0xFFC7A76C);

  final PageController _heroController = PageController();
  Timer? _slideTimer;
  late final AnimationController _logoBorderController;
  int _heroIndex = 0;

  final List<String> _heroImages = const [
    'DNFarytaleIamges/image1.jpg',
    'DNFarytaleIamges/image2.jpg',
    'DNFarytaleIamges/image3.jpg',
    'DNFarytaleIamges/image4.jpg',
    'DNFarytaleIamges/image5.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _logoBorderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _slideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_heroController.hasClients || _heroImages.isEmpty) {
        return;
      }

      final next = (_heroIndex + 1) % _heroImages.length;
      _heroController.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _logoBorderController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  void _openLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  void _openPayCam() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DnFairytalePayCamPage()));
  }

  Widget _buildSectionTitle(String eyebrow, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF2E9D8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF66502A),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            height: 1.08,
            fontWeight: FontWeight.w700,
            color: Color(0xFF152738),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 15,
            height: 1.65,
            color: Color(0xFF526275),
          ),
        ),
      ],
    );
  }

  Widget _featureTile(IconData icon, String title, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE9EC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F3F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _brandTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF132437),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF596A79),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetSlide(String assetPath) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2A3E53), Color(0xFF101C2A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 52,
                  color: Colors.white70,
                ),
              ),
            );
          },
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromRGBO(0, 0, 0, 0.44), Color(0x00000000)],
              begin: Alignment.bottomCenter,
              end: Alignment.center,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x332FC7A1), Color(0x0034D4AC)],
                ),
              ),
            ),
          ),
          Positioned(
            right: -130,
            top: 280,
            child: Container(
              width: 360,
              height: 360,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x334A80B8), Color(0x004A80B8)],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 18),
                    child: Container(
                      height: screenWidth < 700 ? 330 : 470,
                      decoration: BoxDecoration(
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(17, 43, 58, 0.14),
                            blurRadius: 42,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipRect(
                        child: AnimatedBuilder(
                          animation: _logoBorderController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _RunningBorderPainter(
                                progress: _logoBorderController.value,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      'DNFarytaleIamges/HD DN.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildAssetSlide(_heroImages.first),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: screenWidth < 700 ? 220 : 290,
                      height: screenWidth < 700 ? 88 : 104,
                      child: Image.asset(
                        'DNFarytaleIamges/dn_fairytale_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 980;
                      return compact
                          ? Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: _buildAboutSection(),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: _buildCamSection(),
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildAboutSection()),
                                const SizedBox(width: 24),
                                Expanded(child: _buildCamSection()),
                              ],
                            );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  width: double.infinity,
                  height: screenWidth < 700 ? 260 : 360,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: PageView.builder(
                          controller: _heroController,
                          onPageChanged: (index) {
                            setState(() {
                              _heroIndex = index;
                            });
                          },
                          itemCount: _heroImages.length,
                          itemBuilder: (_, index) {
                            return _buildAssetSlide(_heroImages[index]);
                          },
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(0, 0, 0, 0.22),
                                Color.fromRGBO(0, 0, 0, 0.05),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _CircularNavButton(
                            icon: Icons.chevron_left_rounded,
                            onPressed: () {
                              final next =
                                  (_heroIndex - 1 + _heroImages.length) %
                                  _heroImages.length;
                              _heroController.animateToPage(
                                next,
                                duration: const Duration(milliseconds: 450),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        right: 14,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _CircularNavButton(
                            icon: Icons.chevron_right_rounded,
                            onPressed: () {
                              final next =
                                  (_heroIndex + 1) % _heroImages.length;
                              _heroController.animateToPage(
                                next,
                                duration: const Duration(milliseconds: 450),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 14,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_heroImages.length, (index) {
                            final active = _heroIndex == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: active ? 20 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 30,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF123246), Color(0xFF0F8F82)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Anything You Need?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Everything you need for elevated, peaceful, and secure living.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 18,
                        runSpacing: 18,
                        children: const [
                          _WhyChip(
                            icon: Icons.emoji_events_outlined,
                            label: 'Amenities',
                          ),
                          _WhyChip(
                            icon: Icons.verified_user_outlined,
                            label: '24/7 Security & Surveillance',
                          ),
                          _WhyChip(
                            icon: Icons.account_balance_outlined,
                            label: 'Infrastructure',
                          ),
                          _WhyChip(
                            icon: Icons.groups_outlined,
                            label: 'Community',
                          ),
                          _WhyChip(
                            icon: Icons.notifications_none_rounded,
                            label: 'Notices & Updates',
                          ),
                          _WhyChip(
                            icon: Icons.event_note_rounded,
                            label: 'Events & Activities',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFEEF4F8),
                  padding: const EdgeInsets.fromLTRB(18, 34, 18, 18),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 900;
                      final cards = [
                        _footerCard(
                          title: 'Stay Connected',
                          body:
                              'Subscribe to get important updates and announcements.',
                          child: _newsletterForm(compact),
                        ),
                        _footerCard(
                          title: 'Quick Links',
                          body: '',
                          child: _quickLinksRow(),
                        ),
                        _footerCard(
                          title: 'Contact Us',
                          body:
                              'DN Fairytale, Madanpur, Jatni, Khurda, 752054\nMail: dnftaoa@gmail.com',
                          child: const SizedBox.shrink(),
                        ),
                      ];

                      if (compact) {
                        return Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 18),
                            cards[1],
                            const SizedBox(height: 18),
                            cards[2],
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 18),
                          Expanded(child: cards[1]),
                          const SizedBox(width: 18),
                          Expanded(child: cards[2]),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: ColoredBox(
                  color: Color(0xFF112B3A),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Center(
                      child: Text(
                        '© 2026 DN Fairytale. All rights reserved.',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(16, 38, 55, 0.08),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'About Us',
            'Welcome to DN Fairytale',
            'Welcome to DN Fairytale — a thoughtfully designed residential community where luxury, comfort, and modern living come together in perfect harmony.\n\nSpread across 8 acres of beautifully planned landscape in the heart of Madanpur, Bhubaneswar, DN Fairytale is home to 708 premium flats crafted to offer a lifestyle filled with elegance, convenience, and peace of mind.\n\nWith 50+ world-class amenities, the community is built to enrich every aspect of everyday living. From landscaped gardens, clubhouse, swimming pool, fitness center, sports courts, children\'s play areas, and jogging tracks to advanced security systems and vibrant community spaces — every detail is designed to create a complete living experience for families of all generations.\n\nAt DN Fairytale, we believe a home is more than just walls and rooms — it is a place where memories are created, friendships grow, and life flourishes. Surrounded by greenery, modern infrastructure, and seamless connectivity to the city, the society offers the perfect balance of urban convenience and serene living.\n\nWhether you seek comfort, community, or a premium lifestyle, DN Fairytale is where your dream home becomes reality.\n\nDN Fairytale — Live the Fairytale.',
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _featureTile(
                Icons.shield_outlined,
                'Safe & Secure Living',
                'Gated access and modern monitoring keep residents protected.',
              ),
              _featureTile(
                Icons.groups_2_outlined,
                'Community Driven',
                'Designed to encourage active community interaction and events.',
              ),
              _featureTile(
                Icons.eco_outlined,
                'Clean & Green Environment',
                'Landscaped zones and open spaces create a refreshing lifestyle.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCamSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFD9E6EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'Pay Your CAM',
            'Contribute to a Safer Tomorrow',
            'CAM (Common Area Maintenance) charges help us maintain security, cleanliness, and all common facilities.',
          ),
          const SizedBox(height: 18),
          const _BulletList(
            items: [
              'Timely maintenance of common areas',
              '24/7 security and surveillance',
              'Cleanliness and hygiene management',
              'Lift, power backup and other essential services',
              'Landscaping and upkeep of green areas',
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _openPayCam,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Pay CAM Now'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _brandTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openLogin,
                  icon: const Icon(Icons.person_outline_rounded),
                  label: const Text('Login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _brandTeal,
                    side: const BorderSide(color: _brandTeal),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerCard({
    required String title,
    required String body,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE6EE)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(17, 43, 58, 0.06),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF132437),
            ),
          ),
          const SizedBox(height: 10),
          if (body.trim().isNotEmpty)
            Text(
              body,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Color(0xFF5C6D7E),
              ),
            ),
          if (body.trim().isNotEmpty) const SizedBox(height: 10),
          if (child is! SizedBox) ...[const SizedBox(height: 12), child],
        ],
      ),
    );
  }

  Widget _quickLinksRow() {
    const textStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF3F5A72),
    );

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: const [
        Text('Home', style: textStyle),
        Text('|', style: textStyle),
        Text('Gallery', style: textStyle),
        Text('|', style: textStyle),
        Text('Return Policy', style: textStyle),
      ],
    );
  }

  Widget _newsletterForm(bool compact) {
    if (compact) {
      return Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter your email',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: _brandTeal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Subscribe'),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Enter your email',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: _brandTeal,
            foregroundColor: Colors.white,
          ),
          child: const Text('Subscribe'),
        ),
      ],
    );
  }
}

class _CircularNavButton extends StatelessWidget {
  const _CircularNavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: _DnFairytaleLandingPageState._brandNavy),
      ),
    );
  }
}

class _WhyChip extends StatelessWidget {
  const _WhyChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 168,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: _DnFairytaleLandingPageState._brandGold,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: _DnFairytaleLandingPageState._brandTeal,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Color(0xFF2E3F4F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RunningBorderPainter extends CustomPainter {
  const _RunningBorderPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final borderRect = rect.deflate(2);

    final glowPaint = Paint()
      ..color = const Color(0x4458D6FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11);
    canvas.drawRect(borderRect, glowPaint);

    final sweep = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      transform: GradientRotation(progress * math.pi * 2),
      colors: const [
        Color(0x0058D6FF),
        Color(0x6658D6FF),
        Color(0xFFFFD88A),
        Color(0x6658D6FF),
        Color(0x0058D6FF),
      ],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
    );

    final borderPaint = Paint()
      ..shader = sweep.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(borderRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _RunningBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
