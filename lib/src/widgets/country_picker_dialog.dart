import 'dart:async';

import 'package:flutter/material.dart';

import '../models/country.dart';
import '../search/location_search.dart';

/// Builds one selectable country row.
typedef CountryPickerItemBuilder = Widget Function(
  BuildContext context,
  Country country,
  bool isSelected,
  VoidCallback select,
);

/// Builds the search field used by [CountryPickerDialog].
typedef CountryPickerSearchFieldBuilder = Widget Function(
  BuildContext context,
  TextEditingController controller,
  ValueChanged<String> onChanged,
);

/// Builds the country flag or other leading content.
typedef CountryPickerFlagBuilder = Widget Function(
    BuildContext context, Country country);

/// Builds the picker title.
typedef CountryPickerTitleBuilder = Widget Function(
    BuildContext context, VoidCallback close);

/// Builds the no-results state for a normalized [query].
typedef CountryPickerEmptyBuilder = Widget Function(
    BuildContext context, String query);

/// Wraps or replaces the default dialog around [content].
typedef CountryPickerDialogBuilder = Widget Function(
    BuildContext context, Widget content);

/// Visual and behavioral defaults for [CountryPickerDialog].
final class CountryPickerDialogConfiguration {
  /// Creates picker configuration.
  const CountryPickerDialogConfiguration({
    this.title = 'Select country',
    this.searchHintText = 'Search countries',
    this.noResultsText = 'No countries found',
    this.showSearch = true,
    this.showFlag = true,
    this.showPhoneCode = true,
    this.showIsoCode = false,
    this.searchAutofocus = false,
    this.showCloseButton = true,
    this.dialogWidth,
    this.dialogHeight = 560,
    this.constraints = const BoxConstraints(maxWidth: 520, maxHeight: 640),
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 24,
    ),
    this.titlePadding = const EdgeInsets.fromLTRB(24, 16, 8, 8),
    this.searchPadding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
    this.listPadding = const EdgeInsets.only(bottom: 12),
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.flagPadding = const EdgeInsets.only(right: 12),
    this.backgroundColor,
    this.surfaceTintColor,
    this.selectedColor,
    this.flagTextStyle,
    this.countryNameStyle,
    this.phoneCodeStyle,
    this.isoCodeStyle,
    this.searchTextStyle,
    this.titleTextStyle,
    this.searchDecoration,
    this.searchCursorColor,
    this.shape,
    this.elevation,
    this.clipBehavior = Clip.none,
    this.divider,
    this.closeIcon = const Icon(Icons.close),
  });

  /// Default title text.
  final String title;

  /// Default search hint.
  final String searchHintText;

  /// Default empty-state text.
  final String noResultsText;

  /// Whether the search field is visible.
  final bool showSearch;

  /// Whether default rows show flag emoji.
  final bool showFlag;

  /// Whether default rows show calling codes.
  final bool showPhoneCode;

  /// Whether default rows show ISO2 codes.
  final bool showIsoCode;

  /// Whether the default search field requests focus.
  final bool searchAutofocus;

  /// Whether the default title row contains a close button.
  final bool showCloseButton;

  /// Explicit dialog width.
  final double? dialogWidth;

  /// Explicit dialog height.
  final double? dialogHeight;

  /// Dialog content constraints.
  final BoxConstraints constraints;

  /// Space between the dialog and screen edges.
  final EdgeInsets insetPadding;

  /// Title padding.
  final EdgeInsets titlePadding;

  /// Search-field padding.
  final EdgeInsets searchPadding;

  /// Country-list padding.
  final EdgeInsets listPadding;

  /// Default country-row padding.
  final EdgeInsets itemPadding;

  /// Padding after a default flag.
  final EdgeInsets flagPadding;

  /// Dialog background color.
  final Color? backgroundColor;

  /// Material surface-tint color.
  final Color? surfaceTintColor;

  /// Selected-row color.
  final Color? selectedColor;

  /// Flag text style.
  final TextStyle? flagTextStyle;

  /// Country-name text style.
  final TextStyle? countryNameStyle;

  /// Calling-code text style.
  final TextStyle? phoneCodeStyle;

  /// ISO-code text style.
  final TextStyle? isoCodeStyle;

  /// Search-input text style.
  final TextStyle? searchTextStyle;

  /// Dialog-title text style.
  final TextStyle? titleTextStyle;

  /// Search-input decoration.
  final InputDecoration? searchDecoration;

  /// Search cursor color.
  final Color? searchCursorColor;

  /// Dialog shape.
  final ShapeBorder? shape;

  /// Dialog elevation.
  final double? elevation;

  /// Dialog clip behavior.
  final Clip clipBehavior;

  /// Optional divider between controls and results.
  final Widget? divider;

  /// Default close icon.
  final Widget closeIcon;
}

