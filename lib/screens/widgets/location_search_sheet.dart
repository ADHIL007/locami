import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/core/geo-location-Manager/street-Manager.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class LocationSearchSheet extends StatefulWidget {
  final bool isFrom;
  final String initialValue;
  final String userCountry;
  final Position? currentPosition;
  final Function(String) onSelected;

  const LocationSearchSheet({
    Key? key,
    required this.isFrom,
    required this.initialValue,
    required this.userCountry,
    this.currentPosition,
    required this.onSelected,
  }) : super(key: key);

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
    _loadNearby();
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
    final accentColor = context.read<ThemeProvider>().accentColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: customColors().background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: customColors().textPrimary.withOpacity(0.1),
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
                color: customColors().textPrimary.withOpacity(0.3),
              ),
              prefixIcon: Icon(
                widget.isFrom ? Icons.home : Icons.flag,
                color: widget.isFrom ? Colors.grey : accentColor,
              ),
              filled: true,
              fillColor: customColors().textPrimary.withOpacity(0.05),
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
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => _searchController.clear(),
                      ),
            ),
            onChanged: _onSearchChanged,
          ),
          if (widget.isFrom) ...[
            const SizedBox(height: 16),
            ListTile(
              onTap: () async {
                final details =
                    await StreetManager.instance.getCurrentLocationDetails();
                if (details != null && mounted) {
                  widget.onSelected(details['address']!);
                  Navigator.pop(context);
                }
              },
              leading: Icon(Icons.my_location, color: accentColor),
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
                    color: customColors().textPrimary.withOpacity(0.05),
                  ),
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () {
                    widget.onSelected(_suggestions[index]);
                    Navigator.pop(context);
                  },
                  leading: const Icon(
                    Icons.location_on_outlined,
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
