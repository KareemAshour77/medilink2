// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../core/widgets/lang_toggle_button.dart';
import '../../auth/screens/welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Page(
        imagePath: context.isDark
            ? 'assets/images/messagew.png'
            : 'assets/images/messageb.png',
        color: AppColors.bop,
        title: context.l.onboarding1Title,
        desc: context.l.onboarding1Desc,
        width: 160,
        height: 160,
      ),
      _Page(
        imagePath: context.isDark
            ? 'assets/images/locw.png'
            : 'assets/images/locb.png',
        color: AppColors.bop,
        title: context.l.onboarding2Title,
        desc: context.l.onboarding2Desc,
        width: 160,
        height: 160,
      ),
      _Page(
        imagePath: context.isDark
            ? 'assets/images/notification white.png'
            : 'assets/images/notification black.png',
        color: AppColors.bop,
        title: context.l.onboarding3Title,
        desc: context.l.onboarding3Desc,
        width: 160,
        height: 160,
      ),
      _Page(
        imagePath: context.isDark
            ? 'assets/images/medical-record white.png'
            : 'assets/images/medical-record black.png',
        color: AppColors.bop,
        title: context.l.onboarding4Title,
        desc: context.l.onboarding4Desc,
        width: 180,
        height: 180,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  LangToggleButton(),
                  SizedBox(width: 8),
                  ThemeToggleButton(),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: pages.length,
                itemBuilder: (_, i) => _PageView(data: pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: pages.length,
                    effect: WormEffect(
                      dotColor: AppColors.grey.withOpacity(0.3),
                      activeDotColor: AppColors.primary,
                      dotHeight: 8,
                      dotWidth: 8,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () {
                      if (_page < pages.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WelcomeScreen(),
                          ),
                        );
                      }
                    },
                    child: Text(
                      _page == pages.length - 1
                          ? context.l.getStarted
                          : context.l.next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  final _Page data;

  const _PageView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: data.width,
            height: data.height,
            decoration: BoxDecoration(
              color: data.color.withOpacity(
                context.isDark ? 0.12 : 0.20,
              ),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Image.asset(
                data.imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 44),
          Text(
            data.title,
            style: TextStyle(
              color: context.text,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _Page {
  final String imagePath;
  final Color color;
  final String title;
  final String desc;
  final double width;
  final double height;

  const _Page({
    required this.imagePath,
    required this.color,
    required this.title,
    required this.desc,
    this.width = 160,
    this.height = 160,
  });
}