/// Fully customizable searchable country-picker dialog.
final class CountryPickerDialog extends StatefulWidget {
  /// Creates a country picker.
  const CountryPickerDialog({
    required this.countries,
    required this.onSelected,
    super.key,
    this.selectedCountry,
    this.configuration = const CountryPickerDialogConfiguration(),
    this.itemBuilder,
    this.searchFieldBuilder,
    this.flagBuilder,
    this.titleBuilder,
    this.emptyBuilder,
    this.dialogBuilder,
    this.searchController,
  });

  /// Countries available for selection.
  final List<Country> countries;

  /// Currently selected country.
  final Country? selectedCountry;

  /// Called when a country row is selected.
  final ValueChanged<Country> onSelected;

  /// Default visual and behavioral configuration.
  final CountryPickerDialogConfiguration configuration;

  /// Optional complete replacement for each country row.
  final CountryPickerItemBuilder? itemBuilder;

  /// Optional complete replacement for the search text field.
  final CountryPickerSearchFieldBuilder? searchFieldBuilder;

  /// Optional replacement for default flag content.
  final CountryPickerFlagBuilder? flagBuilder;

  /// Optional replacement for the title row.
  final CountryPickerTitleBuilder? titleBuilder;

  /// Optional replacement for the no-results state.
  final CountryPickerEmptyBuilder? emptyBuilder;

  /// Optional wrapper or replacement for the default [Dialog].
  final CountryPickerDialogBuilder? dialogBuilder;

  /// Optional externally managed search controller.
  final TextEditingController? searchController;

  @override
  State<CountryPickerDialog> createState() => _CountryPickerDialogState();
}

final class _CountryPickerDialogState extends State<CountryPickerDialog> {
  TextEditingController? _internalController;
  String _query = '';

  TextEditingController get _controller =>
      widget.searchController ??
      (_internalController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _query = _controller.text;
  }

  @override
  void didUpdateWidget(CountryPickerDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchController != widget.searchController) {
      _internalController?.dispose();
      _internalController = null;
      _query = _controller.text;
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configuration = widget.configuration;
    final countries = _filteredCountries();
    final content = ConstrainedBox(
      constraints: configuration.constraints,
      child: SizedBox(
        width: configuration.dialogWidth,
        height: configuration.dialogHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: configuration.titlePadding,
              child: widget.titleBuilder?.call(context, _close) ??
                  _DefaultTitle(
                    configuration: configuration,
                    close: _close,
                  ),
            ),
            if (configuration.showSearch)
              Padding(
                padding: configuration.searchPadding,
                child: widget.searchFieldBuilder?.call(
                      context,
                      _controller,
                      _onSearchChanged,
                    ) ??
                    TextField(
                      controller: _controller,
                      autofocus: configuration.searchAutofocus,
                      style: configuration.searchTextStyle,
                      cursorColor: configuration.searchCursorColor,
                      textInputAction: TextInputAction.search,
                      decoration: configuration.searchDecoration ??
                          InputDecoration(
                            hintText: configuration.searchHintText,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: _clearSearch,
                                    icon: const Icon(Icons.clear),
                                  ),
                            border: const OutlineInputBorder(),
                          ),
                      onChanged: _onSearchChanged,
                    ),
              ),
            configuration.divider ?? const Divider(height: 1),
            Flexible(
              child: countries.isEmpty
                  ? widget.emptyBuilder?.call(context, _query.trim()) ??
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(configuration.noResultsText),
                        ),
                      )
                  : ListView.builder(
                      padding: configuration.listPadding,
                      itemCount: countries.length,
                      itemBuilder: (context, index) {
                        final country = countries[index];
                        final selected =
                            widget.selectedCountry?.iso2 == country.iso2;
                        void select() {
                          widget.onSelected(country);
                        }

                        return widget.itemBuilder?.call(
                              context,
                              country,
                              selected,
                              select,
                            ) ??
                            _DefaultCountryItem(
                              country: country,
                              selected: selected,
                              select: select,
                              configuration: configuration,
                              flagBuilder: widget.flagBuilder,
                            );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
    return widget.dialogBuilder?.call(context, content) ??
        Dialog(
          insetPadding: configuration.insetPadding,
          backgroundColor: configuration.backgroundColor,
          surfaceTintColor: configuration.surfaceTintColor,
          shape: configuration.shape,
          elevation: configuration.elevation,
          clipBehavior: configuration.clipBehavior,
          child: content,
        );
  }

  List<Country> _filteredCountries() {
    if (_query.trim().isEmpty) {
      return widget.countries;
    }
    return rankedLocationSearch<Country>(
      values: widget.countries,
      query: _query,
      name: (country) => country.name,
      aliases: (country) => <String>[
        country.iso2,
        country.iso3,
        if (country.phoneCode != null) country.phoneCode!,
        if (country.nativeName != null) country.nativeName!,
      ],
      limit: widget.countries.length,
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
    });
  }

