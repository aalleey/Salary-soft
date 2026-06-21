import 'dart:io';

void main() {
  final directory = Directory('lib');
  final pattern = RegExp(r'\.withOpacity\(([^)]+)\)');
  int totalSubs = 0;

  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      int fileSubs = 0;
      final newContent = content.replaceAllMapped(pattern, (match) {
        fileSubs++;
        return '.withValues(alpha: ${match.group(1)})';
      });

      if (fileSubs > 0) {
        entity.writeAsStringSync(newContent);
        print('Updated ${entity.path} ($fileSubs replacements)');
        totalSubs += fileSubs;
      }
    }
  }

  print('Total replacements: $totalSubs');
}
