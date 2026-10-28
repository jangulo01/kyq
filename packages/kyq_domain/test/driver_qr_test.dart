import 'package:kyq_domain/kyq_domain.dart';
import 'package:test/test.dart';

void main() {
  const token = 'q3T9xZk2LmN8pR4sV7wY1a';

  test('ida y vuelta', () {
    expect(parseDriverQr(driverQrPayload(token)), token);
  });

  test('rechaza códigos que no son de Kyq', () {
    expect(parseDriverQr('https://example.com/driver/$token'), isNull);
    expect(parseDriverQr('kyq://driver/'), isNull);
    expect(parseDriverQr('kyq://driver/corto'), isNull);
    expect(parseDriverQr('kyq://driver/$token/extra'), isNull);
    expect(parseDriverQr('kyq://passenger/$token'), isNull);
  });

  test('tolera espacios alrededor', () {
    expect(parseDriverQr(' ${driverQrPayload(token)}\n'), token);
  });

  test('008: enlace del conductor por esquema kyq o por su página pública', () {
    expect(parseAffiliateLink('kyq://affiliate/$token'), token);
    expect(parseAffiliateLink('https://kyq.co/a/$token'), token);
    expect(parseAffiliateLink(' https://kyq.co/a/$token/\n'), token);
    expect(parseAffiliateLink('https://kyq.co/b/$token'), isNull);
    expect(parseAffiliateLink('kyq://affiliate/corto'), isNull);
    expect(parseAffiliateLink(driverQrPayload(token)), isNull);
  });
}
