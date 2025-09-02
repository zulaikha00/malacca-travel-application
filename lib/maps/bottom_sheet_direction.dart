import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fyp25/maps/route_options.dart';
import 'mode_selecter_icon.dart';
import 'nearby_places.dart';

class DirectionBottomSheet extends StatelessWidget {
  final ScrollController scrollController;
  final LatLng? fromLocation;
  final LatLng? toLocation;
  final String toName;
  final String travelDistance;
  final String travelDuration;
  final String selectedMode;
  final ValueChanged<String> onModeChanged;
  final List<RouteOption> routeOptions;
  final int selectedRouteIndex;
  final ValueChanged<int> onRouteSelected;
  final VoidCallback onCloseSheet;
  final String googleApiKey;

  const DirectionBottomSheet({
    super.key,
    required this.scrollController,
    required this.fromLocation,
    required this.toLocation,
    required this.toName,
    required this.travelDistance,
    required this.travelDuration,
    required this.selectedMode,
    required this.onModeChanged,
    required this.routeOptions,
    required this.selectedRouteIndex,
    required this.onRouteSelected,
    required this.onCloseSheet,
    required this.googleApiKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Center(
                    child: Text(
                      'Navigation',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: onCloseSheet,
                ),
              ],
            ),
            const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'Directions'),
                Tab(text: 'Nearby Me'),
                Tab(text: 'Nearby Destination'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  _buildDirectionsTab(context),
                  _buildNearbyTab(fromLocation, 'Nearby Me', scrollController),
                  _buildNearbyTab(
                    toLocation,
                    'Nearby Destination',
                    scrollController,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionsTab(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isPhone = screenWidth < 600;

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationRow(
                  context,
                  'From:',
                  Icons.my_location,
                  fromLocation != null ? 'Current Location' : '-',
                  isPhone: isPhone,
                ),
                const SizedBox(height: 16),
                _buildLocationRow(
                  context,
                  'To:',
                  Icons.location_on,
                  toName,
                  isPhone: isPhone,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ModeSelectorIcon(
                  icon: Icons.directions_car,
                  label: 'Car',
                  mode: 'driving',
                  selectedMode: selectedMode,
                  onModeChanged: onModeChanged,
                  isPhone: isPhone,
                ),
                if (!isPhone)
                  ModeSelectorIcon(
                    icon: Icons.directions_bike,
                    label: 'Bike',
                    mode: 'bicycling',
                    selectedMode: selectedMode,
                    onModeChanged: onModeChanged,
                    isPhone: isPhone,
                  ),
                ModeSelectorIcon(
                  icon: Icons.directions_walk,
                  label: 'Walk',
                  mode: 'walking',
                  selectedMode: selectedMode,
                  onModeChanged: onModeChanged,
                  isPhone: isPhone,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (travelDistance.isNotEmpty && travelDuration.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child:
                    isPhone
                        ? Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.center, // 👈 center in column
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: _buildInfoChip(
                                Icons.route,
                                'Distance: $travelDistance',
                                Colors.blue,
                                isPhone: isPhone,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.center,
                              child: _buildInfoChip(
                                Icons.timer,
                                'Duration: $travelDuration',
                                Colors.green,
                                isPhone: isPhone,
                              ),
                            ),
                          ],
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildInfoChip(
                              Icons.route,
                              'Distance: $travelDistance',
                              Colors.blue,
                              isPhone: isPhone,
                            ),
                            const SizedBox(width: 12),

                            _buildInfoChip(
                              Icons.timer,
                              'Duration: $travelDuration',
                              Colors.green,
                              isPhone: isPhone,
                            ),
                          ],
                        ),
              ),

            if (routeOptions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alternative Routes:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: isPhone ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: routeOptions.length,
                    itemBuilder: (context, index) {
                      final option = routeOptions[index];
                      final isSelected = selectedRouteIndex == index;

                      return GestureDetector(
                        onTap: () => onRouteSelected(index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.green.withOpacity(0.1)
                                    : Theme.of(
                                      context,
                                    ).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.green
                                      : Theme.of(context).dividerColor,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                option.isFastest
                                    ? Icons.flash_on
                                    : Icons.alt_route,
                                size: isPhone ? 18 : 24,
                                color:
                                    option.isFastest
                                        ? Colors.orange
                                        : Theme.of(context).iconTheme.color,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.summary,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.copyWith(
                                        fontSize: isPhone ? 13 : 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Duration: ${option.duration}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        fontSize: isPhone ? 12 : 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildNearbyTab(
    LatLng? location,
    String title,
    ScrollController controller,
  ) {
    if (location == null) {
      return const Center(child: Text("Location unavailable."));
    }
    return NearbyPlacesTab(
      title: title,
      location: location,
      googleApiKey: googleApiKey,
      controller: controller,
    );
  }

  Widget _buildLocationRow(
    BuildContext context,
    String label,
    IconData icon,
    String value, {
    required bool isPhone,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: isPhone ? 20 : 26,
          color: icon == Icons.my_location ? Colors.blue : Colors.red,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isPhone ? 12 : 14,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: isPhone ? 12 : 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    Color color, {
    required bool isPhone,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // 👈 This line is important!
        children: [
          Icon(icon, size: isPhone ? 16 : 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: isPhone ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
