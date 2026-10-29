import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/property_model.dart';
import '../../../providers/property_provider.dart';
import '../../../services/map_service.dart';
import '../../../shared/widgets/amenity_chip.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  PropertyModel? _selectedPlot;
  String _selectedLocality = 'All';
  bool _isFullScreen = false;
  String _mapLayer = 'google_roadmap'; // 'google_roadmap', 'google_satellite', 'google_terrain', 'osm'

  String _getTileUrl() {
    switch (_mapLayer) {
      case 'google_satellite':
        return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case 'google_terrain':
        return 'https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
      case 'osm':
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case 'google_roadmap':
      default:
        return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
    }
  }

  // Transport Avatar Navigation States
  String _selectedTravelMode = 'driving'; // 'driving' (Car), 'bicycling' (Bike), 'transit' (Bus), 'walking' (Walk)
  final ll.LatLng _userLocation = const ll.LatLng(13.0067, 80.2025); // Guindy Hub, Chennai
  bool _isAvatarNavigating = false;
  bool _isNavPaused = false;
  bool _showNavigationMode = false;
  double _navProgress = 0.0;
  Timer? _avatarTimer;
  List<ll.LatLng> _routePoints = [];

  final List<String> _localities = [
    'All',
    'KK Nagar',
    'MGR Nagar',
    'Tambaram',
    'Velachery',
    'Porur',
    'OMR',
    'ECR',
    'Anna Nagar',
    'Medavakkam',
  ];

  @override
  void dispose() {
    _avatarTimer?.cancel();
    super.dispose();
  }

  // Generate realistic road curvature between user location and plot destination
  List<ll.LatLng> _generateRoutePoints(ll.LatLng start, ll.LatLng end) {
    final points = <ll.LatLng>[];
    const steps = 70;
    
    // Intermediate road deflection simulates Chennai arterial highway curves
    double midLat = (start.latitude + end.latitude) / 2;
    double midLng = (start.longitude + end.longitude) / 2;
    
    if (end.latitude > start.latitude) {
      midLat += 0.005;
      midLng -= 0.004;
    } else {
      midLat -= 0.006;
      midLng += 0.005;
    }

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = (1 - t) * (1 - t) * start.latitude + 2 * (1 - t) * t * midLat + t * t * end.latitude;
      final lng = (1 - t) * (1 - t) * start.longitude + 2 * (1 - t) * t * midLng + t * t * end.longitude;
      points.add(ll.LatLng(lat, lng));
    }
    return points;
  }

  void _startAvatarJourney(PropertyModel plot) {
    _avatarTimer?.cancel();
    _routePoints = _generateRoutePoints(_userLocation, ll.LatLng(plot.latitude, plot.longitude));
    _navProgress = 0.0;
    _isAvatarNavigating = true;
    _isNavPaused = false;

    // Center camera on midpoint
    final midLat = (_userLocation.latitude + plot.latitude) / 2;
    final midLng = (_userLocation.longitude + plot.longitude) / 2;
    _mapController.move(ll.LatLng(midLat, midLng), 13.0);

    final tickMs = _selectedTravelMode == 'driving'
        ? 80
        : (_selectedTravelMode == 'bicycling' ? 70 : (_selectedTravelMode == 'transit' ? 95 : 125));

    _avatarTimer = Timer.periodic(Duration(milliseconds: tickMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isNavPaused) return;

      setState(() {
        _navProgress += 1.0 / _routePoints.length;
        if (_navProgress >= 1.0) {
          _navProgress = 1.0;
          timer.cancel();
          _isAvatarNavigating = false;
          _showArrivalDialog(plot);
        } else {
          final index = (_navProgress * (_routePoints.length - 1)).round();
          if (index < _routePoints.length && index % 6 == 0) {
            _mapController.move(_routePoints[index], _mapController.camera.zoom);
          }
        }
      });
    });
  }

  void _pauseAvatarJourney() {
    setState(() {
      _isNavPaused = true;
    });
  }

  void _resumeAvatarJourney() {
    setState(() {
      _isNavPaused = false;
    });
  }

  void _restartAvatarJourney(PropertyModel plot) {
    _startAvatarJourney(plot);
  }

  void _stopAvatarJourney() {
    _avatarTimer?.cancel();
    setState(() {
      _isAvatarNavigating = false;
      _isNavPaused = false;
      _navProgress = 0.0;
      _routePoints.clear();
    });
  }

  void _showArrivalDialog(PropertyModel plot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.verifiedGreen, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Arrived at ${plot.plotNumber}!',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'You have reached the site entrance of ${plot.title} (${plot.locality}). Ready to inspect the demarcated boundary corners (${plot.dimensions}).',
          style: const TextStyle(fontSize: 12.5),
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/property/${plot.id}');
            },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('VIEW DETAILS'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/enquire/${plot.id}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlack,
              foregroundColor: Colors.white,
            ),
            child: const Text('ENQUIRE NOW'),
          ),
        ],
      ),
    );
  }

  void _filterLocality(String locality, List<PropertyModel> allPlots) {
    setState(() {
      _selectedLocality = locality;
      if (locality == 'All') {
        _mapController.move(const ll.LatLng(13.0150, 80.1900), 12.0);
      } else {
        final matches = allPlots
            .where((p) => p.locality.toLowerCase().contains(locality.toLowerCase()))
            .toList();
        if (matches.isNotEmpty) {
          _selectedPlot = matches.first;
          _mapController.move(
            ll.LatLng(matches.first.latitude, matches.first.longitude),
            14.5,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesFutureProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: const Text('Plots Discovery Map'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.layers_outlined),
                  tooltip: 'Map Layer (Google Maps)',
                  onSelected: (val) {
                    setState(() {
                      _mapLayer = val;
                    });
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'google_roadmap',
                      child: Row(
                        children: [
                          Icon(Icons.map, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Google Roadmap'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'google_satellite',
                      child: Row(
                        children: [
                          Icon(Icons.satellite_alt, size: 18, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Google Satellite'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'google_terrain',
                      child: Row(
                        children: [
                          Icon(Icons.terrain, size: 18, color: Colors.brown),
                          SizedBox(width: 8),
                          Text('Google Terrain'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'osm',
                      child: Row(
                        children: [
                          Icon(Icons.public, size: 18, color: Colors.black54),
                          SizedBox(width: 8),
                          Text('OpenStreetMap'),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  tooltip: 'Full Screen Map',
                  onPressed: () {
                    setState(() {
                      _isFullScreen = !_isFullScreen;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.my_location),
                  tooltip: 'Recenter to Central Chennai',
                  onPressed: () {
                    _mapController.move(const ll.LatLng(13.0150, 80.1900), 12.5);
                  },
                ),
              ],
            ),
      body: propertiesAsync.when(
        data: (plots) {
          // If no plot currently selected, select the first one
          _selectedPlot ??= plots.isNotEmpty ? plots.first : null;

          return Stack(
            children: [
              // 1. PURE ZERO-KEY INTERACTIVE GOOGLE MAPS (FLUTTER MAP)
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const ll.LatLng(13.0150, 80.1900),
                  initialZoom: 12.2,
                  minZoom: 8.0,
                  maxZoom: 20.0,
                ),
                children: [
                  // High performance Genuine Google Maps Raster Tiles
                  TileLayer(
                    key: ValueKey(_mapLayer),
                    urlTemplate: _getTileUrl(),
                    userAgentPackageName: 'com.llbrealestate.app',
                    maxZoom: 20,
                  ),

                  // Route Polyline Layer
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          color: AppColors.primaryBlack,
                          strokeWidth: 4.5,
                        ),
                      ],
                    ),

                  // Markers Layer
                  MarkerLayer(
                    markers: [
                      // User Live Location Marker (Guindy Hub)
                      Marker(
                        point: _userLocation,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withValues(alpha: 0.25),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue[700],
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Real Plot Markers
                      ...plots.map((plot) {
                        final isSelected = _selectedPlot?.id == plot.id;
                        Color pinColor = AppColors.verifiedGreen;
                        if (plot.isPlotReserved) pinColor = Colors.orange[800]!;
                        if (plot.isPlotSold) pinColor = Colors.grey[700]!;

                        final label = plot.plotNumber.isNotEmpty ? plot.plotNumber : plot.id;

                        return Marker(
                          point: ll.LatLng(plot.latitude, plot.longitude),
                          width: 88,
                          height: 32,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPlot = plot;
                              });
                              _mapController.move(
                                ll.LatLng(plot.latitude, plot.longitude),
                                _mapController.camera.zoom,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: pinColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.white,
                                  width: isSelected ? 2.5 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isSelected ? 0.45 : 0.25),
                                    blurRadius: isSelected ? 8 : 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.location_on, color: Colors.white, size: 12),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      // Traveling Avatar Marker
                      if (_isAvatarNavigating && _routePoints.isNotEmpty) ...[
                        () {
                          final idx = (_navProgress * (_routePoints.length - 1)).clamp(0, _routePoints.length - 1).round();
                          final pos = _routePoints[idx];

                          return Marker(
                            point: pos,
                            width: 48,
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.2),
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
                                  ],
                                ),
                                child: Icon(
                                  _getModeIcon(_selectedTravelMode),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          );
                        }(),
                      ],
                    ],
                  ),
                ],
              ),

              // 2. Top Filter Chips Bar
              if (!_isFullScreen && !_isAvatarNavigating)
                Positioned(
                  top: 10,
                  left: 12,
                  right: 12,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _localities.map((loc) {
                        final isSelected = _selectedLocality == loc;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: AmenityChip(
                            label: loc,
                            isSelected: isSelected,
                            onTap: () => _filterLocality(loc, plots),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // Floating Google Maps Badge & Quick Layer Toggle
              if (!_isAvatarNavigating)
                Positioned(
                  top: _isFullScreen ? 16 : 56,
                  right: 14,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setState(() {
                            if (_mapLayer == 'google_roadmap') {
                              _mapLayer = 'google_satellite';
                            } else if (_mapLayer == 'google_satellite') {
                              _mapLayer = 'google_terrain';
                            } else {
                              _mapLayer = 'google_roadmap';
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.explore, size: 15, color: Colors.blue),
                              const SizedBox(width: 5),
                              Text(
                                _mapLayer == 'google_roadmap'
                                    ? 'Google Map'
                                    : (_mapLayer == 'google_satellite' ? 'Google Satellite' : 'Google Terrain'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.swap_horiz, size: 13, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // 3. Top Navigation HUD when avatar journey is active
              if (_isAvatarNavigating && _selectedPlot != null)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: _buildNavigationTopHUD(_selectedPlot!),
                ),

              // 4. Interactive Bottom Card with 3 Action Buttons & Navigation Mode
              if (_selectedPlot != null)
                Positioned(
                  bottom: 14,
                  left: 12,
                  right: 12,
                  child: _buildPlotDetailsCard(_selectedPlot!),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlack),
        ),
        error: (err, _) => Center(
          child: Text('Could not load plots map: $err'),
        ),
      ),
    );
  }

  // Top Navigation HUD during trip
  Widget _buildNavigationTopHUD(PropertyModel plot) {
    final pct = (_navProgress * 100).round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(_getModeIcon(_selectedTravelMode), color: Colors.black, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getTravelModeTitle(_selectedTravelMode)} → ${plot.plotNumber}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _getInstructionText(_navProgress, plot),
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _stopAvatarJourney,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text('STOP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _navProgress,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.verifiedGreen),
            minHeight: 4,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Speed: ${_getSpeedText(_selectedTravelMode)}',
                style: const TextStyle(color: AppColors.verifiedGreen, fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
              Text('$pct% completed', style: const TextStyle(color: Colors.white70, fontSize: 9.5)),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'bicycling':
        return Icons.two_wheeler;
      case 'transit':
        return Icons.directions_bus;
      case 'walking':
        return Icons.directions_walk;
      default:
        return Icons.directions_car;
    }
  }

  String _getTravelModeTitle(String mode) {
    switch (mode) {
      case 'bicycling':
        return 'Bike Avatar';
      case 'transit':
        return 'Bus Avatar';
      case 'walking':
        return 'Walking Avatar';
      default:
        return 'Car Avatar';
    }
  }

  String _getSpeedText(String mode) {
    switch (mode) {
      case 'bicycling':
        return '38 km/h';
      case 'transit':
        return '26 km/h';
      case 'walking':
        return '5 km/h';
      default:
        return '45 km/h';
    }
  }

  String _getInstructionText(double ratio, PropertyModel plot) {
    if (ratio < 0.25) return 'Depart Guindy Hub onto Kathipara Grade Separator';
    if (ratio < 0.55) return 'Proceed along arterial highway towards ${plot.locality}';
    if (ratio < 0.85) return 'Turn right onto ${plot.projectName} link road';
    return 'Approaching ${plot.plotNumber} demarcated plot gate';
  }

  // Interactive Bottom Card with Transport Avatar Picker & Action Buttons
  Widget _buildPlotDetailsCard(PropertyModel plot) {
    final plotId = plot.plotNumber.isNotEmpty ? plot.plotNumber : plot.id;

    Color badgeBg = AppColors.verifiedGreen;
    if (plot.isPlotReserved) badgeBg = Colors.orange[800]!;
    if (plot.isPlotSold) badgeBg = Colors.grey[700]!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlack, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Thumbnail, ID, Title & Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: plot.images.isNotEmpty
                      ? Image.network(
                          plot.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.subtleGrey,
                            child: const Icon(Icons.landscape),
                          ),
                        )
                      : Container(color: AppColors.subtleGrey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            plot.availabilityLabel.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          plotId,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryBlack,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plot.title,
                      style: AppTypography.heading3.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      Formatters.formatCurrency(plot.price),
                      style: AppTypography.heading2.copyWith(fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${plot.locality} • ${plot.dimensions}',
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // IF NOT IN NAVIGATION MODE: SHOW THE 3 ACTION BUTTONS (VIEW DETAILS, NAVIGATE, ENQUIRE)
          if (!_showNavigationMode) ...[
            const Divider(height: 1, color: AppColors.dividerGrey),
            const SizedBox(height: 10),
            Row(
              children: [
                // 1. VIEW DETAILS
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/property/${plot.id}'),
                    icon: const Icon(Icons.info_outline, size: 14),
                    label: const Text('DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlack,
                      side: const BorderSide(color: AppColors.borderGrey, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      minimumSize: Size.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // 2. NAVIGATE TO THIS PLOT
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showNavigationMode = true;
                      });
                    },
                    icon: const Icon(Icons.directions, size: 14),
                    label: const Text(
                      'NAVIGATE TO THIS PLOT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlack,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      minimumSize: Size.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // 3. ENQUIRE ABOUT THIS PLOT
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/enquire/${plot.id}'),
                    icon: const Icon(Icons.mail_outline, size: 14),
                    label: const Text('ENQUIRE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlack,
                      side: const BorderSide(color: AppColors.primaryBlack, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      minimumSize: Size.zero,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // ================= NAVIGATION MODE (4 AVATARS + ROUTE CONTROL PANEL) =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlack,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'AVATAR MODE',
                        style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Route to ${plot.plotNumber} (${plot.locality})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _stopAvatarJourney();
                    setState(() {
                      _showNavigationMode = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 4 Selectable Travel Mode Cards
            Row(
              children: [
                _buildAvatarModeChip('driving', Icons.directions_car, 'Car 🚗', '~16m'),
                const SizedBox(width: 6),
                _buildAvatarModeChip('bicycling', Icons.two_wheeler, 'Bike 🏍️', '~11m'),
                const SizedBox(width: 6),
                _buildAvatarModeChip('transit', Icons.directions_bus, 'Bus 🚌', '~24m'),
                const SizedBox(width: 6),
                _buildAvatarModeChip('walking', Icons.directions_walk, 'Walk 🚶', '~1h'),
              ],
            ),
            const SizedBox(height: 8),

            // Distance & ETA Summary
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.subtleGrey,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Route Distance: ~5.2 km', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  Text(
                    'Est. Travel Time: ${_getSpeedEta(_selectedTravelMode)}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.verifiedGreen),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Route Control Panel: Start Preview, Pause, Resume, Restart
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _startAvatarJourney(plot),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlack,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Start Preview', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pauseAvatarJourney,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlack,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Pause', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resumeAvatarJourney,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlack,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Resume', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _restartAvatarJourney(plot),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlack,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Restart', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Open Navigation in Google Maps (External Turn-by-Turn GPS)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  MapService.openDirections(
                    latitude: plot.latitude,
                    longitude: plot.longitude,
                    title: plot.title,
                    plotId: plotId,
                    travelMode: _selectedTravelMode,
                  );
                },
                icon: const Icon(Icons.navigation, size: 14),
                label: const Text(
                  'OPEN NAVIGATION IN GOOGLE MAPS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlack,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  minimumSize: Size.zero,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Simulated route preview inside app. Tap button above for real Google Maps turn-by-turn directions.',
                style: TextStyle(fontSize: 8.5, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarModeChip(String mode, IconData icon, String label, String eta) {
    final isSelected = _selectedTravelMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTravelMode = mode;
          });
          if (_isAvatarNavigating && _selectedPlot != null) {
            _startAvatarJourney(_selectedPlot!);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlack : AppColors.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlack : AppColors.borderGrey,
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primaryBlack),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.primaryBlack,
                ),
              ),
              Text(
                eta,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white70 : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSpeedEta(String mode) {
    switch (mode) {
      case 'bicycling':
        return '11 mins';
      case 'transit':
        return '24 mins';
      case 'walking':
        return '1 hr 10 mins';
      default:
        return '16 mins';
    }
  }
}
