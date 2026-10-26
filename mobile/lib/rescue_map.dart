import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'api_client.dart';

Future<LatLng> locateAnimal() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw Exception(
        'Turn on location services or tap the map to place the paw.');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception('Location permission is unavailable. Tap the map instead.');
  }
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 20),
    ),
  );
  return LatLng(position.latitude, position.longitude);
}

class PawMap extends StatelessWidget {
  const PawMap({required this.points, this.onTap, this.controller, super.key});
  final List<Map<String, dynamic>> points;
  final ValueChanged<LatLng>? onTap;
  final MapController? controller;

  @override
  Widget build(BuildContext context) => FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: points.isEmpty
              ? const LatLng(33.6844, 73.0479)
              : LatLng((points.first['latitude'] as num).toDouble(),
                  (points.first['longitude'] as num).toDouble()),
          initialZoom: 12,
          onTap: (_, point) => onTap?.call(point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'pk.resqpet.ai',
          ),
          MarkerLayer(
            markers: points
                .map((item) => Marker(
                      point: LatLng((item['latitude'] as num).toDouble(),
                          (item['longitude'] as num).toDouble()),
                      width: 52,
                      height: 52,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                            backgroundColor: item['priority'] == 'critical'
                                ? const Color(0xFFF36F63)
                                : const Color(0xFF087F73)),
                        icon: const Icon(Icons.pets, color: Colors.white),
                        tooltip:
                            '${item['species'] ?? 'Animal'} · ${item['case_reference'] ?? 'Selected location'}',
                        onPressed: () {
                          if (item['case_reference'] == null) return;
                          showModalBottomSheet<void>(
                            context: context,
                            builder: (_) => Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${item['species']} · ${item['priority']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge),
                                    const SizedBox(height: 8),
                                    Text(
                                        '${item['case_reference']}\n${item['district']} · ${item['status']}'),
                                    const SizedBox(height: 12),
                                    const Text(
                                        'Keep a safe distance. Coordinate through the rescue team.'),
                                  ],
                                )),
                          );
                        },
                      ),
                    ))
                .toList(),
          ),
          const Align(
              alignment: Alignment.bottomRight,
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Text('© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 10))),
              )),
        ],
      );
}

class LocationPawPicker extends StatefulWidget {
  const LocationPawPicker({required this.onChanged, super.key});
  final ValueChanged<LatLng> onChanged;

  @override
  State<LocationPawPicker> createState() => _LocationPawPickerState();
}

class _LocationPawPickerState extends State<LocationPawPicker> {
  final controller = MapController();
  LatLng? point;
  bool locating = false;

  void select(LatLng next) {
    setState(() {
      point = next;
    });
    widget.onChanged(next);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.my_location),
          label: Text(
              locating ? 'Finding your location…' : 'Use my current location'),
          onPressed: locating
              ? null
              : () async {
                  setState(() {
                    locating = true;
                  });
                  try {
                    final next = await locateAnimal();
                    if (!mounted) return;
                    select(next);
                    controller.move(next, 16);
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('$error')));
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        locating = false;
                      });
                    }
                  }
                },
        ),
        const Text(
            'Tap where the animal is to place its paw marker. Your location is only shared when you submit.'),
        const SizedBox(height: 8),
        SizedBox(
            height: 250,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PawMap(controller: controller, onTap: select, points: [
                if (point != null)
                  {'latitude': point!.latitude, 'longitude': point!.longitude},
              ]),
            )),
        if (point != null)
          Text(
              'Paw placed: ${point!.latitude.toStringAsFixed(5)}, ${point!.longitude.toStringAsFixed(5)}'),
        const SizedBox(height: 12),
      ]);
}

class RescueMapScreen extends StatefulWidget {
  const RescueMapScreen({required this.api, super.key});
  final ApiClient api;
  @override
  State<RescueMapScreen> createState() => _RescueMapScreenState();
}

class _RescueMapScreenState extends State<RescueMapScreen> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  late Future<List<Map<String, dynamic>>> future = widget.api.getMapCases();
  void refresh() {
    setState(() {
      future = widget.api.getMapCases();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Rescue paw map'), actions: [
          IconButton(onPressed: refresh, icon: const Icon(Icons.refresh)),
        ]),
        body: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Could not load rescue paws: ${snapshot.error}'),
                  TextButton(
                      onPressed: refresh, child: const Text('Try again')),
                ]));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(children: [
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(snapshot.data!.isEmpty
                        ? 'No active reports have a paw location yet. Add a location to your next report.'
                        : '${snapshot.data!.length} active rescue paws · Updates every 15 seconds · Tap for details')),
                Expanded(child: PawMap(points: snapshot.data!)),
              ]);
            }),
      );
}
