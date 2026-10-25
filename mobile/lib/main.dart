import 'package:flutter/material.dart';

import 'api_client.dart';

void main() => runApp(const ResQPetApp());

class ResQPetApp extends StatelessWidget {
  const ResQPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF087F8C);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ResQ Pet AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F8F9),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
        ),
      ),
      home: LoginScreen(api: ApiClient()),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.api, super.key});
  final ApiClient api;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(text: 'coordinator@resqpet.demo');
  final password = TextEditingController(text: 'DemoCoordinator123!');
  bool loading = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final session = await widget.api.login(email.text, password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => HomeScreen(api: widget.api, session: session),
      ));
    } catch (exception) {
      setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset('assets/images/logo.png.png',
                            height: 92,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.pets, size: 72)),
                        const SizedBox(height: 12),
                        Text('ResQ Pet AI',
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center),
                        const Text('Rescue coordination for pets and livestock',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        TextField(
                            controller: email,
                            decoration:
                                const InputDecoration(labelText: 'Email')),
                        const SizedBox(height: 12),
                        TextField(
                            controller: password,
                            obscureText: true,
                            decoration:
                                const InputDecoration(labelText: 'Password')),
                        if (error != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(error!,
                                  style: const TextStyle(color: Colors.red))),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                            onPressed: loading ? null : submit,
                            icon: const Icon(Icons.login),
                            label: Text(loading ? 'Signing in…' : 'Sign in')),
                        const SizedBox(height: 10),
                        const Text(
                            'Demo accounts are created by the backend seed script.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12)),
                      ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.api, required this.session, super.key});
  final ApiClient api;
  final Session session;

  @override
  Widget build(BuildContext context) {
    final operational = {'ngo_coordinator', 'system_admin', 'rescue_volunteer'}
        .contains(session.role);
    return Scaffold(
      appBar: AppBar(title: const Text('ResQ Pet AI'), actions: [
        IconButton(
            onPressed: () async {
              await api.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => LoginScreen(api: api)));
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out'),
      ]),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Text('Assalam-o-Alaikum, ${session.fullName}',
            style: Theme.of(context).textTheme.headlineSmall),
        Text(_roleLabel(session.role),
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        _ActionCard(
            icon: Icons.sos,
            title: 'Report an animal emergency',
            subtitle: 'Create a structured rescue report for pets or livestock',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ReportScreen(api: api, session: session)))),
        if (operational)
          _ActionCard(
              icon: Icons.dashboard_customize,
              title: 'Rescue operations',
              subtitle: 'Verify, assign, accept, and update live cases',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CasesScreen(api: api, session: session)))),
        const _ActionCard(
            icon: Icons.medical_services_outlined,
            title: 'Veterinary consultation',
            subtitle: 'Coming after the P0 rescue workflow is stable'),
        const _ActionCard(
            icon: Icons.home_outlined,
            title: 'Responsible adoption',
            subtitle: 'Coming after the P0 rescue workflow is stable'),
      ]),
    );
  }
}

String _roleLabel(String role) => switch (role) {
      'ngo_coordinator' => 'NGO coordinator',
      'rescue_volunteer' => 'Rescue volunteer',
      'system_admin' => 'System administrator',
      'public_reporter' => 'Citizen reporter',
      _ => role.replaceAll('_', ' '),
    };

