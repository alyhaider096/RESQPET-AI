import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'api_client.dart';
import 'rescue_map.dart';
import 'main.dart' show humanize, PriorityBadge, withRescueBuddy;

class CaseDetailScreen extends StatefulWidget {
  const CaseDetailScreen(
      {super.key,
      required this.api,
      required this.session,
      required this.initial,
      this.review = false});
  final ApiClient api;
  final Session session;
  final Map<String, dynamic> initial;
  final bool review;
  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  late Map<String, dynamic> item = Map.of(widget.initial);
  late final Future<Uint8List>? photo = (item['photo_count'] as num? ?? 0) > 0
      ? widget.api.getPhoto(item['id'] as String)
      : null;
  late final Future<List<Map<String, dynamic>>> volunteers =
      item['status'] == 'verified' && coordinator
          ? widget.api.getVolunteers()
          : Future.value([]);
  String? volunteerId;
  bool busy = false;
  bool get coordinator =>
      {'ngo_coordinator', 'system_admin'}.contains(widget.session.role);

  Future<void> confirm() async {
    if (item['status'] == 'verified' && volunteerId == null) return;
    setState(() => busy = true);
    try {
      await withRescueBuddy<void>(context,
          message: item['status'] == 'reported'
              ? 'Checking every paw print…'
              : 'Sending the rescue handoff…',
          animal: '🐕', action: () async {
        if (item['status'] == 'reported') {
          await widget.api.verifyCase(item['id'] as String);
        } else {
          await widget.api.assignCase(item['id'] as String, volunteerId!);
        }
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> placeLocation() async {
    LatLng? point;
    final save = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (sheet) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Confirm the animal’s location',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text(
                      'Use the caller’s directions. Tap the animal’s actual location; your own GPS may be elsewhere.'),
                  LocationPawPicker(onChanged: (value) => point = value),
                  FilledButton(
                      onPressed: () {
                        if (point == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Tap a location on the map first.')));
                          return;
                        }
                        Navigator.pop(sheet, true);
                      },
                      child: const Text('Save rescue paw location')),
                ]))));
    if (save != true || point == null) return;
    try {
      await widget.api.setCaseLocation(
          item['id'] as String, point!.latitude, point!.longitude);
      final updated = await widget.api.getCase(item['id'] as String);
      if (mounted) setState(() => item = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assign = item['status'] == 'verified';
    final hasPoint = item['latitude'] != null && item['longitude'] != null;
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.review
              ? (assign ? 'Assign rescue team' : 'Review rescue report')
              : 'Animal case details')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('${item['case_reference']}',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Row(children: [
          PriorityBadge(priority: item['priority'] as String),
          const SizedBox(width: 12),
          Text(humanize(item['status'] as String))
        ]),
        const SizedBox(height: 16),
        if (photo != null)
          FutureBuilder<Uint8List>(
              future: photo,
              builder: (_, snapshot) => snapshot.hasData
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(snapshot.data!,
                          height: 260, fit: BoxFit.cover))
                  : Text(snapshot.hasError
                      ? 'Photo could not be loaded.'
                      : 'Fetching the rescue photo…'))
        else
          const Card(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(children: [
                    Icon(Icons.pets, size: 48),
                    Text('No photo attached to this report')
                  ]))),
        const SizedBox(height: 16),
        Text(humanize(item['species'] as String),
            style: Theme.of(context).textTheme.titleLarge),
        Text('${item['visible_condition']}'),
        const SizedBox(height: 16),
        for (final field in [
          'consciousness',
          'bleeding',
          'mobility',
          'breathing_difficulty',
          'surrounding_danger'
        ])
          ListTile(
              dense: true,
              title: Text(humanize(field)),
              trailing: Text(humanize('${item[field] ?? 'unsure'}'))),
        if ((item['priority_reasons'] as List? ?? []).isNotEmpty)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                      'Priority reasons: ${(item['priority_reasons'] as List).join(', ')}'))),
        const SizedBox(height: 16),
        Text('Rescue location', style: Theme.of(context).textTheme.titleLarge),
        Text([item['village'], item['district'], item['landmark']]
            .where((v) => v != null && '$v'.isNotEmpty)
            .join(' · ')),
        if (hasPoint)
          SizedBox(height: 250, child: PawMap(points: [item]))
        else
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                  'Area reported; GPS location has not been confirmed. This case has no paw marker yet.')),
        if (coordinator)
          OutlinedButton.icon(
              onPressed: busy ? null : placeLocation,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(hasPoint
                  ? 'Update rescue location'
                  : 'Place this animal on the map')),
        if (widget.review && coordinator) ...[
          const Divider(height: 36),
          if (assign)
            FutureBuilder<List<Map<String, dynamic>>>(
                future: volunteers,
                builder: (_, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                        'Could not load volunteers. Reopen this screen to try again.');
                  }
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  if (snapshot.data!.isEmpty) {
                    return const Text(
                        'No active volunteer is available in this organization.');
                  }
                  return DropdownButtonFormField<String>(
                      initialValue: volunteerId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Choose a rescue volunteer'),
                      items: snapshot.data!
                          .map((v) => DropdownMenuItem(
                              value: v['id'] as String,
                              child: Text(v['full_name'] as String)))
                          .toList(),
                      onChanged: busy
                          ? null
                          : (value) => setState(() => volunteerId = value));
                })
          else
            const Text(
                'Confirm the report’s condition, priority and location before marking it verified.'),
          const SizedBox(height: 18),
          FilledButton.icon(
              onPressed:
                  busy || (assign && volunteerId == null) ? null : confirm,
              icon: Icon(
                  assign ? Icons.group_add_outlined : Icons.verified_outlined),
              label:
                  Text(assign ? 'Confirm assignment' : 'Confirm verification')),
        ],
        if ((item['events'] as List? ?? []).isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('Case history', style: Theme.of(context).textTheme.titleLarge),
          for (final event in item['events'] as List)
            ListTile(
                leading: const Icon(Icons.history),
                title: Text(
                    humanize('${event['event_type']}'.replaceAll('.', ' '))),
                subtitle:
                    Text('${event['reason'] ?? event['new_value'] ?? ''}')),
        ],
      ]),
    );
  }
}
