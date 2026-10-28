import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_radio/kyq_radio.dart';
import 'package:kyq_radio/testing.dart';

import 'support/harness.dart';

void main() {
  testWidgets('foto de la cámara: reserva, sube el JPEG y confirma (FR-023, R6)', (tester) async {
    final api = FakeRadioApi(conversations: [fakeContact('c1')]);
    final photos = FakeRadioPhotoPicker(Uint8List.fromList(List.filled(1200, 7)));
    final h = RadioHarness(api, photos: photos);
    await h.pump(tester, initial: '/radio/c/c1');
    await tester.tap(find.byKey(const Key('radio.attach')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('radio.attach.camera')));
    await tester.pumpAndSettle();
    expect(photos.picked, [true]);
    expect(api.calls, containsAllInOrder(['photo c1', 'upload 1200', 'photo-uploaded photo-1']));

    // Cancelar la galería no envía nada.
    photos.jpeg = null;
    await tester.tap(find.byKey(const Key('radio.attach')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('radio.attach.gallery')));
    await tester.pumpAndSettle();
    expect(api.calls.where((c) => c.startsWith('photo ')), hasLength(1));
    await h.done(tester);
  });

  testWidgets('ubicación actual; sin permiso lo explica (US6-3)', (tester) async {
    final api = FakeRadioApi(conversations: [fakeContact('c1')]);
    final location = FakeRadioLocation((lat: 4.65, lng: -74.05));
    final h = RadioHarness(api, location: location);
    await h.pump(tester, initial: '/radio/c/c1');
    await tester.tap(find.byKey(const Key('radio.attach')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('radio.attach.location')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('send location'));

    location.point = null;
    await tester.tap(find.byKey(const Key('radio.attach')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('radio.attach.location')));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos obtener tu ubicación. Revisa el permiso.'), findsOneWidget);
    await h.done(tester);
  });

  testWidgets('punto en el mapa de la app (FR-023)', (tester) async {
    final api = FakeRadioApi(conversations: [fakeContact('c1')]);
    RadioPoint? near;
    final h = RadioHarness(
      api,
      location: FakeRadioLocation((lat: 4.6, lng: -74.0)),
      pickPoint: (_, n) async {
        near = n;
        return (lat: 4.7, lng: -74.1);
      },
    );
    await h.pump(tester, initial: '/radio/c/c1');
    await tester.tap(find.byKey(const Key('radio.attach')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('radio.attach.point')));
    await tester.pumpAndSettle();
    expect(near, (lat: 4.6, lng: -74.0), reason: 'el mapa abre cerca de donde está');
    expect(api.calls, contains('send location'));
    await h.done(tester);
  });

  testWidgets('historial: ubicación con su nombre y foto con miniatura', (tester) async {
    final api = FakeRadioApi(conversations: [fakeContact('c1')]);
    api.messages['c1'] = [
      fakeVoice('m2', 'c1', minute: 2).copyWith(kind: RadioMessageKind.photo, durationMs: null),
      fakeVoice(
        'm1',
        'c1',
        minute: 1,
      ).copyWith(kind: RadioMessageKind.location, hasMedia: false, lat: 4.65, lng: -74.05, body: 'Calle 80'),
    ];
    final h = RadioHarness(api);
    await h.pump(tester, initial: '/radio/c/c1');
    expect(find.text('Calle 80'), findsOneWidget);
    expect(find.byKey(const Key('radio.message.m2')), findsOneWidget);
    await h.done(tester);
  });
}
