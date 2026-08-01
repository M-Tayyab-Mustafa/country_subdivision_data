import 'package:country_subdivision_data/country_subdivision_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final countries = <Country>[
    Country(
      id: 161,
      name: 'Nigeria',
      iso2: 'NG',
      iso3: 'NGA',
      phoneCode: '234',
      timezones: const <String>[],
    ),
    Country(
      id: 233,
      name: 'United States',
      iso2: 'US',
      iso3: 'USA',
      phoneCode: '1',
      timezones: const <String>[],
    ),
  ];
  final data = CountrySubdivisionData(
    repository: _CountryRepository(countries),
  );

  testWidgets('loads initial country, selects another, and emits phone value', (
    tester,
  ) async {
    CountryPhoneNumber? value;
    Country? changedCountry;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountryPhoneField(
            data: data,
            initialCountryCode: 'US',
            onChanged: (next) {
              value = next;
            },
            onCountryChanged: (country) {
              changedCountry = country;
            },
            pickerPresenter: (context, countries, selected) async =>
                countries.firstWhere((country) => country.iso2 == 'NG'),
          ),
        ),
      ),
    );
    await _finishCountryLoad(tester);

    expect(find.text('+1'), findsOneWidget);
    await tester.tap(find.text('+1'));
    await tester.pump();
    expect(find.text('+234'), findsOneWidget);
    expect(changedCountry?.iso2, 'NG');

    await tester.enterText(find.byType(TextFormField), '0803 123 4567');
    await tester.pump();
    expect(value?.country.iso2, 'NG');
    expect(value?.nationalNumber, '0803 123 4567');
    expect(value?.internationalNumber, '+23408031234567');
  });

  testWidgets('custom selector, filters, and favorites are honored', (
    tester,
  ) async {
    List<Country>? presentedCountries;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountryPhoneField(
            data: data,
            initialCountryCode: 'NG',
            favoriteCountryCodes: const <String>['NG'],
            countryFilter: (country) =>
                country.iso2 == 'NG' || country.iso2 == 'US',
            selectorBuilder: (context, country, enabled, open) => TextButton(
              key: const Key('custom-selector'),
              onPressed: open,
              child: Text(country?.iso2 ?? 'none'),
            ),
            pickerPresenter: (context, countries, selected) async {
              presentedCountries = countries;
              return null;
            },
          ),
        ),
      ),
    );
    await _finishCountryLoad(tester);

    expect(find.byKey(const Key('custom-selector')), findsOneWidget);
    expect(find.text('NG'), findsOneWidget);
    await tester.tap(find.byKey(const Key('custom-selector')));
    await tester.pump();

    expect(presentedCountries, hasLength(2));
    expect(presentedCountries!.first.iso2, 'NG');
  });

  testWidgets('custom phone text field replaces the default composition', (
    tester,
  ) async {
    var pickerOpened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountryPhoneField(
            data: data,
            pickerPresenter: (context, countries, selected) async {
              pickerOpened = true;
              return null;
            },
            phoneTextFieldBuilder:
                (
                  context,
                  controller,
                  focusNode,
                  country,
                  enabled,
                  openPicker,
                  onChanged,
                ) => Row(
                  children: <Widget>[
                    IconButton(
                      key: const Key('custom-open-picker'),
                      onPressed: enabled ? openPicker : null,
                      icon: Text(country?.iso2 ?? ''),
                    ),
                    Expanded(
                      child: TextField(
                        key: const Key('custom-phone'),
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: onChanged,
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
    await _finishCountryLoad(tester);

    expect(find.byKey(const Key('custom-phone')), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    await tester.tap(find.byKey(const Key('custom-open-picker')));
    await tester.pump();
    expect(pickerOpened, isTrue);
  });

  testWidgets('structured validator participates in Form validation', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: CountryPhoneField(
              data: data,
              initialCountryCode: 'NG',
              validator: (value) =>
                  value == null || value.isEmpty ? 'Phone is required' : null,
            ),
          ),
        ),
      ),
    );
    await _finishCountryLoad(tester);

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Phone is required'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '12345');
    await tester.pump();
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('responds when the requested initial country changes', (
    tester,
  ) async {
    const fieldKey = Key('changing-country');

    Future<void> pumpField(String code) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountryPhoneField(
              key: fieldKey,
              data: data,
              initialCountryCode: code,
            ),
          ),
        ),
      );
      await _finishCountryLoad(tester);
    }

    await pumpField('US');
    expect(find.text('+1'), findsOneWidget);

    await pumpField('NG');
    expect(find.text('+234'), findsOneWidget);
  });
}

Future<void> _finishCountryLoad(WidgetTester tester) async {
  for (var index = 0; index < 3; index += 1) {
    await tester.pump();
  }
}

final class _CountryRepository extends Fake
    implements CountrySubdivisionRepository {
  _CountryRepository(this.countries);

  final List<Country> countries;

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<Country>> getCountries() async => countries;
}
