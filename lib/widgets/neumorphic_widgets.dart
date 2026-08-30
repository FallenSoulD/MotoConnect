import 'package:flutter/material.dart';

/// MotoConnect Minimalist Modern Dark UI Renk Paleti ve Temel Değerleri
class NeuColors {
  // Arka Plan ve Zeminler (Derin Obsidyen & Grafit Tonları)
  static const Color background = Color(0xFF0B0C10);
  static const Color surface = Color(0xFF13161F);
  static const Color surfaceLight = Color(0xFF1C202C);
  static const Color surfaceDark = Color(0xFF0F1017);
  static const Color surfaceGlass = Color(0xCC13161F);

  // Gölgeler ve İnce Kenarlıklar (Minimalist Aydınlatma)
  static const Color lightShadow = Color(0xFF1E222E);
  static const Color darkShadow = Color(0xFF000000);
  static const Color borderSubtle = Color(0x14FFFFFF); // %8 Beyaz
  static const Color borderMedium = Color(0x26FFFFFF); // %15 Beyaz
  static const Color borderActive = Color(0x80FF5E1E);

  // Vurgulu Aksiyon Renkleri (Sleek & Energetic)
  static const Color accentOrange = Color(0xFFFF5E1E);
  static const Color accentOrangeDark = Color(0xFFE64A19);
  static const Color accentAmber = Color(0xFFFFA000);
  static const Color accentGold = Color(0xFFFFD54F);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentCyan = Color(0xFF06B6D4);

  // Tipografi Renkleri (Yüksek Kontrastlı & Göz Yormayan)
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B);     // Slate 500
}

enum NeuStyle { raised, sunken, flat }

/// Modern Minimalist Kart / Konteyner Bileşeni
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
  final Gradient? gradient;
  final List<BoxShadow>? customShadows;

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
    this.depth = 3.0,
    this.onTap,
    this.shape,
    this.gradient,
    this.customShadows,
  });

  @override
  Widget build(BuildContext context) {
    Color baseColor;
    if (color != null) {
      baseColor = color!;
    } else if (style == NeuStyle.sunken) {
      baseColor = NeuColors.surfaceDark;
    } else {
      baseColor = NeuColors.surface;
    }

    List<BoxShadow> shadows = [];
    if (customShadows != null) {
      shadows = customShadows!;
    } else if (style == NeuStyle.raised && depth > 0) {
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          offset: Offset(0, depth * 0.7),
          blurRadius: depth * 2.5,
          spreadRadius: 0,
        ),
      ];
    }

    final effectiveBorderColor = borderColor ??
        (style == NeuStyle.sunken
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.07));

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? baseColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: effectiveBorderColor, width: borderWidth),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }
}

/// Dokunsal & Modern Minimalist Buton
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
  final double? width;
  final double? height;

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
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.depth = 3.0,
    this.isLoading = false,
    this.isPrimary = false,
    this.primaryGradientStart,
    this.primaryGradientEnd,
    this.width,
    this.height,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onPressed == null || widget.isLoading;

    Color baseColor = widget.color ?? (widget.isPrimary ? NeuColors.accentOrange : NeuColors.surface);
    if (disabled) {
      baseColor = baseColor.withValues(alpha: 0.4);
    }

    final List<BoxShadow> shadows = disabled
        ? []
        : widget.isPrimary
            ? [
                BoxShadow(
                  color: NeuColors.accentOrange.withValues(alpha: _isPressed ? 0.2 : 0.35),
                  offset: Offset(0, _isPressed ? 2 : 4),
                  blurRadius: _isPressed ? 6 : 14,
                  spreadRadius: 0,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isPressed ? 0.15 : 0.25),
                  offset: Offset(0, _isPressed ? 1 : 3),
                  blurRadius: _isPressed ? 3 : 8,
                  spreadRadius: 0,
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
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.isPrimary ? null : baseColor,
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
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.08),
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
                          color: widget.iconColor ?? (widget.isPrimary ? Colors.white : Colors.white),
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (widget.text != null)
                        Flexible(
                          child: Text(
                            widget.text!,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.textColor ?? Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
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

/// Minimalist Dairesel / Kare İkon Butonu
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
  final bool isSelected;
  final Color? selectedColor;

  const NeuIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.iconColor,
    this.size = 44.0,
    this.iconSize = 20.0,
    this.borderRadius = 14.0,
    this.isCircle = true,
    this.tooltip,
    this.isSelected = false,
    this.selectedColor,
  });

  @override
  State<NeuIconButton> createState() => _NeuIconButtonState();
}

