import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_driver_app/background/location_reporter.dart';

import '../support/fakes.dart';

void main() {
  final at = DateTime.utc(2026, 10, 27, 12);
  LocationFix fix(int s) =>
      LocationFix(lat: 4.6, lng: -74.05, heading: 90, speedMps: 8, recordedAt: at.add(Duration(seconds: s)));

  test('reenvía la última lectura cada intervalo aunque no cambie', () async {
    final source = FakePositions()..fixes.addAll([fix(0), fix(0), null, fix(3)]);
    final sent = <LocationFix>[];
    final reporter = LocationReporter(source: source, sink: (f) async => sent.add(f), now: () => at);

    expect(await reporter.tick(), isTrue);
    expect(await reporter.tick(), isTrue, reason: 'equipo quieto: se reenvía la misma lectura');
    expect(await reporter.tick(), isFalse, reason: 'sin GPS aún');
    expect(await reporter.tick(), isTrue);
    expect(sent.map((f) => f.recordedAt), [at, at, at.add(const Duration(seconds: 3))]);
  });

  test('no envía lecturas de más de 60 s', () async {
    final source = FakePositions()..fixes.add(fix(0));
    final sent = <LocationFix>[];
    final reporter = LocationReporter(
      source: source,
      sink: (f) async => sent.add(f),
      now: () => at.add(const Duration(seconds: 61)),
    );
    expect(await reporter.tick(), isFalse);
    expect(sent, isEmpty);
  });

  test('un error de envío no detiene el reporte', () async {
    final source = FakePositions()..fixes.addAll([fix(0), fix(3)]);
    final errors = <Object>[];
    var calls = 0;
    final reporter = LocationReporter(
      source: source,
      sink: (f) async {
        if (calls++ == 0) throw Exception('sin red');
      },
      onError: errors.add,
      now: () => at,
    );

    expect(await reporter.tick(), isFalse);
    expect(await reporter.tick(), isTrue);
    expect(errors, hasLength(1));
  });

  test('start envía cada intervalo y stop libera el GPS', () async {
    final source = FakePositions()..fixes.addAll([fix(0), fix(3), fix(6), fix(9)]);
    final sent = <LocationFix>[];
    final reporter = LocationReporter(
      source: source,
      sink: (f) async => sent.add(f),
      interval: const Duration(milliseconds: 10),
      now: () => at,
    )..start();
    expect(reporter.running, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 35));
    await reporter.stop();
    expect(reporter.running, isFalse);
    expect(sent.length, greaterThanOrEqualTo(3));
    expect(source.stops, 1);
  });
}
