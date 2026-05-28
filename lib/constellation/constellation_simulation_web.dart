import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:web/web.dart' as web;

import 'constellation_simulation.dart';
import 'constellation_simulation_base.dart';

ConstellationSimulation createConstellationSimulation() =>
    _WebConstellationSimulation();

class _WebConstellationSimulation extends ConstellationSimulationBase {
  late final web.Worker _worker;

  @override
  Future<void> initialize({
    required List<ConstellationNode> nodes,
    required List<ConstellationEdge> edges,
    required Map<String, dynamic> forces,
  }) async {
    _worker = web.Worker('assets/constellation_engine.js'.toJS);
    _worker.onmessage = _onMessage.toJS;
    sendGraph(nodes, edges, forces: forces, alpha: 1.0);
  }

  @override
  void dispatch(Map<String, dynamic> msg) {
    _worker.postMessage(msg.jsify());
  }

  void _onMessage(web.MessageEvent event) {
    try {
      final obj = event.data as JSObject;

      final jsIds = obj.getProperty<JSAny?>('id'.toJS);
      if (jsIds == null) return;

      final jsBuffer = obj.getProperty<JSAny?>('buffer'.toJS);
      if (jsBuffer == null) return;

      final ids = (jsIds as JSArray<JSAny>).toDart
          .map((s) => (s as JSString).toDart)
          .toList();

      final floats = Float32List.view((jsBuffer as JSArrayBuffer).toDart);

      for (int i = 0; i < ids.length; i++) {
        current[ids[i]] = Offset(floats[2 * i], floats[2 * i + 1]);
      }
      positions.ping();
    } catch (_) {}
  }

  @override
  void dispose() {
    _worker.terminate();
    positions.dispose();
  }
}
