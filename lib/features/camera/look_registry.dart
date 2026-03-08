import 'camera_models.dart';

const String kDefaultSimulationId = 'slate';

const List<LumaFilmSimulation> kLumaFilmSimulations = [
  LumaFilmSimulation(id: 'slate', name: 'Slate', intensity: 1.0),
  LumaFilmSimulation(id: 'ember', name: 'Ember', intensity: 1.0),
  LumaFilmSimulation(id: 'bloom', name: 'Bloom', intensity: 1.0),
  LumaFilmSimulation(id: 'drift', name: 'Drift', intensity: 1.0),
  LumaFilmSimulation(id: 'vale', name: 'Vale', intensity: 1.0),
  LumaFilmSimulation(id: 'mono', name: 'Mono', intensity: 1.0),
];

LumaFilmSimulation lumaSimulationById(String id) {
  for (final simulation in kLumaFilmSimulations) {
    if (simulation.id == id) return simulation;
  }
  return kLumaFilmSimulations.first;
}

int lumaSimulationIndexById(String id) {
  final index = kLumaFilmSimulations.indexWhere((s) => s.id == id);
  return index >= 0 ? index : 0;
}
