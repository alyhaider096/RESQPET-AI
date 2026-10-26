import 'package:flutter/material.dart';
import 'api_client.dart';

class CareScreen extends StatefulWidget {
  const CareScreen({required this.api, required this.session, super.key});
  final ApiClient api;
  final Session session;
  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  late Future<List<Map<String, dynamic>>> future =
      widget.api.getCare('consultations');
  bool busy = false;
  void refresh() {
    if (mounted) {
      setState(() {
        future = widget.api.getCare('consultations');
      });
    }
  }

  Future<void> request() async {
    try {
      final vets = await widget.api.getCare('veterinarians');
      if (!mounted) return;
      if (vets.isEmpty) {
        throw Exception(
            'No veterinarian is available in this organization yet.');
      }
      final result = await showDialog<Map<String, dynamic>>(
          context: context, builder: (_) => ConsultationForm(vets: vets));
      if (result == null) return;
      setState(() {
        busy = true;
      });
      await widget.api.requestConsultation(result);
      refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Future<void> update(Map<String, dynamic> item) async {
    try {
      final data = <String, dynamic>{};
      if (item['status'] == 'requested') {
        final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 90)));
        if (date == null || !mounted) return;
        final time = await showTimePicker(
            context: context, initialTime: TimeOfDay.now());
        if (time == null || !mounted) return;
        data['status'] = 'scheduled';
        data['appointment_at'] =
            DateTime(date.year, date.month, date.day, time.hour, time.minute)
                .toUtc()
                .toIso8601String();
      } else {
        final note = TextEditingController();
        final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text('Complete consultation'),
                  content: TextField(
                      controller: note,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                          labelText: 'Veterinarian follow-up note')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Complete'))
                  ],
                ));
        if (confirmed != true) {
          note.dispose();
          return;
        }
        data['status'] = 'completed';
        data['vet_note'] = note.text.trim();
        note.dispose();
      }
      await widget.api.updateConsultation(item['id'] as String, data);
      refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Vet & animal care'), actions: [
          IconButton(onPressed: refresh, icon: const Icon(Icons.refresh))
        ]),
        floatingActionButton: {'owner', 'public_reporter', 'ngo_coordinator'}
                .contains(widget.session.role)
            ? FloatingActionButton.extended(
                onPressed: busy ? null : request,
                icon: const Icon(Icons.medical_services_outlined),
                label: const Text('Ask a veterinarian'))
            : null,
        body: Column(children: [
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                  'Care for pets and farm animals: general health, vaccination, heat cycles and reproductive concerns. Requests are reviewed by a veterinarian. This demo does not provide automated diagnoses or medication advice.')),
          Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No consultation requests yet.'));
                    }
                    return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        children: snapshot.data!
                            .map((item) => Card(
                                  child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                '${item['animal_name']} · ${item['species']}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge),
                                            Text('${item['concern']}'
                                                .replaceAll('_', ' ')),
                                            const SizedBox(height: 8),
                                            Text('${item['description']}'),
                                            const SizedBox(height: 8),
                                            Text('Status: ${item['status']}'),
                                            if (item['appointment_at'] != null)
                                              Text(
                                                  'Appointment: ${DateTime.parse(item['appointment_at'] as String).toLocal()}'),
                                            if (item['vet_note'] != null)
                                              Text(
                                                  'Veterinarian note: ${item['vet_note']}'),
                                            if (widget.session.role ==
                                                    'veterinarian' &&
                                                item['status'] != 'completed')
                                              FilledButton(
                                                  onPressed: () => update(item),
                                                  child: Text(item['status'] ==
                                                          'requested'
                                                      ? 'Schedule appointment'
                                                      : 'Complete consultation')),
                                          ])),
                                ))
                            .toList());
                  })),
        ]),
      );
}

class ConsultationForm extends StatefulWidget {
  const ConsultationForm({required this.vets, super.key});
  final List<Map<String, dynamic>> vets;
  @override
  State<ConsultationForm> createState() => _ConsultationFormState();
}

class _ConsultationFormState extends State<ConsultationForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final description = TextEditingController();
  String species = 'cat';
  String concern = 'general_health';
  late String vetId = widget.vets.first['id'] as String;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Request animal care'),
        content: SingleChildScrollView(
            child: Form(
                key: form,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                      controller: name,
                      maxLength: 120,
                      decoration: const InputDecoration(
                          labelText: 'Animal name / herd reference'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter an animal name or herd reference'
                          : null),
                  DropdownButtonFormField<String>(
                      initialValue: species,
                      decoration: const InputDecoration(labelText: 'Animal'),
                      items: [
                        'cat',
                        'dog',
                        'cattle',
                        'buffalo',
                        'goat',
                        'sheep',
                        'poultry',
                        'horse',
                        'donkey',
                        'other'
                      ]
                          .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            species = v;
                          });
                        }
                      }),
                  DropdownButtonFormField<String>(
                      initialValue: concern,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Care topic'),
                      items: [
                        'general_health',
                        'heat_cycle',
                        'reproductive_health',
                        'vaccination'
                      ]
                          .map((v) => DropdownMenuItem(
                              value: v, child: Text(v.replaceAll('_', ' '))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            concern = v;
                          });
                        }
                      }),
                  DropdownButtonFormField<String>(
                      initialValue: vetId,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Veterinarian'),
                      items: widget.vets
                          .map((v) => DropdownMenuItem(
                              value: v['id'] as String,
                              child: Text(v['full_name'] as String)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            vetId = v;
                          });
                        }
                      }),
                  TextFormField(
                      controller: description,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                          labelText:
                              'Describe the concern and when it started'),
                      validator: (v) => (v?.trim().length ?? 0) < 5
                          ? 'Please add more detail'
                          : null),
                ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (!form.currentState!.validate()) return;
                Navigator.pop(context, {
                  'veterinarian_id': vetId,
                  'species': species,
                  'animal_name': name.text.trim(),
                  'concern': concern,
                  'description': description.text.trim()
                });
              },
              child: const Text('Request consultation'))
        ],
      );
}
