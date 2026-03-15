import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/core/geo_location_manager/street_manager.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:locami/core/widgets/glass_container.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class LocationSearchSheet extends StatefulWidget {
  final bool isFrom;
  final String initialValue;
  final String userCountry;
  final Position? currentPosition;
  final Function(String) onSelected;

  const LocationSearchSheet({
    super.key,
    required this.isFrom,
    required this.initialValue,
    required this.userCountry,
    this.currentPosition,
    required this.onSelected,
  });

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  late TextEditingController _searchController;
  List<String> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialValue);
    if (widget.isFrom && widget.initialValue.isEmpty) {
      _loadNearby();
    }
  }

  void _loadNearby() async {
    setState(() => _isLoading = true);
    final results = await StreetManager.instance.getNearbyStreets();
    if (mounted) {
      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (value.trim().isEmpty) {
      _loadNearby();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final results = await StreetManager.instance.searchStreets(
          value,
          countryCode: widget.userCountry,
          lat: widget.currentPosition?.latitude,
          lon: widget.currentPosition?.longitude,
        );
        if (mounted) {
          setState(() {
            _suggestions = results;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.theme == AppThemeMode.dark;

    return GlassContainer(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      opacity: isDark ? 0.15 : 0.7,
      blur: 25,
      color: isDark ? Colors.white : Colors.white.withValues(alpha: 0.9),
      customBorderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      border: Border.all(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.1) 
            : Colors.white.withValues(alpha: 0.5),
        width: 1.5,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: customColors().textPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(color: customColors().textPrimary),
            decoration: InputDecoration(
              hintText:
                  widget.isFrom ? "Search location" : "Search destination",
              hintStyle: TextStyle(
                color: customColors().textPrimary.withValues(alpha: 0.3),
              ),
              prefixIcon: Icon(
                widget.isFrom ? SolarIconsBold.home : SolarIconsBold.flag,
                color: widget.isFrom ? Colors.grey : accentColor,
              ),
              filled: true,
              fillColor: customColors().textPrimary.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon:
                  _isLoading
                      ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentColor,
                          ),
                        ),
                      )
                      : IconButton(
                        icon: Icon(SolarIconsOutline.closeCircle, color: Colors.grey),
                        onPressed: () => _searchController.clear(),
                      ),
            ),
            onChanged: _onSearchChanged,
          ),
          if (widget.isFrom && _suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            ListTile(
              onTap: () async {
                final details =
                    await StreetManager.instance.getCurrentLocationDetails();
                if (!context.mounted) return;
                if (details != null && mounted) {
                  widget.onSelected(details['address']!);
                  Navigator.pop(context);
                }
              },
              leading: Icon(SolarIconsOutline.gps, color: accentColor),
              title: Text(
                "Use Current Location",
                style: TextStyle(color: customColors().textPrimary),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _suggestions.length,
              separatorBuilder:
                  (_, __) => Divider(
                    color: customColors().textPrimary.withValues(alpha: 0.05),
                  ),
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () {
                    widget.onSelected(_suggestions[index]);
                    Navigator.pop(context);
                  },
                  leading: Icon(
                    SolarIconsOutline.mapPoint,
                    color: Colors.grey,
                  ),
                  title: Text(
                    _suggestions[index],
                    style: TextStyle(color: customColors().textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
