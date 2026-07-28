import 'package:country_subdivision_data/country_subdivision_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final nigeria = Country(
    id: 161,
    name: 'Nigeria',
    iso2: 'NG',
    iso3: 'NGA',
    phoneCode: '+234',
    timezones: const <String>['Africa/Lagos'],
  );

  test('normalizes country calling code and preserves national input', () {
    final value = CountryPhoneNumber(
      country: nigeria,
      nationalNumber: '0803 123-4567',
    );

    expect(value.dialingCode, '+234');
    expect(value.nationalDigits, '08031234567');
    expect(value.internationalNumber, '+23408031234567');
    expect(value.isNotEmpty, isTrue);
    expect(value.toString(), contains('NG'));
  });

  test('flag and calling-code helpers handle valid and invalid values', () {
    expect(countryFlagEmoji('ng'), '🇳🇬');
    expect(countryFlagEmoji('invalid'), isEmpty);
    expect(normalizedDialingCode(nigeria), '+234');
  });
}
