import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../country_subdivision_data_base.dart';
import '../models/country.dart';
import '../models/country_phone_number.dart';
import 'country_picker_dialog.dart';

/// Builds the button used to open the country picker.
typedef CountryPhoneSelectorBuilder = Widget Function(
  BuildContext context,
  Country? country,
  bool enabled,
  VoidCallback openPicker,
);

/// Completely replaces the default phone text field.
///
/// The builder receives picker state and [openPicker], so a custom composition
/// can place the country selector anywhere.
typedef CountryPhoneTextFieldBuilder = Widget Function(
  BuildContext context,
  TextEditingController controller,
  FocusNode focusNode,
  Country? country,
  bool enabled,
  VoidCallback openPicker,
  ValueChanged<String> onChanged,
);

/// Presents a custom country picker route.
typedef CountryPickerPresenter = Future<Country?> Function(
  BuildContext context,
  List<Country> countries,
  Country? selectedCountry,
);

/// Builds a state shown while countries load.
typedef CountryPhoneLoadingBuilder = Widget Function(BuildContext context);

/// Builds a state shown when countries cannot be loaded.
typedef CountryPhoneErrorBuilder = Widget Function(
    BuildContext context, Object error, VoidCallback retry);

/// Fully customizable country-aware phone-number form field.
///
/// This widget does not perform country-specific phone validation. Supply
/// [validator] when application-specific validation is required.
final class CountryPhoneField extends StatefulWidget {
  /// Creates a country-aware phone field.
  const CountryPhoneField({
    super.key,
    this.data,
    this.controller,
    this.focusNode,
    this.initialCountryCode = 'US',
    this.initialValue,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.keyboardType = TextInputType.phone,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.showCursor,
    this.cursorColor,
    this.cursorWidth = 2,
    this.cursorHeight,
    this.cursorRadius,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.onEditingComplete,
    this.onSubmitted,
    this.onTap,
    this.onTapOutside,
    this.decoration = const InputDecoration(labelText: 'Phone number'),
    this.autovalidateMode,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.onCountryChanged,
    this.countryFilter,
    this.favoriteCountryCodes = const <String>[],
    this.selectorBuilder,
    this.phoneTextFieldBuilder,
    this.pickerPresenter,
    this.pickerConfiguration = const CountryPickerDialogConfiguration(),
    this.pickerItemBuilder,
    this.pickerSearchFieldBuilder,
    this.pickerFlagBuilder,
    this.pickerTitleBuilder,
    this.pickerEmptyBuilder,
    this.pickerDialogBuilder,
    this.countrySelectorPadding = const EdgeInsets.symmetric(horizontal: 8),
    this.countrySelectorConstraints = const BoxConstraints(minWidth: 88),
    this.loadingBuilder,
    this.errorBuilder,
    this.pickerBarrierDismissible = true,
    this.pickerBarrierColor,
    this.pickerBarrierLabel,
    this.useRootNavigator = true,
    this.pickerRouteSettings,
  });

  /// Data facade used to load countries.
  final CountrySubdivisionData? data;

  /// Optional externally managed phone-text controller.
  final TextEditingController? controller;

  /// Optional externally managed focus node.
  final FocusNode? focusNode;

  /// Initial ISO2 or ISO3 country code.
  final String? initialCountryCode;

  /// Initial national-number text when [controller] is absent.
  final String? initialValue;

  /// Whether the selector and phone input are enabled.
  final bool enabled;

  /// Whether the default text field is read-only.
  final bool readOnly;

  /// Whether the default text field requests focus.
  final bool autofocus;

  /// Whether the default text field obscures its text.
  final bool obscureText;

  /// Keyboard used by the default text field.
  final TextInputType keyboardType;

  /// Action button used by the default text field.
  final TextInputAction? textInputAction;

  /// Capitalization used by the default text field.
  final TextCapitalization textCapitalization;

  /// Input formatters used by the default text field.
  final List<TextInputFormatter>? inputFormatters;

  /// Text style used by the default text field.
  final TextStyle? style;

  /// Strut style used by the default text field.
  final StrutStyle? strutStyle;

  /// Text alignment used by the default text field.
  final TextAlign textAlign;

  /// Text direction used by the default text field.
  final TextDirection? textDirection;

  /// Whether the default field shows a cursor.
  final bool? showCursor;

  /// Cursor color.
  final Color? cursorColor;

  /// Cursor width.
  final double cursorWidth;

  /// Cursor height.
  final double? cursorHeight;

  /// Cursor corner radius.
  final Radius? cursorRadius;

  /// Maximum character count.
  final int? maxLength;

  /// Maximum line count.
  final int? maxLines;

  /// Minimum line count.
  final int? minLines;

  /// Whether the default field expands to its parent.
  final bool expands;

