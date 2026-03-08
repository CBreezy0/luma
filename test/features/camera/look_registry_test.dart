import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/camera/look_registry.dart';

void main() {
  test('look registry has six unique branded looks', () {
    expect(kLumaFilmSimulations.length, 6);

    final ids = kLumaFilmSimulations.map((s) => s.id).toSet();
    final names = kLumaFilmSimulations.map((s) => s.name).toSet();
    expect(ids.length, 6);
    expect(names.length, 6);
  });

  test('look names do not use disallowed trademarked names', () {
    const banned = <String>{
      'provia',
      'velvia',
      'astia',
      'classic chrome',
      'eterna',
      'acros',
    };

    final lowerNames = kLumaFilmSimulations
        .map((simulation) => simulation.name.toLowerCase())
        .toSet();

    for (final name in lowerNames) {
      expect(banned.contains(name), isFalse);
    }
  });
}
