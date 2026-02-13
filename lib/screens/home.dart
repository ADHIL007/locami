import 'package:flutter/material.dart';
import 'package:locami/core/geo-location-Manager/street-Manager.dart';
import 'package:locami/core/model/user_model.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserCountryFromProfile();
    _loadNearbyStreets();
    _checkTrackingStatus();
  }

  Future<void> _checkTrackingStatus() async {
    // Ideally check from persistent state or manager
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
    if (value.length < 2) {
      if (locations.isNotEmpty) setState(() => locations = []);
      return;
    }

    // Smarter logic:
    // 1. If length == 2, always fetch 100 to seed the local cache.
    // 2. If length > 2, check if we have enough local matches. If not, refetch specific query.

    final localMatches =
        locations
            .where((e) => e.toLowerCase().contains(value.toLowerCase()))
            .toList();
    final bool needsRefetch =
        (value.length == 2) || (value.length > 2 && localMatches.length < 5);

    if (needsRefetch) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () async {
        setState(() => _isLoading = true);

        // If we are refetching for >2 chars, we probably don't need 100 results, but 20 is safest to ensure diversity
        // If 2 chars, we strictly want 100 as per request.
        final limit = value.length == 2 ? 100 : 20;

        try {
          final result = await StreetManager.instance.searchStreets(
            value,
            countryCode: userCountry.toLowerCase(),
            limit: limit,
          );

          if (mounted) {
            setState(() {
              locations = result;
              _isLoading = false;
            });
          }
        } catch (e) {
          if (mounted) setState(() => _isLoading = false);
        }
      });
    }
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

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isTracking ? Colors.red : customColors().textPrimary,
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
                ],
              ),
              const SizedBox(height: 20),
              // Trip Details Section
              if (_isTracking || TripDetailsManager.instance.isTracking)
                const TripInfoDisplay(),
            ],
          ),
        ),
      ),
    );
  }
}
