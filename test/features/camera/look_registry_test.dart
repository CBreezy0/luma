import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/camera/look_registry.dart';

void main() {
  test('look registry includes original plus six unique branded looks', () {
    expect(kLumaFilmSimulations.length, 7);

    final ids = kLumaFilmSimulations.map((s) => s.id).toSet();
    final names = kLumaFilmSimulations.map((s) => s.name).toSet();
    expect(ids.length, 7);
    expect(names.length, 7);
    expect(kLumaFilmSimulations.first.id, kDefaultSimulationId);
    expect(kLumaFilmSimulations.first.name, 'Original');
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
