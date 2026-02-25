import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/core/geo-location-Manager/street-Manager.dart';
import 'package:locami/dbManager/userModel_manager.dart';
import 'package:locami/dbManager/trip_details_manager.dart';
import 'package:locami/screens/widgets/location_search_field.dart';
import 'package:locami/screens/widgets/trip_info_display.dart';
import 'package:locami/theme/them_provider.dart';
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
  bool _isLocating = false;
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
    _debounce?.cancel();
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

  Future<void> _onGpsIconPressed() async {
    setState(() => _isLocating = true);

    try {
      final details = await StreetManager.instance.getCurrentLocationDetails();
      if (details != null && mounted) {
        setState(() {
          _fromController.text = details['address']!;
          userCountry = details['countryCode']!;
        });

        _currentPosition = await Geolocator.getCurrentPosition();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _loadNearbyStreets() async {
    final result = await StreetManager.instance.getNearbyStreets();
    setState(() => locations = result);
  }

  Timer? _debounce;

  bool _isLoading = false;

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        locations = [];
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isLoading = true);
      try {
        final results = await StreetManager.instance.searchStreets(
          value,
          countryCode: userCountry,
          lat: _currentPosition?.latitude,
          lon: _currentPosition?.longitude,
        );
        if (mounted) {
          setState(() {
            locations = results;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: customColors().background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child:
                    _isTracking
                        ? const SizedBox.shrink()
                        : Column(
                          children: [
                            LocationSearchField(
                              controller: _fromController,
                              label: 'From',
                              prefixIcon:
                                  _isLocating
                                      ? Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: customColors().textSecondary,
                                          ),
                                        ),
                                      )
                                      : IconButton(
                                        icon: Icon(
                                          Icons.my_location,
                                          size: 20,
                                          color: customColors().textSecondary,
                                        ),
                                        onPressed: _onGpsIconPressed,
                                        tooltip: 'Use current location',
                                      ),
                              suggestions: locations,
                              isLoading: _isLoading,
                              onSearchChanged: _onSearchChanged,
                            ),
                            const SizedBox(height: 12),
                            LocationSearchField(
                              controller: _toController,
                              label: 'To',
                              prefixIcon: Icon(
                                Icons.flag_outlined,
                                size: 20,
                                color: customColors().textSecondary,
                              ),
                              suggestions: locations,
                              isLoading: _isLoading,
                              onSearchChanged: _onSearchChanged,
                            ),
                          ],
                        ),
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _isTracking
                      ? IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.alarm_add,
                          size: 32,
                          color: customColors().textPrimary,
                        ),
                      )
                      : SizedBox(),

                  Opacity(
                    opacity: validateisTracking() ? 1 : 0.5,
                    child: AbsorbPointer(
                      absorbing: !validateisTracking(),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isTracking
                                  ? Colors.red
                                  : customColors().textPrimary,
                          foregroundColor: customColors().background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _toggleTracking,
                        label: Text(
                          _isTracking ? 'Stop Tracking' : 'Start Tracking',
                        ),
                        icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                        iconAlignment: IconAlignment.end,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_isTracking || TripDetailsManager.instance.isTracking)
                const TripInfoDisplay(),
            ],
          ),
        ),
      ),
    );
  }
}
