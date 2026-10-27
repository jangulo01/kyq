import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_rider_app/app/session_user.dart';

import '../support/fakes.dart';

void main() {
  test('lee el sub del JWT', () {
    expect(userIdFromAccessToken(fakeAccessToken('3f1c-p1')), '3f1c-p1');
  });

  test('token que no es JWT devuelve null', () {
    expect(userIdFromAccessToken('a'), isNull);
    expect(userIdFromAccessToken('x.%%%.y'), isNull);
  });
}
