import 'dart:async';

import 'package:country_subdivision_data/country_subdivision_data.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

final class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Country subdivision data',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const LocationExplorer(),
      );
}

final class LocationExplorer extends StatefulWidget {
  const LocationExplorer({super.key});

  @override
  State<LocationExplorer> createState() => _LocationExplorerState();
}

final class _LocationExplorerState extends State<LocationExplorer> {
  final CountrySubdivisionData _data = CountrySubdivisionData.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Country> _countries = const <Country>[];
  List<Subdivision> _subdivisions = const <Subdivision>[];
  List<City> _cities = const <City>[];
  List<City> _results = const <City>[];
  Country? _country;
  Subdivision? _subdivision;
  Object? _error;
  bool _loading = true;
  String _phoneNumber = '';

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _data.initialize();
      final countries = await _data.getCountries();
      if (mounted) {
        setState(() {
          _countries = countries;
          _loading = false;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectCountry(Country? country) async {
    setState(() {
      _country = country;
      _subdivision = null;
      _subdivisions = const <Subdivision>[];
      _cities = const <City>[];
      _results = const <City>[];
      _loading = country != null;
    });
    if (country == null) {
      return;
    }
    try {
      final subdivisions = await _data.getSubdivisions(
        countryCode: country.iso2,
      );
      if (mounted && _country == country) {
        setState(() {
          _subdivisions = subdivisions;
          _loading = false;
        });
      }
    } on Object catch (error) {
      _showError(error);
    }
  }

  Future<void> _selectSubdivision(Subdivision? subdivision) async {
    setState(() {
      _subdivision = subdivision;
      _cities = const <City>[];
      _results = const <City>[];
      _loading = subdivision != null;
    });
    final country = _country;
    if (country == null || subdivision == null) {
      return;
    }
    try {
      final cities = await _data.getCities(
        countryCode: country.iso2,
        subdivisionCode: subdivision.code,
      );
      if (mounted && _subdivision == subdivision) {
        setState(() {
          _cities = cities;
          _loading = false;
        });
      }
    } on Object catch (error) {
      _showError(error);
    }
  }

  Future<void> _search(String query) async {
    final country = _country;
    if (country == null) {
      return;
    }
    final results = await _data.searchCities(
      query: query,
      countryCode: country.iso2,
      subdivisionCode: _subdivision?.code,
    );
    if (mounted) {
      setState(() {
        _results = results;
      });
    }
  }

  Future<void> _clearAndReload() async {
    await _data.clearCache();
    final country = _country;
    if (country != null) {
      await _selectCountry(country);
    }
  }

  void _showError(Object error) {
    if (mounted) {
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Location explorer')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Could not load locations: $_error'),
              FilledButton(onPressed: _initialize, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Location explorer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (_loading) const LinearProgressIndicator(),
          CountryPhoneField(
            initialCountryCode: 'NG',
            favoriteCountryCodes: const <String>['NG', 'US', 'GB'],
            decoration: const InputDecoration(
              labelText: 'Phone number',
              border: OutlineInputBorder(),
            ),
            pickerConfiguration: const CountryPickerDialogConfiguration(
              title: 'Choose a calling code',
              searchHintText: 'Search country, ISO code, or calling code',
              showIsoCode: true,
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter a phone number' : null,
            onChanged: (value) {
              setState(() {
                _phoneNumber = value.internationalNumber;
              });
            },
          ),
          if (_phoneNumber.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Composed number: $_phoneNumber'),
            ),
          const SizedBox(height: 20),
          DropdownButtonFormField<Country>(
            initialValue: _country,
            decoration: const InputDecoration(labelText: 'Country'),
            items: _countries
                .map(
                  (country) => DropdownMenuItem<Country>(
                    value: country,
                    child: Text(country.name),
                  ),
                )
                .toList(growable: false),
            onChanged: _selectCountry,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Subdivision>(
            initialValue: _subdivision,
            decoration: const InputDecoration(labelText: 'Subdivision'),
            items: _subdivisions
                .map(
                  (subdivision) => DropdownMenuItem<Subdivision>(
                    value: subdivision,
                    child: Text(subdivision.name),
                  ),
                )
                .toList(growable: false),
            onChanged: _country == null ? null : _selectSubdivision,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            enabled: _country != null,
            decoration: const InputDecoration(
              labelText: 'Search cities',
              suffixIcon: Icon(Icons.search),
            ),
            onChanged: _search,
          ),
          const SizedBox(height: 12),
          Text(
            _subdivision == null
                ? 'Select a subdivision to load cities.'
                : _cities.isEmpty
                    ? 'No cities are listed for this subdivision.'
                    : '${_cities.length} cities loaded.',
          ),
          for (final city in _results)
            ListTile(
                title: Text(city.name), subtitle: Text(city.timezone ?? '')),
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Store a user-entered location separately from the dataset.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit_location_alt),
            label: const Text('Location not listed'),
          ),
          OutlinedButton(
            onPressed: _clearAndReload,
            child: const Text('Clear cache and reload'),
          ),
          const Divider(),
          if (_data.isInitialized)
            Text(
              'Snapshot ${_data.snapshotMetadata.upstreamCommit.substring(0, 12)}\n'
              '${_data.snapshotMetadata.countryCount} countries, '
              '${_data.snapshotMetadata.subdivisionCount} subdivisions, '
              '${_data.snapshotMetadata.cityCount} cities',
            ),
        ],
      ),
    );
  }
}