  /// Default field editing-complete callback.
  final VoidCallback? onEditingComplete;

  /// Default field submission callback.
  final ValueChanged<String>? onSubmitted;

  /// Default field tap callback.
  final GestureTapCallback? onTap;

  /// Default field outside-tap callback.
  final TapRegionCallback? onTapOutside;

  /// Default field decoration. Its prefix icon is replaced by the selector.
  final InputDecoration decoration;

  /// Form autovalidation behavior.
  final AutovalidateMode? autovalidateMode;

  /// Validates the structured country-aware value.
  final FormFieldValidator<CountryPhoneNumber>? validator;

  /// Saves the structured country-aware value.
  final FormFieldSetter<CountryPhoneNumber>? onSaved;

  /// Called whenever country or phone text changes.
  final ValueChanged<CountryPhoneNumber>? onChanged;

  /// Called after selecting a different country.
  final ValueChanged<Country>? onCountryChanged;

  /// Optional predicate limiting picker countries.
  final bool Function(Country country)? countryFilter;

  /// ISO2/ISO3 codes pinned to the beginning of the picker.
  final List<String> favoriteCountryCodes;

  /// Replaces the default selector button.
  final CountryPhoneSelectorBuilder? selectorBuilder;

  /// Replaces the complete default phone text field and selector composition.
  ///
  /// When set, the builder owns form integration and should call the supplied
  /// text-change callback.
  final CountryPhoneTextFieldBuilder? phoneTextFieldBuilder;

  /// Replaces picker presentation, including route and dialog.
  final CountryPickerPresenter? pickerPresenter;

  /// Default picker configuration.
  final CountryPickerDialogConfiguration pickerConfiguration;

  /// Optional custom picker rows.
  final CountryPickerItemBuilder? pickerItemBuilder;

  /// Optional custom picker search field.
  final CountryPickerSearchFieldBuilder? pickerSearchFieldBuilder;

  /// Optional custom picker flags.
  final CountryPickerFlagBuilder? pickerFlagBuilder;

  /// Optional custom picker title.
  final CountryPickerTitleBuilder? pickerTitleBuilder;

  /// Optional custom picker empty state.
  final CountryPickerEmptyBuilder? pickerEmptyBuilder;

  /// Optional custom picker dialog wrapper.
  final CountryPickerDialogBuilder? pickerDialogBuilder;

  /// Padding inside the default selector.
  final EdgeInsets countrySelectorPadding;

  /// Constraints for the default selector.
  final BoxConstraints countrySelectorConstraints;

  /// Replaces the selector while country data loads.
  final CountryPhoneLoadingBuilder? loadingBuilder;

  /// Replaces the selector when loading fails.
  final CountryPhoneErrorBuilder? errorBuilder;

  /// Whether the default picker route can be dismissed via its barrier.
  final bool pickerBarrierDismissible;

  /// Picker route barrier color.
  final Color? pickerBarrierColor;

  /// Picker route barrier label.
  final String? pickerBarrierLabel;

  /// Whether the picker uses the root navigator.
  final bool useRootNavigator;

  /// Picker route settings.
  final RouteSettings? pickerRouteSettings;

  @override
  State<CountryPhoneField> createState() => _CountryPhoneFieldState();
}

final class _CountryPhoneFieldState extends State<CountryPhoneField> {
  TextEditingController? _internalController;
  FocusNode? _internalFocusNode;
  List<Country> _countries = const <Country>[];
  Country? _country;
  Object? _loadError;
  bool _loading = true;

  CountrySubdivisionData get _data =>
      widget.data ?? CountrySubdivisionData.instance;

