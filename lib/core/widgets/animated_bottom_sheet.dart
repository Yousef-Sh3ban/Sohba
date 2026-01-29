// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║                     ANIMATED BOTTOM SHEET                                  ║
// ║  Utility لعرض Bottom Sheet مع animations سلسة                              ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Extension على BuildContext لتسهيل استخدام الـ AnimatedBottomSheet
extension AnimatedBottomSheetExtension on BuildContext {
  /// عرض bottom sheet مع animations
  Future<T?> showAnimatedSheet<T>({
    required Widget Function(BuildContext) builder,
    bool isScrollControlled = true,
    bool useSafeArea = true,
    Color? backgroundColor,
    ShapeBorder? shape,
  }) {
    return showAnimatedBottomSheet<T>(
      context: this,
      builder: builder,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      backgroundColor: backgroundColor,
      shape: shape,
    );
  }
}

/// عرض Bottom Sheet مع animations سلسة
///
/// **للتحكم في سرعة ظهور الـ Sheet:**
/// استخدم `slideDuration` parameter:
/// ```dart
/// showAnimatedBottomSheet(
///   context: context,
///   slideDuration: Duration(milliseconds: 600), // أبطأ
///   builder: (ctx) => YourSheet(),
/// );
/// ```
///
/// **القيم المقترحة:**
/// - سريع: 300-400ms
/// - متوسط (default): 500ms
/// - بطيء وناعم: 600-800ms
Future<T?> showAnimatedBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  Duration slideDuration = const Duration(milliseconds: 500),
}) {
  final theme = Theme.of(context);

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: backgroundColor ?? theme.colorScheme.surface,
    shape:
        shape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
    // استخدام الـanimation الافتراضي من Flutter - أسرع وأكثر استقراراً
    transitionAnimationController: null,
    builder: builder,
  );
}

/// Widget يضيف staggered animations لمحتوى الـ Bottom Sheet
///
/// استخدمه داخل الـ Bottom Sheet لإضافة animations تلقائية:
/// ```dart
/// AnimatedSheetContent(
///   child: Column(
///     children: [
///       SheetHandle(),
///       SheetHeader(...),
///       // ...
///     ],
///   ),
/// )
/// ```
class AnimatedSheetContent extends StatelessWidget {
  final Widget child;
  final Duration initialDelay;
  final Duration fadeInDuration;
  final Duration slideUpDuration;
  final Curve curve;

  const AnimatedSheetContent({
    super.key,
    required this.child,
    this.initialDelay = Duration.zero,
    this.fadeInDuration = const Duration(milliseconds: 350),
    this.slideUpDuration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutQuart,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: initialDelay)
        .fadeIn(duration: fadeInDuration, curve: curve)
        .slideY(begin: 0.05, end: 0, duration: slideUpDuration, curve: curve);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Common Sheet Components with Animations
// ════════════════════════════════════════════════════════════════════════════

/// المقبض (Handle) للـ Bottom Sheet مع animation
///
/// **للتحكم في السرعة:**
/// - `delay`: بداية الـ animation (default: 0ms)
/// - `fadeIn duration`: سرعة الظهور (default: 300ms)
/// - `scaleX duration`: سرعة التوسع الأفقي (default: 350ms)
class SheetHandle extends StatelessWidget {
  final Duration delay;
  final Color? color;

  const SheetHandle({super.key, this.delay = Duration.zero, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: color ?? colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )
        .animate(delay: delay)
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .scaleX(
          begin: 0.5,
          end: 1,
          duration: 350.ms, // سرعة توسع المقبض
          curve: Curves.easeOutBack,
        );
  }
}

/// رأس الـ Sheet (أيقونة + عنوان + وصف) مع animations
///
/// **للتحكم في السرعة:**
/// - `delay`: بداية الـ animation (default: 100ms)
/// - Icon: scale 450ms + fade 350ms
/// - Title: slide + fade 400ms (delay +80ms)
/// - Subtitle: slide + fade 350ms (delay +150ms)
class SheetHeader extends StatelessWidget {
  final IconData icon;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final Duration delay;

  const SheetHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconBackgroundColor,
    this.iconColor,
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Icon Container
        Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor ?? colorScheme.primary),
            )
            .animate(delay: delay)
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 450.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 350.ms),

        const SizedBox(width: 16),

        // Title & Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge)
                  .animate(delay: delay + 80.ms)
                  .fadeIn(duration: 400.ms)
                  .slideX(
                    begin: 0.1,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutQuart,
                  ),
              Text(subtitle, style: theme.textTheme.bodySmall)
                  .animate(delay: delay + 150.ms)
                  .fadeIn(duration: 350.ms)
                  .slideX(
                    begin: 0.1,
                    end: 0,
                    duration: 350.ms,
                    curve: Curves.easeOutQuart,
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// حقل إدخال Form مع animation
///
/// **للتحكم في السرعة:**
/// - `delay`: بداية الـ animation (default: 250ms)
/// - fade: 400ms
/// - slideY: 450ms (المسافة: 15% من الأسفل)
class AnimatedFormField extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const AnimatedFormField({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 250),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.15, // المسافة من الأسفل (15% من الارتفاع)
          end: 0,
          duration: 450.ms, // سرعة الحركة للأعلى
          curve: Curves.easeOutQuart,
        );
  }
}

/// زر الـ Action مع animation
///
/// **للتحكم في السرعة:**
/// - `delay`: بداية الـ animation (default: 350ms)
/// - fade: 400ms
/// - slideY: 500ms مع bounce effect (easeOutBack)
class AnimatedActionButton extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const AnimatedActionButton({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.2, // المسافة من الأسفل (20%)
          end: 0,
          duration: 500.ms, // سرعة الحركة للأعلى
          curve: Curves.easeOutBack, // تأثير bounce خفيف
        );
  }
}

/// ملاحظة/معلومة مع animation
///
/// **للتحكم في السرعة:**
/// - `delay`: بداية الـ animation (default: 420ms)
/// - fade: 350ms
/// - slideY: 400ms (المسافة: 10%)
class AnimatedInfoBox extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const AnimatedInfoBox({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 350),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.1, // المسافة من الأسفل (10%)
          end: 0,
          duration: 400.ms, // سرعة الحركة للأعلى
          curve: Curves.easeOutQuart,
        );
  }
}
