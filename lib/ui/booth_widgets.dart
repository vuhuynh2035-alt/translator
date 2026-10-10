import 'package:flutter/material.dart';

import '../models/language.dart';
import '../models/settings.dart';
import '../theme.dart';

class BoothPanel extends StatelessWidget {
  const BoothPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.booth.panel,
        borderRadius: BorderRadius.circular(22),
        // Remove border for authentic neumorphism
        boxShadow: context.neuShadows,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = BoothColors.lime});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(color: color, fontSize: 12, letterSpacing: 1.4, fontWeight: FontWeight.w700),
    );
  }
}

class LanguageMenu extends StatelessWidget {
  const LanguageMenu({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      dropdownColor: context.booth.panel,
      underline: const SizedBox.shrink(),
      isExpanded: true,
      items: [
        for (final language in AppLanguage.all)
          DropdownMenuItem(value: language.code, child: Text(language.name)),
      ],
      onChanged: (code) {
        if (code != null) onChanged(code);
      },
    );
  }
}

class ChoiceChips<T> extends StatelessWidget {
  const ChoiceChips({super.key, required this.options, required this.selected, required this.onSelected});

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(option.$2),
            selected: option.$1 == selected,
            onSelected: (_) => onSelected(option.$1),
            selectedColor: BoothColors.lime,
            labelStyle: TextStyle(
              color: option.$1 == selected ? const Color(0xFF1A2208) : context.booth.paper,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: context.booth.ink,
            side: BorderSide(color: context.booth.line),
          ),
      ],
    );
  }
}

class LiveMeter extends StatelessWidget {
  const LiveMeter({super.key, required this.level, required this.active});

  final double level;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final normalized = active ? (level.abs() / 20).clamp(0.08, 1.0) : 0.08;
    return Row(
      children: List.generate(12, (index) {
        final on = normalized > index / 12;
        return Expanded(
          child: Container(
            height: 8 + (index % 4) * 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: on ? BoothColors.coral : context.booth.line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

String engineLabel(EngineMode mode) => mode == EngineMode.online ? 'Online · AI' : 'Offline';

String outputLabel(OutputMode mode) {
  switch (mode) {
    case OutputMode.text:
      return 'Chỉ chữ';
    case OutputMode.audio:
      return 'Chỉ giọng';
    case OutputMode.both:
      return 'Chữ và giọng';
  }
}