  TextEditingController get _controller =>
      widget.controller ??
      (_internalController ??= TextEditingController(
        text: widget.initialValue,
      ));

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  CountryPhoneNumber? get _value {
    final country = _country;
    return country == null
        ? null
        : CountryPhoneNumber(
            country: country,
            nationalNumber: _controller.text,
          );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadCountries(preferRequestedCountry: true));
  }

  @override
  void didUpdateWidget(CountryPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _internalController?.dispose();
      _internalController = null;
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _internalFocusNode?.dispose();
      _internalFocusNode = null;
    }
    final initialCountryChanged =
        oldWidget.initialCountryCode != widget.initialCountryCode;
    if (oldWidget.data != widget.data ||
        initialCountryChanged ||
        oldWidget.countryFilter != widget.countryFilter ||
        !listEquals(
          oldWidget.favoriteCountryCodes,
          widget.favoriteCountryCodes,
        )) {
      unawaited(_loadCountries(preferRequestedCountry: initialCountryChanged));
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.phoneTextFieldBuilder != null) {
      return widget.phoneTextFieldBuilder!(
        context,
        _controller,
        _focusNode,
        _country,
        widget.enabled && !widget.readOnly,
        _openPicker,
        _onPhoneChanged,
      );
    }
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      style: widget.style,
      strutStyle: widget.strutStyle,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      showCursor: widget.showCursor,
      cursorColor: widget.cursorColor,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      onTapOutside: widget.onTapOutside,
      decoration: widget.decoration.copyWith(
        prefixIcon: _buildSelector(context),
        prefixIconConstraints: widget.countrySelectorConstraints,
      ),
      autovalidateMode: widget.autovalidateMode,
      validator: (_) => widget.validator?.call(_value),
      onSaved: (_) => widget.onSaved?.call(_value),
      onChanged: _onPhoneChanged,
    );
  }

  Widget _buildSelector(BuildContext context) {
    if (_loading) {
      return widget.loadingBuilder?.call(context) ??
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
    }
    final error = _loadError;
    if (error != null) {
      return widget.errorBuilder?.call(context, error, _retry) ??
          IconButton(
            tooltip: 'Retry loading countries',
            onPressed: widget.enabled ? _retry : null,
            icon: const Icon(Icons.refresh),
          );
    }
    final enabled = widget.enabled && !widget.readOnly;
    return widget.selectorBuilder?.call(
          context,
          _country,
          enabled,
          _openPicker,
        ) ??
        InkWell(
          onTap: enabled ? _openPicker : null,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: widget.countrySelectorPadding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (_country != null) ...<Widget>[
                  Text(
                    countryFlagEmoji(_country!.iso2),
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 6),
                  Text(normalizedDialingCode(_country!)),
                ],
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        );
  }

  Future<void> _loadCountries({bool preferRequestedCountry = false}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      await _data.initialize();
      var countries = await _data.getCountries();
      final filter = widget.countryFilter;
      if (filter != null) {
        countries = countries.where(filter).toList(growable: false);
      }
      countries = _favoritesFirst(countries, widget.favoriteCountryCodes);
      final requestedCode = widget.initialCountryCode?.trim().toUpperCase();
      final previousCode = _country?.iso2;
      final preferredCode = preferRequestedCountry
          ? requestedCode
          : previousCode ?? requestedCode;
      Country? selected;
      for (final country in countries) {
        if (country.iso2 == preferredCode || country.iso3 == preferredCode) {
          selected = country;
          break;
        }
      }
      selected ??= countries.firstOrNull;
      if (!mounted) {
        return;
      }
      setState(() {
        _countries = List<Country>.unmodifiable(countries);
        _country = selected;
        _loading = false;
      });
      _notifyChanged();
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error;
          _loading = false;
        });
      }
    }
  }

  Future<void> _openPicker() async {
    if (_countries.isEmpty || !widget.enabled || widget.readOnly) {
      return;
    }
    final selected =
        await (widget.pickerPresenter?.call(context, _countries, _country) ??
            showCountryPickerDialog(
              context: context,
              countries: _countries,
              selectedCountry: _country,
              configuration: widget.pickerConfiguration,
              itemBuilder: widget.pickerItemBuilder,
              searchFieldBuilder: widget.pickerSearchFieldBuilder,
              flagBuilder: widget.pickerFlagBuilder,
              titleBuilder: widget.pickerTitleBuilder,
              emptyBuilder: widget.pickerEmptyBuilder,
              dialogBuilder: widget.pickerDialogBuilder,
              barrierDismissible: widget.pickerBarrierDismissible,
              barrierColor: widget.pickerBarrierColor,
              barrierLabel: widget.pickerBarrierLabel,
              useRootNavigator: widget.useRootNavigator,
              routeSettings: widget.pickerRouteSettings,
            ));
    if (!mounted || selected == null || selected == _country) {
      return;
    }
    setState(() {
      _country = selected;
    });
    widget.onCountryChanged?.call(selected);
    _notifyChanged();
  }

  void _onPhoneChanged(String _) {
    _notifyChanged();
  }

  void _notifyChanged() {
    final value = _value;
    if (value != null) {
      widget.onChanged?.call(value);
    }
  }

  void _retry() {
    unawaited(_loadCountries());
  }
}

List<Country> _favoritesFirst(
  List<Country> countries,
  List<String> favoriteCodes,
) {
  if (favoriteCodes.isEmpty) {
    return countries;
  }
  final order = <String, int>{
    for (var index = 0; index < favoriteCodes.length; index += 1)
      favoriteCodes[index].trim().toUpperCase(): index,
  };
  final favorites = <({Country country, int order})>[];
  final remaining = <Country>[];
  for (final country in countries) {
    final index = order[country.iso2] ?? order[country.iso3];
    if (index == null) {
      remaining.add(country);
    } else {
      favorites.add((country: country, order: index));
    }
  }
  favorites.sort((left, right) => left.order.compareTo(right.order));
  return <Country>[...favorites.map((entry) => entry.country), ...remaining];
}
