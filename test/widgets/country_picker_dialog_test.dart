import 'package:country_subdivision_data/country_subdivision_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  testWidgets('default dialog searches names and calling codes',
      (tester) async {
    Country? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await showCountryPickerDialog(
                context: context,
                countries: countries,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Nigeria'), findsOneWidget);
    expect(find.text('United States'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '234');
    await tester.pump();
    expect(find.text('Nigeria'), findsOneWidget);
    expect(find.text('United States'), findsNothing);

    await tester.tap(find.text('Nigeria'));
    await tester.pumpAndSettle();
    expect(result?.iso2, 'NG');
  });

  testWidgets('custom search, row, title, empty, and dialog builders are used',
      (
    tester,
  ) async {
    Country? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: CountryPickerDialog(
          countries: countries,
          selectedCountry: countries.last,
          onSelected: (country) {
            selected = country;
          },
          searchFieldBuilder: (context, controller, onChanged) => TextField(
            key: const Key('custom-search'),
            controller: controller,
            onChanged: onChanged,
          ),
          titleBuilder: (context, close) => const Text('Custom title'),
          itemBuilder: (context, country, isSelected, select) => ListTile(
            key: Key('custom-${country.iso2}'),
            title: Text('${country.iso2}:${isSelected ? 'yes' : 'no'}'),
            onTap: select,
          ),
          emptyBuilder: (context, query) => Text('Nothing for $query'),
          dialogBuilder: (context, content) => Material(
            key: const Key('custom-dialog'),
            child: content,
          ),
          configuration: const CountryPickerDialogConfiguration(
            dialogHeight: 400,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('custom-dialog')), findsOneWidget);
    expect(find.text('Custom title'), findsOneWidget);
    expect(find.text('US:yes'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('custom-search')), 'missing');
    await tester.pump();
    expect(find.text('Nothing for missing'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('custom-search')), 'Nigeria');
    await tester.pump();
    await tester.tap(find.byKey(const Key('custom-NG')));
    expect(selected?.iso2, 'NG');
  });
}
