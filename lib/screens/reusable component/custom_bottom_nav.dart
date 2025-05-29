import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

// Modern Glassmorphic Bottom Navigation with FAB
class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback? onFabPressed;
  final String? fabLabel;
  final IconData? fabIcon;

  const CustomBottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.onFabPressed,
    this.fabLabel,
    this.fabIcon,
  }) : super(key: key);

  final Color primaryColor = const Color(0xFF008080); // Original teal
  final Color accentColor = const Color(0xFF006666); // Darker teal accent

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Glassmorphic container
        Container(
          height: 87, // Reduced from 85
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 32,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: primaryColor.withOpacity(0.12),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Reduced from 12
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModernNavItem(Icons.home_filled, "Home", 0),
                  _buildModernNavItem(Icons.storefront_rounded, "Stores", 1),
                  if (onFabPressed != null) const SizedBox(width: 60),
                  _buildSvgNavItem("assets/order.svg", "Orders", onFabPressed != null ? 2 : 1),
                  _buildModernNavItem(Icons.person_rounded, "Profile", onFabPressed != null ? 3 : 2),
                ],
              ),
            ),
          ),
        ),
        // Modern FAB
        if (onFabPressed != null)
          Positioned(
            top: -20,
            child: _buildModernFAB(context),
          ),
      ],
    );
  }

  Widget _buildModernFAB(BuildContext context) {
    return GestureDetector(
      onTap: onFabPressed,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    accentColor,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated background circle
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 2 * math.pi),
                    duration: const Duration(seconds: 8),
                    builder: (context, double angle, child) {
                      return Transform.rotate(
                        angle: angle,
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.transparent,
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Main icon
                  Icon(
                    fabIcon ?? Icons.add_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernNavItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onItemTapped(index),
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Color.lerp(
                  Colors.transparent,
                  primaryColor.withOpacity(0.12),
                  value,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 1 + (value * 0.15),
                    child: Icon(
                      icon,
                      size: 26,
                      color: Color.lerp(
                        Colors.grey.shade500,
                        primaryColor,
                        value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: Color.lerp(
                        Colors.grey.shade500,
                        primaryColor,
                        value,
                      ),
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSvgNavItem(String assetPath, String label, int index) {
    final isSelected = selectedIndex == index;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onItemTapped(index),
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Color.lerp(
                  Colors.transparent,
                  primaryColor.withOpacity(0.12),
                  value,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 1 + (value * 0.15),
                    child: SvgPicture.asset(
                      assetPath,
                      height: 26,
                      width: 26,
                      colorFilter: ColorFilter.mode(
                        Color.lerp(
                          Colors.grey.shade500,
                          primaryColor,
                          value,
                        )!,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: Color.lerp(
                        Colors.grey.shade500,
                        primaryColor,
                        value,
                      ),
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Neumorphic Style Bottom Navigation
class CustomBottomNavWithFAB extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavWithFAB({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  final Color primaryColor = const Color(0xFF008080); // Original teal
  final Color backgroundColor = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60, // Reduced from 90
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          // Outer shadow (dark)
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(8, 8),
            blurRadius: 24,
            spreadRadius: 0,
          ),
          // Inner shadow (light)
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            offset: const Offset(-8, -8),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Reduced from 12
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNeumorphicItem(Icons.home_filled, "Home", 0),
              _buildNeumorphicItem(Icons.storefront_rounded, "Stores", 1),
              _buildSvgNeumorphicItem("assets/inventory.svg", "Inventory", 2),
              _buildNeumorphicItem(Icons.person_rounded, "Profile", 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
              // Inset shadow effect for selected state
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(4, 4),
                blurRadius: 8,

              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                offset: const Offset(-4, -4),
                blurRadius: 8,

              ),
            ]
                : [
              // Raised effect for unselected state
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(2, 2),
                blurRadius: 6,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.9),
                offset: const Offset(-2, -2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? primaryColor : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? primaryColor : Colors.grey.shade600,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSvgNeumorphicItem(String assetPath, String label, int index) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(4, 4),
                blurRadius: 8,

              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                offset: const Offset(-4, -4),
                blurRadius: 8,

              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(2, 2),
                blurRadius: 6,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.9),
                offset: const Offset(-2, -2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                child: SvgPicture.asset(
                  assetPath,
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    isSelected ? primaryColor : Colors.grey.shade600,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? primaryColor : Colors.grey.shade600,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Minimal Floating Bottom Navigation
class PillShapedBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const PillShapedBottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  final Color primaryColor = const Color(0xFF008080); // Original teal
  final Color accentColor = const Color(0xFF006666); // Darker teal

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60, // Reduced from 70
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMinimalItem(Icons.home_filled, 0),
              _buildMinimalItem(Icons.storefront_rounded, 1),
              _buildSvgMinimalItem("assets/order.svg", 2),
              _buildMinimalItem(Icons.person_rounded, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalItem(IconData icon, int index) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: AnimatedScale(
          scale: isSelected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            icon,
            size: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSvgMinimalItem(String assetPath, int index) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: AnimatedScale(
          scale: isSelected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: SvgPicture.asset(
            assetPath,
            height: 24,
            width: 24,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

// Morphing Bottom Navigation with Liquid Animation
class LineIndicatorBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const LineIndicatorBottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  final Color primaryColor = const Color(0xFF008080); // Original teal
  final Color backgroundColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60, // Reduced from 80
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Animated background blob
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              left: _getSelectedPosition(context),
              top: 20,
              child: Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.2),
                      primaryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            // Navigation items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMorphingItem(Icons.home_filled, "Home", 0),
                  _buildMorphingItem(Icons.storefront_rounded, "Stores", 1),
                  _buildSvgMorphingItem("assets/order.svg", "Orders", 2),
                  _buildMorphingItem(Icons.person_rounded, "Profile", 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getSelectedPosition(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 64) / 4; // 32px padding on each side
    return 16 + (itemWidth * selectedIndex) + (itemWidth - 60) / 2;
  }

  Widget _buildMorphingItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onItemTapped(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                transform: Matrix4.identity()
                  ..scale(isSelected ? 1.3 : 1.0)
                  ..translate(0.0, isSelected ? -4.0 : 0.0),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? primaryColor : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.6,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? primaryColor : Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSvgMorphingItem(String assetPath, String label, int index) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onItemTapped(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                transform: Matrix4.identity()
                  ..scale(isSelected ? 1.3 : 1.0)
                  ..translate(0.0, isSelected ? -4.0 : 0.0),
                child: SvgPicture.asset(
                  assetPath,
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    isSelected ? primaryColor : Colors.grey.shade400,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.6,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? primaryColor : Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}