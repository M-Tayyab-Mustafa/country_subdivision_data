import 'country.dart';

/// A phone value paired with its selected country.
///
/// This model composes a dialing code and user input. It deliberately does not
/// claim country-specific phone-number parsing or validity.
final class CountryPhoneNumber {
  /// Creates a country-aware phone value.
  const CountryPhoneNumber({
    required this.country,
    required this.nationalNumber,
  });

  /// Selected country.
  final Country country;

  /// Phone text entered by the user, without the country selector.
  final String nationalNumber;

  /// Country calling code, normalized to include one leading `+`.
  String get dialingCode {
    final code = country.phoneCode?.trim() ?? '';
    if (code.isEmpty) {
      return '';
    }
    return '+${code.replaceFirst(RegExp(r'^\++'), '')}';
  }

  /// Decimal digits from [nationalNumber].
  String get nationalDigits => nationalNumber.replaceAll(RegExp(r'\D'), '');

  /// Dialing code followed by [nationalDigits].
  ///
  /// No national trunk prefix is removed because that requires
  /// country-specific numbering-plan knowledge.
  String get internationalNumber => '$dialingCode$nationalDigits';

  /// Whether no national-number digits have been entered.
  bool get isEmpty => nationalDigits.isEmpty;

  /// Whether at least one national-number digit has been entered.
  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryPhoneNumber &&
          country == other.country &&
          nationalNumber == other.nationalNumber;

  @override
  int get hashCode => Object.hash(country, nationalNumber);

  @override
  String toString() =>
      'CountryPhoneNumber(${country.iso2}, $internationalNumber)';
}