class _ActionCard extends StatelessWidget {
  const _ActionCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(child: Icon(icon)),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(subtitle),
            trailing: onTap == null
                ? const Icon(Icons.lock_clock)
                : const Icon(Icons.chevron_right),
            onTap: onTap),
      );
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({required this.api, required this.session, super.key});
  final ApiClient api;
  final Session session;
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final condition = TextEditingController();
  final district = TextEditingController(text: 'Islamabad');
  final village = TextEditingController();
  String species = 'dog',
      consciousness = 'conscious',
      bleeding = 'none',
      mobility = 'mobile',
      breathing = 'no',
      danger = 'none';
  bool loading = false;

  Future<void> submit() async {
    if (condition.text.trim().length < 3) return;
    setState(() => loading = true);
    try {
      final created = await widget.api.createCase({
        'organization_id': widget.session.organizationId,
        'species': species,
        'visible_condition': condition.text.trim(),
        'consciousness': consciousness,
        'bleeding': bleeding,
        'mobility': mobility,
        'breathing_difficulty': breathing,
        'surrounding_danger': danger,
        'district': district.text.trim(),
        'village': village.text.trim().isEmpty ? null : village.text.trim(),
      });
      if (!mounted) return;
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                  title: const Text('Rescue reported'),
                  content: Text(
                      '${created['case_reference']}\nPriority: ${created['priority']}\n${(created['priority_reasons'] as List).join(', ')}'),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('Done'))
                  ]));
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(exception.toString())));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Report rescue')),
        body: ListView(padding: const EdgeInsets.all(18), children: [
          _drop(
              'Animal type',
              species,
              [
                'dog',
                'cat',
                'cattle',
                'buffalo',
                'goat',
                'sheep',
                'poultry',
                'horse',
                'donkey',
                'other'
              ],
              (v) => setState(() => species = v)),
          TextField(
              controller: condition,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'What happened? *')),
          const SizedBox(height: 12),
          _drop(
              'Consciousness',
              consciousness,
              ['conscious', 'unconscious', 'unsure'],
              (v) => setState(() => consciousness = v)),
          _drop('Bleeding', bleeding, ['none', 'minor', 'severe'],
              (v) => setState(() => bleeding = v)),
          _drop(
              'Mobility',
              mobility,
              ['mobile', 'limping', 'immobile', 'unsure'],
              (v) => setState(() => mobility = v)),
          _drop('Breathing difficulty', breathing, ['no', 'yes', 'unsure'],
              (v) => setState(() => breathing = v)),
          _drop(
              'Surrounding danger',
              danger,
              [
                'none',
                'traffic',
                'fire',
                'water',
                'electrical',
                'violence',
                'other'
              ],
              (v) => setState(() => danger = v)),
          TextField(
              controller: district,
              decoration: const InputDecoration(labelText: 'District *')),
          const SizedBox(height: 12),
          TextField(
              controller: village,
              decoration: const InputDecoration(labelText: 'Village or area')),
          const SizedBox(height: 18),
          FilledButton.icon(
              onPressed: loading ? null : submit,
              icon: const Icon(Icons.send),
              label: Text(loading ? 'Submitting…' : 'Submit rescue report')),
        ]),
      );

  Widget _drop(String label, String value, List<String> values,
          ValueChanged<String> change) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(labelText: label),
            items: values
                .map((v) => DropdownMenuItem(
                    value: v, child: Text(v.replaceAll('_', ' '))))
                .toList(),
            onChanged: (v) {
              if (v != null) change(v);
            }),
      );
}

class CasesScreen extends StatefulWidget {
  const CasesScreen({required this.api, required this.session, super.key});
  final ApiClient api;
  final Session session;
  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  late Future<List<Map<String, dynamic>>> future = widget.api.getCases();
  void refresh() => setState(() => future = widget.api.getCases());

  Future<void> act(Map<String, dynamic> item) async {
    try {
      if (widget.session.role == 'ngo_coordinator' ||
          widget.session.role == 'system_admin') {
        if (item['status'] == 'reported') {
          await widget.api.verifyCase(item['id'] as String);
        } else if (item['status'] == 'verified') {
          final volunteers = await widget.api.getVolunteers();
          if (!mounted || volunteers.isEmpty) {
            throw ApiException('No volunteer is available', 422);
          }
          await widget.api.assignCase(
              item['id'] as String, volunteers.first['id'] as String);
        }
      } else if (widget.session.role == 'rescue_volunteer') {
        final next = {
          'assigned': 'accepted',
          'accepted': 'en_route',
          'en_route': 'on_scene',
          'on_scene': 'rescued',
          'rescued': 'closed'
        }[item['status']];
        if (next != null) {
          await widget.api
              .updateStatus(item['id'] as String, next, item['version'] as int);
        }
      }
      refresh();
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(exception.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Rescue operations'), actions: [
          IconButton(onPressed: refresh, icon: const Icon(Icons.refresh))
        ]),
        body: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }
              final cases = snapshot.data ?? [];
              if (cases.isEmpty) {
                return const Center(child: Text('No rescue cases yet'));
              }
              return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cases.length,
                  itemBuilder: (_, index) {
                    final item = cases[index];
                    final actionable =
                        (widget.session.role == 'ngo_coordinator' &&
                                ['reported', 'verified']
                                    .contains(item['status'])) ||
                            (widget.session.role == 'system_admin' &&
                                ['reported', 'verified']
                                    .contains(item['status'])) ||
                            (widget.session.role == 'rescue_volunteer' &&
                                item['assigned_volunteer_id'] ==
                                    widget.session.userId &&
                                [
                                  'assigned',
                                  'accepted',
                                  'en_route',
                                  'on_scene',
                                  'rescued'
                                ].contains(item['status']));
                    return Card(
                        child: ListTile(
                      leading: CircleAvatar(
                          child: Text(
                              (item['priority'] as String)[0].toUpperCase())),
                      title: Text(
                          '${item['case_reference']} • ${item['species']}'),
                      subtitle: Text(
                          '${item['district']}\n${item['status']} • ${item['priority']}'),
                      isThreeLine: true,
                      trailing: actionable
                          ? FilledButton(
                              onPressed: () => act(item),
                              child: Text(item['status'] == 'reported'
                                  ? 'Verify'
                                  : item['status'] == 'verified'
                                      ? 'Assign'
                                      : 'Next'))
                          : null,
                    ));
                  });
            }),
      );
}
