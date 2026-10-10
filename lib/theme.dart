import 'package:flutter/material.dart';

class BoothColors {
  static const lime = Color(0xFFD6F25C);
  static const mint = Color(0xFF8EDEC8);
  static const coral = Color(0xFFFF6B4A);
}

class BoothTheme extends ThemeExtension<BoothTheme> {
  const BoothTheme({
    required this.ink,
    required this.panel,
    required this.line,
    required this.paper,
    required this.mute,
  });

  final Color ink;
  final Color panel;
  final Color line;
  final Color paper;
  final Color mute;

  @override
  BoothTheme copyWith({
    Color? ink,
    Color? panel,
    Color? line,
    Color? paper,
    Color? mute,
  }) {
    return BoothTheme(
      ink: ink ?? this.ink,
      panel: panel ?? this.panel,
      line: line ?? this.line,
      paper: paper ?? this.paper,
      mute: mute ?? this.mute,
    );
  }

  @override
  BoothTheme lerp(ThemeExtension<BoothTheme>? other, double t) {
    if (other is! BoothTheme) return this;
    return BoothTheme(
      ink: Color.lerp(ink, other.ink, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      line: Color.lerp(line, other.line, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      mute: Color.lerp(mute, other.mute, t)!,
    );
  }
}

extension BoothThemeContext on BuildContext {
  BoothTheme get booth => Theme.of(this).extension<BoothTheme>()!;
  
  List<BoxShadow> get neuShadows {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? Colors.black.withOpacity(0.6) : const Color(0xFFD1D9E6),
        offset: const Offset(6, 6),
        blurRadius: 12,
      ),
      BoxShadow(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        offset: const Offset(-6, -6),
        blurRadius: 12,
      ),
    ];
  }
  
  List<BoxShadow> get neuShadowsInset {
    // Basic trick for pressed state or inner shadow if needed, but standard is fine
    return [];
  }
}

ThemeData buildBoothTheme({Brightness brightness = Brightness.dark}) {
  final isDark = brightness == Brightness.dark;

  final ink = isDark ? const Color(0xFF1A1C23) : const Color(0xFFE0E5EC);
  final panel = ink;
  final line = isDark ? const Color(0xFF2A2D35) : const Color(0xFFD1D9E6);
  final paper = isDark ? const Color(0xFFE0E5EC) : const Color(0xFF1A1C23);
  final mute = isDark ? const Color(0xFF8A94A6) : const Color(0xFF7A8496);

  final boothExt = BoothTheme(ink: ink, panel: panel, line: line, paper: paper, mute: mute);

  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: ink,
    extensions: [boothExt],
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: BoothColors.lime,
      onPrimary: const Color(0xFF1A2208),
      secondary: BoothColors.mint,
      onSecondary: const Color(0xFF10211C),
      error: BoothColors.coral,
      onError: Colors.white,
      surface: ink,
      onSurface: paper,
    ),
    fontFamily: 'sans-serif',
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: paper,
      displayColor: paper,
    ),
    dividerColor: line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: panel,
      labelStyle: TextStyle(color: mute),
      hintStyle: TextStyle(color: mute),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BoothColors.lime),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