  void _clearSearch() {
    _controller.clear();
    _onSearchChanged('');
  }

  void _close() {
    unawaited(Navigator.of(context).maybePop());
  }
}

final class _DefaultTitle extends StatelessWidget {
  const _DefaultTitle({
    required this.configuration,
    required this.close,
  });

  final CountryPickerDialogConfiguration configuration;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Expanded(
            child: Text(
              configuration.title,
              style: configuration.titleTextStyle ??
                  Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (configuration.showCloseButton)
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: close,
              icon: configuration.closeIcon,
            ),
        ],
      );
}

final class _DefaultCountryItem extends StatelessWidget {
  const _DefaultCountryItem({
    required this.country,
    required this.selected,
    required this.select,
    required this.configuration,
    required this.flagBuilder,
  });

  final Country country;
  final bool selected;
  final VoidCallback select;
  final CountryPickerDialogConfiguration configuration;
  final CountryPickerFlagBuilder? flagBuilder;

  @override
  Widget build(BuildContext context) => Padding(
        padding: configuration.itemPadding,
        child: Material(
          color: selected
              ? configuration.selectedColor ??
                  Theme.of(context).colorScheme.secondaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: ListTile(
            selected: selected,
            onTap: select,
            leading: configuration.showFlag
                ? Padding(
                    padding: configuration.flagPadding,
                    child: flagBuilder?.call(context, country) ??
                        Text(
                          countryFlagEmoji(country.iso2),
                          style: configuration.flagTextStyle ??
                              const TextStyle(fontSize: 24),
                        ),
                  )
                : null,
            title: Text(country.name, style: configuration.countryNameStyle),
            subtitle: configuration.showIsoCode
                ? Text(country.iso2, style: configuration.isoCodeStyle)
                : null,
            trailing: configuration.showPhoneCode
                ? Text(
                    normalizedDialingCode(country),
                    style: configuration.phoneCodeStyle,
                  )
                : null,
          ),
        ),
      );
}

/// Presents a [CountryPickerDialog] and returns the selected country.
Future<Country?> showCountryPickerDialog({
  required BuildContext context,
  required List<Country> countries,
  Country? selectedCountry,
  CountryPickerDialogConfiguration configuration =
      const CountryPickerDialogConfiguration(),
  CountryPickerItemBuilder? itemBuilder,
  CountryPickerSearchFieldBuilder? searchFieldBuilder,
  CountryPickerFlagBuilder? flagBuilder,
  CountryPickerTitleBuilder? titleBuilder,
  CountryPickerEmptyBuilder? emptyBuilder,
  CountryPickerDialogBuilder? dialogBuilder,
  TextEditingController? searchController,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) =>
    showDialog<Country>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
      builder: (context) => CountryPickerDialog(
        countries: countries,
        selectedCountry: selectedCountry,
        configuration: configuration,
        itemBuilder: itemBuilder,
        searchFieldBuilder: searchFieldBuilder,
        flagBuilder: flagBuilder,
        titleBuilder: titleBuilder,
        emptyBuilder: emptyBuilder,
        dialogBuilder: dialogBuilder,
        searchController: searchController,
        onSelected: (country) {
          Navigator.of(context).pop(country);
        },
      ),
    );

/// Returns a country calling code with exactly one leading `+`.
String normalizedDialingCode(Country country) {
  final code = country.phoneCode?.trim() ?? '';
  return code.isEmpty ? '' : '+${code.replaceFirst(RegExp(r'^\++'), '')}';
}

/// Converts a two-letter ASCII ISO country code to a flag emoji.
String countryFlagEmoji(String iso2) {
  final code = iso2.trim().toUpperCase();
  if (!RegExp(r'^[A-Z]{2}$').hasMatch(code)) {
    return '';
  }
  return String.fromCharCodes(
    code.codeUnits.map((unit) => unit + 0x1F1A5),
  );
}
