import 'dart:io';

void main() {
  final dir = Directory('C:/Translator/lib');
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart') && !entity.path.endsWith('theme.dart')) {
      var content = entity.readAsStringSync();
      
      // Fix const TextStyle
      content = content.replaceAll(RegExp(r'const\s+(TextStyle\([^)]*BoothColors\.(mute|paper|ink|panel|line)[^)]*\))'), r'$1');
      // Fix const BorderSide
      content = content.replaceAll(RegExp(r'const\s+(BorderSide\([^)]*BoothColors\.(mute|paper|ink|panel|line)[^)]*\))'), r'$1');
      
      // Replace BoothColors.x with context.booth.x
      content = content.replaceAllMapped(RegExp(r'BoothColors\.(ink|panel|line|paper|mute)'), (m) => 'context.booth.${m[1]}');
      
      entity.writeAsStringSync(content);
    }
  }
}
