import 'package:flutter/material.dart';
import 'api_client.dart';

class AdoptionScreen extends StatefulWidget {
  const AdoptionScreen({super.key, required this.api, required this.session});
  final ApiClient api;
  final Session session;
  @override
  State<AdoptionScreen> createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {
  late Future<List<List<Map<String, dynamic>>>> future = load();
  bool busy = false;
  bool get reviewer =>
      {'ngo_coordinator', 'system_admin'}.contains(widget.session.role);
  bool get publisher => reviewer || widget.session.role == 'rescue_volunteer';
  bool get applicant =>
      {'public_reporter', 'owner'}.contains(widget.session.role);
  Future<List<List<Map<String, dynamic>>>> load() => Future.wait([
        widget.api.getAdoption('listings'),
        widget.api.getAdoption('applications')
      ]);
  void refresh() {
    if (mounted) {
      setState(() {
        future = load();
      });
    }
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<String?> ask(String title, String label) async {
    final text = TextEditingController();
    final result = await showDialog<String>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: Text(title),
                content: TextField(
                    controller: text,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 2000,
                    decoration: InputDecoration(labelText: label)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        if (text.text.trim().length < 10) return;
                        Navigator.pop(dialog, text.text.trim());
                      },
                      child: const Text('Submit')),
                ]));
    text.dispose();
    return result;
  }

  Future<void> publish() async {
    await run(() async {
      final cases = (await widget.api.getCases())
          .where((c) =>
              {'rescued', 'closed'}.contains(c['status']) &&
              (reviewer || c['assigned_volunteer_id'] == widget.session.userId))
          .toList();
      if (!mounted) return;
      if (cases.isEmpty) {
        throw Exception(
            'Rescue an assigned animal first, then list it for adoption.');
      }
      String selected = cases.first['id'] as String;
      final name = TextEditingController();
      final description = TextEditingController();
      final form = GlobalKey<FormState>();
      final data = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (dialog) => AlertDialog(
                  title: const Text('A new beginning'),
                  content: SingleChildScrollView(
                      child: Form(
                          key: form,
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const Text(
                                'Publish only after the rescue team has confirmed the animal can be placed in a new home.'),
                            DropdownButtonFormField<String>(
                                initialValue: selected,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                    labelText: 'Rescued animal'),
                                items: cases
                                    .map((c) => DropdownMenuItem(
                                        value: c['id'] as String,
                                        child: Text(
                                            '${c['case_reference']} · ${c['species']}')))
                                    .toList(),
                                onChanged: (v) => selected = v!),
                            TextFormField(
                                controller: name,
                                maxLength: 120,
                                decoration: const InputDecoration(
                                    labelText: 'Animal name'),
                                validator: (v) => (v ?? '').trim().isEmpty
                                    ? 'Enter a name'
                                    : null),
                            TextFormField(
                                controller: description,
                                maxLines: 4,
                                maxLength: 2000,
                                decoration: const InputDecoration(
                                    labelText: 'Care needs and suitable home'),
                                validator: (v) => (v ?? '').trim().length < 10
                                    ? 'Add at least 10 characters'
                                    : null),
                          ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialog),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () {
                          if (form.currentState!.validate()) {
                            Navigator.pop(dialog, {
                              'case_id': selected,
                              'animal_name': name.text.trim(),
                              'description': description.text.trim()
                            });
                          }
                        },
                        child: const Text('Publish listing'))
                  ]));
      name.dispose();
      description.dispose();
      if (data != null) await widget.api.adoptionAction('listings', data);
    });
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
            title: const Text('Adoption & new beginnings'),
            actions: [
              IconButton(onPressed: refresh, icon: const Icon(Icons.refresh))
            ],
            bottom: TabBar(tabs: [
              const Tab(text: 'Find a companion'),
              Tab(text: reviewer ? 'Review applications' : 'My applications')
            ])),
        floatingActionButton: publisher
            ? FloatingActionButton.extended(
                onPressed: busy ? null : publish,
                icon: const Icon(Icons.add),
                label: const Text('List rescued animal'))
            : null,
        body: FutureBuilder<List<List<Map<String, dynamic>>>>(
            future: future,
            builder: (_, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Could not load adoptions: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final listings = snapshot.data![0];
              final applications = snapshot.data![1];
              final byId = {
                for (final listing in listings) listing['id']: listing
              };
              return TabBarView(children: [
                listings.isEmpty
                    ? const Center(
                        child: Text(
                            'Every new beginning starts with a rescue.\nNo animals are listed yet.',
                            textAlign: TextAlign.center))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        children: listings
                            .map((item) => Card(
                                child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.pets,
                                              size: 44,
                                              color: Color(0xFF087F73)),
                                          Text(
                                              '${item['animal_name']} · ${item['species']}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge),
                                          Chip(
                                              label: Text('${item['status']}')),
                                          Text(
                                              '${item['shelter_name']} · ${item['district']}'),
                                          const SizedBox(height: 8),
                                          Text('${item['description']}'),
                                          Text(
                                              'Rescue reference: ${item['case_reference']}'),
                                          if (applicant &&
                                              item['status'] == 'available')
                                            FilledButton(
                                                onPressed: busy
                                                    ? null
                                                    : () async {
                                                        final message = await ask(
                                                            'Apply to adopt ${item['animal_name']}',
                                                            'Tell the NGO about your home and care plan (10+ characters)');
                                                        if (message != null) {
                                                          await run(() => widget
                                                                  .api
                                                                  .adoptionAction(
                                                                      "listings/${item['id']}/applications",
                                                                      {
                                                                    'message':
                                                                        message
                                                                  }));
                                                        }
                                                      },
                                                child: const Text(
                                                    'Apply for adoption')),
                                          if (reviewer &&
                                              item['status'] == 'reserved')
                                            OutlinedButton(
                                                onPressed: busy
                                                    ? null
                                                    : () async {
                                                        final yes = await showDialog<
                                                                bool>(
                                                            context: context,
                                                            builder: (dialog) =>
                                                                AlertDialog(
                                                                    title: const Text(
                                                                        'Confirm adoption handover?'),
                                                                    content:
                                                                        const Text(
                                                                            'Confirm only after your team has completed its placement checks and handed the animal to the approved adopter.'),
                                                                    actions: [
                                                                      TextButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              dialog,
                                                                              false),
                                                                          child:
                                                                              const Text('Not yet')),
                                                                      FilledButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              dialog,
                                                                              true),
                                                                          child:
                                                                              const Text('Handover complete'))
                                                                    ]));
                                                        if (yes == true) {
                                                          await run(() => widget
                                                              .api
                                                              .adoptionAction(
                                                                  "listings/${item['id']}/complete",
                                                                  {}));
                                                        }
                                                      },
                                                child: const Text(
                                                    'Confirm handover')),
                                        ]))))
                            .toList()),
                applications.isEmpty
                    ? const Center(child: Text('No adoption applications yet.'))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        children: applications
                            .map((app) => Card(
                                child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '${byId[app['listing_id']]?['animal_name'] ?? 'Animal'} · ${app['status']}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium),
                                          Text(
                                              'Application ${app['id'].toString().substring(0, 8)}'),
                                          const SizedBox(height: 8),
                                          Text('${app['message']}'),
                                          if (app['review_note'] != null)
                                            Text(
                                                'NGO response: ${app['review_note']}'),
                                          if (reviewer &&
                                              app['status'] == 'pending')
                                            Wrap(
                                                spacing: 8,
                                                children: [
                                                  'approved',
                                                  'rejected'
                                                ]
                                                    .map((status) =>
                                                        OutlinedButton(
                                                            onPressed: busy
                                                                ? null
                                                                : () async {
                                                                    final note = await ask(
                                                                        status ==
                                                                                'approved'
                                                                            ? 'Approve application'
                                                                            : 'Decline application',
                                                                        'Decision note (10+ characters)');
                                                                    if (note !=
                                                                        null) {
                                                                      await run(() => widget.api.adoptionAction(
                                                                          "applications/${app['id']}",
                                                                          {
                                                                            'status':
                                                                                status,
                                                                            'review_note':
                                                                                note
                                                                          },
                                                                          patch:
                                                                              true));
                                                                    }
                                                                  },
                                                            child: Text(status ==
                                                                    'approved'
                                                                ? 'Approve'
                                                                : 'Decline')))
                                                    .toList()),
                                        ]))))
                            .toList()),
              ]);
            }),
      ));
}
