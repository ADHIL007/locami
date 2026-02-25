import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/core/geo-location-Manager/street-Manager.dart';
import 'package:locami/dbManager/userModel_manager.dart';
import 'package:locami/dbManager/trip_details_manager.dart';
import 'package:locami/screens/widgets/trip_info_display.dart';
import 'package:locami/screens/widgets/settings_bottom_sheet.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  String userCountry = 'India';
  bool _isTracking = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();

    _fromController.addListener(_onTextChanged);
    _toController.addListener(_onTextChanged);

    _loadUserCountryFromProfile();
    _loadNearbyStreets();
    _checkTrackingStatus();
    _getInitialLocation();
  }

  Future<void> _getInitialLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkTrackingStatus() async {
    if (TripDetailsManager.instance.isTracking) {
      setState(() => _isTracking = true);
    }
  }

  Future<void> _loadNearbyStreets() async {
    final result = await StreetManager.instance.getNearbyStreets();
    setState(() => locations = result);
  }

  void _loadUserCountryFromProfile() async {
    final user = await UserModelManager.instance.user;
    setState(() {
      userCountry = user.country.isNotEmpty ? user.country : 'in';
    });
  }

  List<String> locations = [];

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      await TripDetailsManager.instance.stopTracking();
      setState(() => _isTracking = false);
    } else {
      try {
        await UserModelManager.instance.patchUser(
          fromStreet: _fromController.text,
          destinationStreet: _toController.text,

          destinationLatitude: null,
          destinationLongitude: null,
        );

        await TripDetailsManager.instance.startTracking();
        setState(() => _isTracking = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error starting tracking: $e')),
          );
        }
      }
    }
  }

  bool validateisTracking() {
    if (_fromController.text.isNotEmpty && _toController.text.isNotEmpty) {
      return true;
    }
    return false;
  }

  void _showLocationSearch(bool isFrom) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _LocationSearchSheet(
            isFrom: isFrom,
            initialValue: isFrom ? _fromController.text : _toController.text,
            userCountry: userCountry,
            currentPosition: _currentPosition,
            onSelected: (address) {
              setState(() {
                if (isFrom) {
                  _fromController.text = address;
                } else {
                  _toController.text = address;
                }
              });
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: accentColor, size: 32),
                          const SizedBox(width: 8),
                          Text(
                            "Locami",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: customColors().textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        "Offline Location Alert",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),

                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const SettingsBottomSheet(),
                      );
                    },
                    icon: Icon(
                      Icons.settings,
                      color: customColors().textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // const Text(
              //   "Destination Alert",
              //   style: TextStyle(
              //     fontSize: 18,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.white,
              //   ),
              // ),
              // const SizedBox(height: 16),

              // From Field
              _buildInputCard(
                controller: _fromController,
                label: "From",
                hint: "Select starting point",
                icon: Icons.home,
                onTap: _isTracking ? null : () => _showLocationSearch(true),
              ),
              const SizedBox(height: 12),

              // To Field
              _buildInputCard(
                controller: _toController,
                label: "To",
                hint: "Select destination",
                icon: Icons.flag,
                iconColor: accentColor,
                onTap: _isTracking ? null : () => _showLocationSearch(false),
              ),
              const SizedBox(height: 24),

              // Alert selection row
              Row(
                children: [
                  Text(
                    "Alert Me",
                    style: TextStyle(
                      color: customColors().textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildDistanceOption("500m", true),
                  _buildDistanceOption("1km", false),
                  _buildDistanceOption("2km", false),
                  const Spacer(),
                  if (!_isTracking) _buildStartButton(accentColor),
                ],
              ),

              if (_isTracking || TripDetailsManager.instance.isTracking) ...[
                const SizedBox(height: 32),
                const TripInfoDisplay(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Color iconColor = Colors.grey,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: customColors().textPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      return Text(
                        value.text.isEmpty ? hint : value.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: customColors().textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceOption(String distance, bool isSelected) {
    final accentColor = context.read<ThemeProvider>().accentColor;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            distance,
            style: TextStyle(
              color: isSelected ? customColors().textPrimary : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStartButton(Color accentColor) {
    bool canStart = validateisTracking();
    return Opacity(
      opacity: canStart ? 1 : 0.5,
      child: AbsorbPointer(
        absorbing: !canStart,
        child: ElevatedButton.icon(
          onPressed: _toggleTracking,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: customColors().textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.play_arrow, size: 18),
          label: const Text(
            "Start Tracking",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _LocationSearchSheet extends StatefulWidget {
  final bool isFrom;
  final String initialValue;
  final String userCountry;
  final Position? currentPosition;
  final Function(String) onSelected;

  const _LocationSearchSheet({
    required this.isFrom,
    required this.initialValue,
    required this.userCountry,
    this.currentPosition,
    required this.onSelected,
  });

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                color:
                    widget.isFrom
                        ? Colors.grey
                        : context.read<ThemeProvider>().accentColor,
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
                            color: context.read<ThemeProvider>().accentColor,
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
                // Re-use current location logic
                final details =
                    await StreetManager.instance.getCurrentLocationDetails();
                if (details != null && mounted) {
                  widget.onSelected(details['address']!);
                  Navigator.pop(context);
                }
              },
              leading: Icon(
                Icons.my_location,
                color: context.read<ThemeProvider>().accentColor,
              ),
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
