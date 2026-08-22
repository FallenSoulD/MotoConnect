import 'package:flutter/material.dart';

/// MotoConnect Neumorphic Renk Paleti ve Temel Değerleri
class NeuColors {
  static const Color background = Color(0xFF16171B);
  static const Color surface = Color(0xFF1E2026);
  static const Color surfaceLight = Color(0xFF262931);
  static const Color surfaceDark = Color(0xFF131417);
  
  static const Color lightShadow = Color(0xFF2A2E38);
  static const Color darkShadow = Color(0xFF0C0D0F);
  
  static const Color accentOrange = Color(0xFFFF5722);
  static const Color accentAmber = Color(0xFFFFB300);
  static const Color accentGold = Color(0xFFFFD54F);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentBlue = Color(0xFF2979FF);
  
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF616161);
}

enum NeuStyle { raised, sunken, flat }

/// Neumorphic Kart / Konteyner
class NeuContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final NeuStyle style;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final double depth;
  final VoidCallback? onTap;
  final ShapeBorder? shape;

  const NeuContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 18.0,
    this.style = NeuStyle.raised,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.depth = 4.0,
    this.onTap,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? NeuColors.surface;

    List<BoxShadow> shadows = [];
    if (style == NeuStyle.raised) {
      shadows = [
        BoxShadow(
          color: NeuColors.lightShadow.withValues(alpha: 0.6),
          offset: Offset(-depth, -depth),
          blurRadius: depth * 2,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: NeuColors.darkShadow.withValues(alpha: 0.9),
          offset: Offset(depth, depth),
          blurRadius: depth * 2,
          spreadRadius: 0,
        ),
      ];
    } else if (style == NeuStyle.sunken) {
      shadows = [
        BoxShadow(
          color: NeuColors.darkShadow.withValues(alpha: 0.7),
          offset: Offset(depth / 2, depth / 2),
          blurRadius: depth,
        ),
        BoxShadow(
          color: NeuColors.lightShadow.withValues(alpha: 0.25),
          offset: Offset(-depth / 2, -depth / 2),
          blurRadius: depth,
        ),
      ];
    }

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : Border.all(color: Colors.white.withValues(alpha: 0.04), width: borderWidth),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

/// Dokunsal Neumorphic Buton
class NeuButton extends StatefulWidget {
  final Widget? child;
  final String? text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final Color? iconColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double depth;
  final bool isLoading;
  final bool isPrimary;
  final Color? primaryGradientStart;
  final Color? primaryGradientEnd;

  const NeuButton({
    super.key,
    this.child,
    this.text,
    this.icon,
    this.onPressed,
    this.color,
    this.textColor,
    this.iconColor,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    this.depth = 4.0,
    this.isLoading = false,
    this.isPrimary = false,
    this.primaryGradientStart,
    this.primaryGradientEnd,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onPressed == null || widget.isLoading;
    final double currentDepth = _isPressed ? 1.5 : widget.depth;

    Color baseColor = widget.color ?? (widget.isPrimary ? NeuColors.accentOrange : NeuColors.surface);
    if (disabled) {
      baseColor = baseColor.withValues(alpha: 0.5);
    }

    final List<BoxShadow> shadows = _isPressed
        ? [
            BoxShadow(
              color: NeuColors.darkShadow.withValues(alpha: 0.8),
              offset: const Offset(1.5, 1.5),
              blurRadius: 3,
            ),
          ]
        : [
            BoxShadow(
              color: widget.isPrimary
                  ? NeuColors.accentOrange.withValues(alpha: 0.25)
                  : NeuColors.lightShadow.withValues(alpha: 0.6),
              offset: Offset(-currentDepth, -currentDepth),
              blurRadius: currentDepth * 2,
            ),
            BoxShadow(
              color: NeuColors.darkShadow.withValues(alpha: 0.9),
              offset: Offset(currentDepth, currentDepth),
              blurRadius: currentDepth * 2,
            ),
          ];

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            },
      onTapCancel: disabled ? null : () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: baseColor,
          gradient: widget.isPrimary
              ? LinearGradient(
                  colors: [
                    widget.primaryGradientStart ?? const Color(0xFFFF6E40),
                    widget.primaryGradientEnd ?? NeuColors.accentOrange,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.isPrimary
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: shadows,
        ),
        child: widget.isLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ),
              )
            : widget.child ??
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.iconColor ?? (widget.isPrimary ? Colors.white : Colors.white70),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (widget.text != null)
                      Text(
                        widget.text!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.textColor ?? Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                  ],
                ),
      ),
    );
  }
}

/// Dairesel / Kare Neumorphic İkon Butonu
class NeuIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final double borderRadius;
  final bool isCircle;
  final String? tooltip;

  const NeuIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.iconColor,
    this.size = 46.0,
    this.iconSize = 22.0,
    this.borderRadius = 14.0,
    this.isCircle = true,
    this.tooltip,
  });

  @override
  State<NeuIconButton> createState() => _NeuIconButtonState();
}

class _NeuIconButtonState extends State<NeuIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double depth = _isPressed ? 1.5 : 3.5;
    final baseColor = widget.color ?? NeuColors.surface;

    final Widget button = GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            },
      onTapCancel: widget.onPressed == null ? null : () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: baseColor,
          shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.isCircle ? null : BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: NeuColors.darkShadow.withValues(alpha: 0.8),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: NeuColors.lightShadow.withValues(alpha: 0.5),
                    offset: Offset(-depth, -depth),
                    blurRadius: depth * 1.8,
                  ),
                  BoxShadow(
                    color: NeuColors.darkShadow.withValues(alpha: 0.8),
                    offset: Offset(depth, depth),
                    blurRadius: depth * 1.8,
                  ),
                ],
        ),
        child: Center(
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: widget.iconColor ?? Colors.white70,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

/// İçe Gömülü (Sunken) Neumorphic Metin Giriş Alanı
class NeuTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final double borderRadius;

  const NeuTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.borderRadius = 16.0,
  });

  @override
  State<NeuTextField> createState() => _NeuTextFieldState();
}

class _NeuTextFieldState extends State<NeuTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              widget.labelText!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: NeuColors.surfaceDark,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isFocused
                  ? NeuColors.accentOrange.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.05),
              width: _isFocused ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: NeuColors.darkShadow.withValues(alpha: 0.9),
                offset: const Offset(2, 2),
                blurRadius: 4,
                spreadRadius: -1,
              ),
              BoxShadow(
                color: NeuColors.lightShadow.withValues(alpha: 0.15),
                offset: const Offset(-1, -1),
                blurRadius: 3,
                spreadRadius: -1,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 14.5),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13.5),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused ? NeuColors.accentOrange : Colors.white38,
                      size: 20,
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Neumorphic Sekme / Segmented Kontrolcü
class NeuSegmentedTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const NeuSegmentedTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: NeuColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: NeuColors.darkShadow.withValues(alpha: 0.8),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: NeuColors.lightShadow.withValues(alpha: 0.2),
            offset: const Offset(-1, -1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? NeuColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: Colors.white.withValues(alpha: 0.08))
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: NeuColors.darkShadow.withValues(alpha: 0.8),
                            offset: const Offset(2, 2),
                            blurRadius: 5,
                          ),
                          BoxShadow(
                            color: NeuColors.lightShadow.withValues(alpha: 0.4),
                            offset: const Offset(-2, -2),
                            blurRadius: 5,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: isSelected ? NeuColors.accentOrange : Colors.white54,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Neumorphic Rozet
class NeuBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;

  const NeuBadge({
    super.key,
    required this.text,
    this.icon,
    this.color = NeuColors.accentOrange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
