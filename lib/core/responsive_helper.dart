import 'package:flutter/material.dart';

class ResponsiveHelper {
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isSmallScreen(BuildContext context) {
    return getScreenWidth(context) < 360;
  }

  static bool isMediumScreen(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= 360 && width < 768;
  }

  static bool isLargeScreen(BuildContext context) {
    return getScreenWidth(context) >= 768;
  }

  // Dinamik padding değerleri
  static EdgeInsets getScreenPadding(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) {
      return const EdgeInsets.all(8.0); // Küçük ekran
    } else if (width < 400) {
      return const EdgeInsets.all(12.0); // Orta ekran
    } else {
      return const EdgeInsets.all(16.0); // Büyük ekran
    }
  }

  // Dinamik font boyutları
  static double getTitleFontSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return 14.0;
    if (width < 400) return 16.0;
    return 18.0;
  }

  static double getSubtitleFontSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return 12.0;
    if (width < 400) return 14.0;
    return 16.0;
  }

  static double getBodyFontSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return 11.0;
    if (width < 400) return 12.0;
    return 14.0;
  }

  // Dinamik spacing
  static double getVerticalSpacing(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return 8.0;
    if (width < 400) return 12.0;
    return 16.0;
  }

  static double getHorizontalSpacing(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return 6.0;
    if (width < 400) return 8.0;
    return 12.0;
  }

  // Form field yüksekliği
  static double getFormFieldHeight(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return 48.0;
    if (width < 400) return 52.0;
    return 56.0;
  }

  // Icon boyutları
  static double getIconSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return 20.0;
    if (width < 400) return 22.0;
    return 24.0;
  }

  // Button height
  static double getButtonHeight(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return 44.0;
    if (width < 400) return 48.0;
    return 52.0;
  }

  // Dinamik grid column sayısı
  static int getGridColumnCount(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return 1;
    if (width < 600) return 2;
    return 3;
  }

  // Minimum dokunma alanı
  static double getMinTouchTarget(BuildContext context) {
    return 44.0; // Material Design standart minimum
  }
}