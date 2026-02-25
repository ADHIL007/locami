import 'package:flutter/material.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/dbManager/trip_details_manager.dart';
import 'package:locami/screens/widgets/settings_bottom_sheet.dart';
import 'package:locami/theme/them_provider.dart';

class HomeHeader extends StatelessWidget {
  final bool isTracking;
  final bool showLocami;
  final Color accentColor;

  const HomeHeader({
    Key? key,
    required this.isTracking,
    required this.showLocami,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: accentColor, size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ValueListenableBuilder<TripDetailsModel?>(
                      valueListenable:
                          TripDetailsManager.instance.currentTripDetail,
                      builder: (context, details, _) {
                        String displayText = "Locami";
                        if (isTracking &&
                            !showLocami &&
                            details != null &&
                            details.street != null) {
                          displayText = details.street!.split(',').first;
                        }

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          layoutBuilder: (
                            Widget? currentChild,
                            List<Widget> previousChildren,
                          ) {
                            return Stack(
                              alignment: Alignment.centerLeft,
                              children: <Widget>[
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            );
                          },
                          transitionBuilder: (
                            Widget child,
                            Animation<double> animation,
                          ) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: Text(
                            displayText,
                            key: ValueKey<String>(displayText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: customColors().textPrimary,
                            ),
                          ),
                        );
                      },
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
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const SettingsBottomSheet(),
            );
          },
          icon: Icon(Icons.settings, color: customColors().textPrimary),
        ),
      ],
    );
  }
}
