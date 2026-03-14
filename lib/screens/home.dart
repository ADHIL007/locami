import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/core/geo-location-Manager/street-Manager.dart';
import 'package:locami/dbManager/userModel_manager.dart';
import 'package:locami/dbManager/trip_details_manager.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/screens/widgets/trip_info_display.dart';
import 'package:locami/screens/widgets/home_header.dart';
import 'package:locami/screens/widgets/home_input_card.dart';
import 'package:locami/screens/widgets/home_distance_option.dart';
import 'package:locami/screens/widgets/tracking_button.dart';
import 'package:locami/screens/widgets/location_search_sheet.dart';
import 'package:locami/screens/widgets/trip_history_card.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:locami/screens/widgets/arrival_alert.dart';

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
  bool _isTrackingLoading = false;
  Position? _currentPosition;
  Timer? _transmissionTimer;
  bool _showLocami = true;

  int _alertDistance = 500;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _fromController.addListener(_onTextChanged);
    _toController.addListener(_onTextChanged);

    _loadUserCountryFromProfile();
    _loadNearbyStreets();
    _loadTripHistory();
    _checkTrackingStatus();
    _getInitialLocation();
    TripDetailsManager.instance.isTrackingNotifier.addListener(
      _onTrackingStatusChanged,
    );
    TripDetailsManager.instance.alertTriggeredNotifier.addListener(
      _onAlertTriggered,
    );
  }

  void _onAlertTriggered() {
    final distance = TripDetailsManager.instance.alertTriggeredNotifier.value;
    if (distance != null && mounted) {
      _showArrivalAlert(distance);
    }
  }

  void _showArrivalAlert(double distance) {
    final themeProvider = context.read<ThemeProvider>();
    final soundKey = themeProvider.alertSound;
    final isCustom = themeProvider.isCustomSound;
    final customPath = themeProvider.customSoundPath;

    // Start playing sound
    _stopAllSounds();

    if (isCustom && customPath != null) {
      _audioPlayer.play(DeviceFileSource(customPath));
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
    } else {
      if (soundKey == 'alarm') {
        FlutterRingtonePlayer().playAlarm(looping: true);
      } else if (soundKey == 'ringtone') {
        FlutterRingtonePlayer().playRingtone(looping: true);
      } else {
        FlutterRingtonePlayer().playNotification(looping: true);
      }
    }

    final destination =
        TripDetailsManager.instance.currentTripDetail.value?.destination ??
        "Destination";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ArrivalAlert(
            destination: destination,
            onDone: () {
              _stopAllSounds();
              Navigator.pop(context);
              _toggleTracking();
            },
            onThanks: () {
              _stopAllSounds();
              Navigator.pop(context);
            },
          ),
    );
  }

  void _stopAllSounds() {
    FlutterRingtonePlayer().stop();
    _audioPlayer.stop();
  }

  void _onTrackingStatusChanged() {
    final isTrackingNow = TripDetailsManager.instance.isTracking;
    if (mounted) {
      if (_isTracking != isTrackingNow) {
        setState(() {
          _isTracking = isTrackingNow;
          if (_isTracking) {
            _startTransmission();
          } else {
            _stopTransmission();
            _loadTripHistory();
          }
        });
      }
    }
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
    _transmissionTimer?.cancel();
    TripDetailsManager.instance.isTrackingNotifier.removeListener(
      _onTrackingStatusChanged,
    );
    TripDetailsManager.instance.alertTriggeredNotifier.removeListener(
      _onAlertTriggered,
    );
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkTrackingStatus() async {
    if (TripDetailsManager.instance.isTracking) {
      if (mounted) {
        setState(() => _isTracking = true);
        _startTransmission();
      }
    }
  }

  void _startTransmission() {
    _transmissionTimer?.cancel();
    _transmissionTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (mounted && _isTracking) {
        setState(() {
          _showLocami = !_showLocami;
        });
      } else if (!_isTracking) {
        _stopTransmission();
      }
    });
  }

  void _stopTransmission() {
    _transmissionTimer?.cancel();
    if (mounted) {
      setState(() {
        _showLocami = true;
      });
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
  List<TripDetailsModel> _tripHistory = [];
  bool _isLoadingHistory = false;

  Future<void> _loadTripHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await TripDetailsManager.instance.getLogs();
      if (mounted) {
        setState(() {
          _tripHistory = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _toggleTracking() async {
    if (_isTrackingLoading) return;

    setState(() => _isTrackingLoading = true);
    if (_isTracking) {
      try {
        await TripDetailsManager.instance.stopTracking();
        if (mounted) {
          setState(() {
            _isTracking = false;
            _isTrackingLoading = false;
          });
          _stopTransmission();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isTrackingLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error stopping tracking: $e')),
          );
        }
      }
    } else {
      try {
        await UserModelManager.instance.patchUser(
          fromStreet: _fromController.text,
          destinationStreet: _toController.text,
          destinationLatitude: null,
          destinationLongitude: null,
        );

        await TripDetailsManager.instance.startTracking(
          alertDistance: _alertDistance.toDouble(),
        );
        if (mounted) {
          setState(() {
            _isTracking = true;
            _isTrackingLoading = false;
          });
          _startTransmission();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isTrackingLoading = false);
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
          (context) => LocationSearchSheet(
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

  void _showAllHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _HistoryBottomSheet(
            history: _tripHistory,
            onClear: () async {
              await TripDetailsManager.instance.clearLogs();
              _loadTripHistory();
              Navigator.pop(context);
            },
            onRestart: (TripDetailsModel trip) {
              _fromController.text = trip.street ?? "";
              _toController.text = trip.destination ?? "";
              Navigator.pop(context);
              _toggleTracking();
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
              HomeHeader(
                isTracking: _isTracking,
                showLocami: _showLocami,
                accentColor: accentColor,
              ),
              const SizedBox(height: 32),

              HomeInputCard(
                controller: _fromController,
                label: "From",
                hint: "Select starting point",
                icon: Icons.home,
                onTap: _isTracking ? null : () => _showLocationSearch(true),
              ),
              const SizedBox(height: 12),

              HomeInputCard(
                controller: _toController,
                label: "To",
                hint: "Select destination",
                icon: Icons.flag,
                iconColor: accentColor,
                onTap: _isTracking ? null : () => _showLocationSearch(false),
              ),
              const SizedBox(height: 24),

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
                  HomeDistanceOption(
                    distance: "500m",
                    isSelected: _alertDistance == 500,
                    onTap:
                        _isTracking
                            ? null
                            : () => setState(() => _alertDistance = 500),
                  ),
                  HomeDistanceOption(
                    distance: "1km",
                    isSelected: _alertDistance == 1000,
                    onTap:
                        _isTracking
                            ? null
                            : () => setState(() => _alertDistance = 1000),
                  ),
                  HomeDistanceOption(
                    distance: "2km",
                    isSelected: _alertDistance == 2000,
                    onTap:
                        _isTracking
                            ? null
                            : () => setState(() => _alertDistance = 2000),
                  ),
                  const Spacer(),
                  TrackingButton(
                    isTracking: _isTracking,
                    isLoading: _isTrackingLoading,
                    canStart: validateisTracking(),
                    accentColor: accentColor,
                    onPressed: _toggleTracking,
                  ),
                ],
              ),

              if (_isTracking || TripDetailsManager.instance.isTracking) ...[
                const SizedBox(height: 32),
                const TripInfoDisplay(),
              ] else ...[
                const SizedBox(height: 32),
                if (_isLoadingHistory)
                  const Center(child: CircularProgressIndicator())
                else if (_tripHistory.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Trips",
                        style: TextStyle(
                          color: customColors().textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_tripHistory.length > 3)
                        TextButton(
                          onPressed: _showAllHistory,
                          child: const Text("Show More"),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Column(
                        children:
                            _tripHistory
                                .take(3)
                                .map(
                                  (TripDetailsModel trip) => TripHistoryCard(
                                    trip: trip,
                                    onRestart: () {
                                      _fromController.text = trip.street ?? "";
                                      _toController.text =
                                          trip.destination ?? "";
                                      _toggleTracking();
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                      if (_tripHistory.length > 3)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  customColors().background.withOpacity(0),
                                  customColors().background,
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        SvgPicture.asset(
                          'assets/images/busTerminal.svg',
                          height: 240,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "No track history yet",
                          style: TextStyle(
                            color: customColors().textPrimary.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryBottomSheet extends StatelessWidget {
  final List<TripDetailsModel> history;
  final VoidCallback onClear;
  final Function(TripDetailsModel) onRestart;

  const _HistoryBottomSheet({
    Key? key,
    required this.history,
    required this.onClear,
    required this.onRestart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "All Recent Trips",
                style: TextStyle(
                  color: customColors().textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onClear,
                child: const Text(
                  "Clear All",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                return TripHistoryCard(
                  trip: history[index],
                  onRestart: () => onRestart(history[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