class _NeuIconButtonState extends State<NeuIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isSelected
        ? (widget.selectedColor ?? NeuColors.accentOrange.withValues(alpha: 0.2))
        : (widget.color ?? NeuColors.surface);

    final Widget button = GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            },
      onTapCancel: widget.onPressed == null ? null : () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: baseColor,
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircle ? null : BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.isSelected
                  ? (widget.selectedColor ?? NeuColors.accentOrange)
                  : Colors.white.withValues(alpha: 0.08),
              width: widget.isSelected ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: widget.isSelected
                  ? (widget.selectedColor ?? NeuColors.accentOrange)
                  : (widget.iconColor ?? Colors.white),
            ),
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

/// Minimalist Düz Metin Giriş Alanı
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
  final int maxLines;
  final int minLines;

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
    this.maxLines = 1,
    this.minLines = 1,
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
                color: NeuColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: NeuColors.surfaceDark,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isFocused
                  ? NeuColors.accentOrange
                  : Colors.white.withValues(alpha: 0.08),
              width: _isFocused ? 1.4 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: NeuColors.accentOrange.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            onChanged: widget.onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 14.5),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: NeuColors.textMuted, fontSize: 13.5),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused ? NeuColors.accentOrange : NeuColors.textSecondary,
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

/// Minimalist Kapsül Sekme Kontrolcüsü (Segmented Tabs)
class NeuSegmentedTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final double height;

  const NeuSegmentedTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.height = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: NeuColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected ? NeuColors.surfaceLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                  border: isSelected
                      ? Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1)
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? NeuColors.accentOrange : NeuColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
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

/// Minimalist Rozet (Badge / Pill)
class NeuBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const NeuBadge({
    super.key,
    required this.text,
    this.icon,
    this.color = NeuColors.accentOrange,
    this.fontSize = 11.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimalist Kart Bileşeni (Başlık, İkon ve İçerik Alanı)
class NeuCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;

  const NeuCard({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 18,
    this.onTap,
    this.borderColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      borderColor: borderColor,
      color: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || icon != null || trailing != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (iconColor ?? NeuColors.accentOrange).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (iconColor ?? NeuColors.accentOrange).withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: iconColor ?? NeuColors.accentOrange, size: 18),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(color: NeuColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            if (child != null) const SizedBox(height: 14),
          ],
          ?child,
        ],
      ),
    );
  }
}

/// Minimalist Toggle Switch
class NeuSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const NeuSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = NeuColors.accentOrange,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? activeColor.withValues(alpha: 0.25) : NeuColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? activeColor : Colors.white.withValues(alpha: 0.1),
            width: 1.2,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? activeColor : Colors.white70,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimalist Liste Elemanı (Ayarlar, Profil, Menüler İçin)
class NeuListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;

  const NeuListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.margin = const EdgeInsets.only(bottom: 10),
    this.borderRadius = 16,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      color: color,
      borderColor: borderColor,
      onTap: onTap,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                title,
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  subtitle!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ] else if (onTap != null) ...[
            const Icon(Icons.chevron_right, color: NeuColors.textMuted, size: 20),
          ],
        ],
      ),
    );
  }
}

/// Minimalist Avatar Çerçevesi
class NeuAvatar extends StatelessWidget {
  final double radius;
  final ImageProvider? image;
  final Widget? child;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;

  const NeuAvatar({
    super.key,
    this.radius = 40,
    this.image,
    this.child,
    this.onTap,
    this.borderColor,
    this.borderWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: NeuColors.surfaceLight,
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.12),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
        image: image != null
            ? DecorationImage(
                image: image!,
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: image == null ? Center(child: child) : null,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: content);
    }
    return content;
  }
}
