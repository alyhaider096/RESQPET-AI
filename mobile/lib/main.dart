import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'care_screen.dart';
import 'rescue_map.dart';

const ink = Color(0xFF18263B);
const rescueGreen = Color(0xFF16B89D);
const deepGreen = Color(0xFF087F73);
const warmBeige = Color(0xFFF6EEDC);
const warmSurface = Color(0xFFFFFCF5);
const rescueCoral = Color(0xFFF36F63);
const softSky = Color(0xFF69BFEA);

void main() => runApp(const ResQPetApp());

class ResQPetApp extends StatelessWidget {
  const ResQPetApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ResQPet AI',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.light(
            primary: rescueGreen,
            onPrimary: Colors.white,
            primaryContainer: Color(0xFFD9F5EC),
            onPrimaryContainer: deepGreen,
            secondary: rescueCoral,
            onSecondary: Colors.white,
            secondaryContainer: Color(0xFFFFE5DF),
            onSecondaryContainer: ink,
            tertiary: softSky,
            surface: warmSurface,
            onSurface: ink,
            outline: Color(0xFFD8CFBD),
          ),
          scaffoldBackgroundColor: warmBeige,
          textTheme: ThemeData.light().textTheme.apply(
                bodyColor: ink,
                displayColor: ink,
              ),
          appBarTheme: const AppBarTheme(
            backgroundColor: warmBeige,
            foregroundColor: ink,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: warmSurface,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0x1F18263B)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: warmSurface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0x1F18263B)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: deepGreen, width: 2),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: rescueGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 54),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: warmSurface,
            indicatorColor: Color(0xFFD9F5EC),
            labelTextStyle: WidgetStatePropertyAll(
              TextStyle(color: ink, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        home: SplashScreen(api: ApiClient()),
      );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.api, super.key});
  final ApiClient api;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: LoginScreen(api: widget.api),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: DoodleBackground()),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: controller,
                    builder: (_, child) => Transform.scale(
                      scale: 0.98 + controller.value * 0.035,
                      child: child,
                    ),
                    child: Container(
                      width: 210,
                      height: 210,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: warmSurface,
                        borderRadius: BorderRadius.circular(52),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2618263B),
                            blurRadius: 35,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(42),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'ResQPet AI',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rescue • Care • Rehome',
                    style: TextStyle(
                      color: deepGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class DoodleBackground extends StatefulWidget {
  const DoodleBackground({super.key});

  @override
  State<DoodleBackground> createState() => _DoodleBackgroundState();
}

class _DoodleBackgroundState extends State<DoodleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, __) => Stack(
            children: [
              doodle('🐾', 22, 80, rescueCoral, 0),
              doodle('♡', 310, 110, rescueGreen, 1.4),
              doodle('✦', 42, 650, softSky, 2.7),
              doodle('🐾', 300, 690, rescueGreen, 4.1),
            ],
          ),
        ),
      );

  Widget doodle(
    String value,
    double left,
    double top,
    Color color,
    double phase,
  ) {
    final float = math.sin(animation.value * math.pi * 2 + phase) * 7;
    return Positioned(
      left: left,
      top: top + float,
      child: Transform.rotate(
        angle: math.sin(animation.value * math.pi * 2 + phase) * 0.08,
        child: Text(
          value,
          style: TextStyle(
            color: color.withValues(alpha: 0.34),
            fontSize: value == '🐾' ? 28 : 38,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
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
  bool hidePassword = true;
  String? error;

  @override
  void initState() {
    super.initState();
    widget.api.restoreBackendUrl().catchError((Object _) {});
  }

  Future<void> configureBackend() async {
    final address = TextEditingController(text: widget.api.backendUrl);
    final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Demo server connection'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text(
                    'Use the HTTPS address supplied by your demo operator. Only use a server you trust; login details are sent there.'),
                const SizedBox(height: 12),
                TextField(
                    controller: address,
                    decoration:
                        const InputDecoration(labelText: 'Backend HTTPS URL')),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, address.text),
                    child: const Text('Save'))
              ],
            ));
    address.dispose();
    if (result == null) return;
    try {
      await widget.api.setBackendUrl(result);
    } catch (exception) {
      if (mounted) {
        setState(() {
          error = exception.toString();
        });
      }
    }
  }

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final session = await withRescueBuddy(
        context,
        message: 'Checking your rescue badge…',
        animal: '🐕',
        action: () => widget.api.login(email.text, password.text),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(api: widget.api, session: session),
        ),
      );
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: DoodleBackground()),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      children: [
                        Image.asset('assets/images/logo.png.png', height: 82),
                        const SizedBox(height: 10),
                        const Text(
                          'Welcome to ResQPet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Pakistan’s rescue network for pets, livestock and working animals.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF617083),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Sign in to help',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: email,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email address',
                                    prefixIcon:
                                        Icon(Icons.alternate_email_rounded),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: password,
                                  obscureText: hidePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => hidePassword = !hidePassword,
                                      ),
                                      icon: Icon(
                                        hidePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                                if (error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      error!,
                                      style: const TextStyle(
                                        color: Color(0xFFBA1A1A),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 18),
                                FilledButton.icon(
                                  onPressed: loading ? null : submit,
                                  icon: const Icon(Icons.pets_rounded),
                                  label: const Text('Continue'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const AnimalStrip(),
                        TextButton.icon(
                            onPressed: configureBackend,
                            icon: const Icon(Icons.settings_ethernet),
                            label: const Text('Demo server connection')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.api, required this.session, super.key});
  final ApiClient api;
  final Session session;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  final casesKey = GlobalKey<_CasesPanelState>();

  Future<void> openReport() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportScreen(
          api: widget.api,
          session: widget.session,
        ),
      ),
    );
    if (mounted) await casesKey.currentState?.refresh();
  }

  void selectDestination(int value) {
    setState(() => index = value);
    if (value == 1) casesKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Home', casesLabel(widget.session.role), 'Profile'];
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Vet and animal care',
            icon: const Icon(Icons.medical_services_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  CareScreen(api: widget.api, session: widget.session),
            )),
          ),
          IconButton(
            tooltip: 'Rescue paw map',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RescueMapScreen(api: widget.api),
            )),
          )
        ],
        title: Row(
          children: [
            Image.asset('assets/images/logo.png.png', width: 38, height: 38),
            const SizedBox(width: 10),
            Text(
              titles[index],
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: index,
        children: [
          DashboardTab(
            session: widget.session,
            onReport: openReport,
            onCases: () => selectDestination(1),
          ),
          CasesPanel(
            key: casesKey,
            api: widget.api,
            session: widget.session,
          ),
          ProfileTab(
            session: widget.session,
            onLogout: () async {
              await widget.api.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => LoginScreen(api: widget.api),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openReport,
        backgroundColor: rescueCoral,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.sos_rounded),
        label: const Text(
          'Report rescue',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: selectDestination,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment_rounded),
            label: casesLabel(widget.session.role),
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

String casesLabel(String role) =>
    role == 'public_reporter' ? 'My reports' : 'Cases';

class DashboardTab extends StatelessWidget {
  const DashboardTab({
    required this.session,
    required this.onReport,
    required this.onCases,
    super.key,
  });
  final Session session;
  final VoidCallback onReport;
  final VoidCallback onCases;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          Text(
            'Assalam-o-Alaikum,',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF617083),
                ),
          ),
          Text(
            session.fullName,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          HeroCard(onReport: onReport),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: StatCard(
                  value: '10+',
                  label: 'Animal types',
                  color: rescueGreen,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  value: '3',
                  label: 'Priority levels',
                  color: rescueCoral,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  value: 'Live',
                  label: 'Case updates',
                  color: softSky,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'How can you help?',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          FeatureCard(
            icon: Icons.sos_rounded,
            color: rescueCoral,
            title: 'Report an emergency',
            subtitle: 'Share the condition and exact area in a guided report.',
            onTap: onReport,
          ),
          const SizedBox(height: 12),
          FeatureCard(
            icon: Icons.route_rounded,
            color: rescueGreen,
            title: casesLabel(session.role),
            subtitle: session.role == 'public_reporter'
                ? 'Follow the progress of animals you reported.'
                : 'Verify, assign and move active rescues forward.',
            onTap: onCases,
          ),
          const SizedBox(height: 12),
          const ComingSoonCard(),
          const SizedBox(height: 20),
          const AnimalStrip(),
        ],
      );
}

class HeroCard extends StatelessWidget {
  const HeroCard({required this.onReport, super.key});
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2B18263B),
              blurRadius: 24,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -6,
              top: -16,
              child: Text('🐾', style: TextStyle(fontSize: 78)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: rescueGreen.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'RESCUE NETWORK ACTIVE',
                    style: TextStyle(
                      color: Color(0xFF76E9D5),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Every animal deserves a quick response.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Pets, livestock and working animals—all in one rescue system.',
                  style: TextStyle(color: Color(0xFFD7DFEA), height: 1.4),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onReport,
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text('Start a rescue report'),
                ),
              ],
            ),
          ],
        ),
      );
}

class StatCard extends StatelessWidget {
  const StatCard({
    required this.value,
    required this.label,
    required this.color,
    super.key,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: warmSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFF617083)),
            ),
          ],
        ),
      );
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF617083),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: deepGreen,
                ),
              ],
            ),
          ),
        ),
      );
}

class ComingSoonCard extends StatelessWidget {
  const ComingSoonCard({super.key});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: rescueCoral),
                  SizedBox(width: 9),
                  Text(
                    'Next for ResQPet',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  RoadmapChip(
                    icon: Icons.medical_services_outlined,
                    label: 'Vet consults',
                  ),
                  RoadmapChip(icon: Icons.home_outlined, label: 'Adoption'),
                  RoadmapChip(
                    icon: Icons.pets_outlined,
                    label: 'Pet profiles',
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class RoadmapChip extends StatelessWidget {
  const RoadmapChip({required this.icon, required this.label, super.key});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: warmBeige,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: deepGreen),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class AnimalStrip extends StatelessWidget {
  const AnimalStrip({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8DE),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('🐕', style: TextStyle(fontSize: 25)),
            Text('🐈', style: TextStyle(fontSize: 25)),
            Text('🐃', style: TextStyle(fontSize: 25)),
            Text('🐐', style: TextStyle(fontSize: 25)),
            Text('🐓', style: TextStyle(fontSize: 25)),
            Text('🐴', style: TextStyle(fontSize: 25)),
          ],
        ),
      );
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({
    required this.session,
    required this.onLogout,
    super.key,
  });
  final Session session;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: const Color(0xFFD9F5EC),
                    child: Text(
                      session.fullName.isEmpty
                          ? '?'
                          : session.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        color: deepGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    session.fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    session.email,
                    style: const TextStyle(color: Color(0xFF617083)),
                  ),
                  const SizedBox(height: 12),
                  Chip(
                    avatar: const Icon(
                      Icons.verified_user_outlined,
                      size: 18,
                      color: deepGreen,
                    ),
                    label: Text(roleLabel(session.role)),
                    backgroundColor: const Color(0xFFD9F5EC),
                    side: BorderSide.none,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.shield_outlined, color: deepGreen),
                  title: Text(
                    'Privacy first',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle:
                      Text('Contact details stay encrypted in the backend.'),
                ),
                const Divider(height: 1),
                ListTile(
                  onTap: onLogout,
                  leading: const Icon(Icons.logout_rounded, color: rescueCoral),
                  title: const Text(
                    'Sign out',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const AnimalStrip(),
        ],
      );
}

String roleLabel(String role) => switch (role) {
      'ngo_coordinator' => 'NGO coordinator',
      'rescue_volunteer' => 'Rescue volunteer',
      'system_admin' => 'System administrator',
      'public_reporter' => 'Citizen reporter',
      _ => role.replaceAll('_', ' '),
    };

class ReportScreen extends StatefulWidget {
  const ReportScreen({required this.api, required this.session, super.key});
  final ApiClient api;
  final Session session;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final formKey = GlobalKey<FormState>();
  final condition = TextEditingController();
  final district = TextEditingController(text: 'Islamabad');
  final village = TextEditingController();
  final landmark = TextEditingController();
  String species = 'dog';
  String consciousness = 'conscious';
  String bleeding = 'none';
  String mobility = 'mobile';
  String breathing = 'no';
  String danger = 'none';
  bool loading = false;
  double? animalLatitude;
  double? animalLongitude;
  Uint8List? animalPhoto;
  String? photoWarning;

  Future<void> pickPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: source, maxWidth: 1280, imageQuality: 75);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('Choose a photo smaller than 5 MB.');
      }
      if (mounted) {
        setState(() {
          animalPhoto = bytes;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => loading = true);
    try {
      final created = await withRescueBuddy(
        context,
        message: 'Calling the rescue pack…',
        animal: species == 'cat' ? '🐈' : '🐕',
        action: () async {
          final item = await widget.api.createCase({
            'organization_id': widget.session.organizationId,
            'species': species,
            'visible_condition': condition.text.trim(),
            'consciousness': consciousness,
            'bleeding': bleeding,
            'mobility': mobility,
            'breathing_difficulty': breathing,
            'surrounding_danger': danger,
            'district': district.text.trim(),
            'latitude': animalLatitude,
            'longitude': animalLongitude,
            'village': village.text.trim().isEmpty ? null : village.text.trim(),
            'landmark':
                landmark.text.trim().isEmpty ? null : landmark.text.trim(),
          });
          if (animalPhoto != null) {
            try {
              await widget.api.uploadPhoto(item['id'] as String, animalPhoto!);
            } catch (_) {
              photoWarning =
                  'Your report was saved, but its photo could not upload. Please contact the coordinator with your case reference.';
            }
          }
          return item;
        },
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: warmSurface,
          icon: const Icon(
            Icons.check_circle_rounded,
            color: rescueGreen,
            size: 46,
          ),
          title: const Text('Rescue reported', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                created['case_reference'] as String,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              PriorityBadge(priority: created['priority'] as String),
              const SizedBox(height: 12),
              const Text(
                'Great job, hero! An NGO coordinator can now verify and assign this case.',
                textAlign: TextAlign.center,
              ),
              if (photoWarning != null)
                Text(photoWarning!, style: const TextStyle(color: rescueCoral)),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(exception.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'Report a rescue',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5DF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      color: rescueCoral,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Stay safe. Do not enter traffic or approach an aggressive animal.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FormSection(
                title: 'Animal and condition',
                icon: Icons.pets_rounded,
                children: [
                  Wrap(spacing: 8, children: [
                    OutlinedButton.icon(
                        onPressed: () => pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camera')),
                    OutlinedButton.icon(
                        onPressed: () => pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Add photo')),
                  ]),
                  if (animalPhoto != null)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(animalPhoto!,
                                height: 160, fit: BoxFit.cover))),
                  drop(
                    'Animal type',
                    species,
                    const [
                      'dog',
                      'cat',
                      'cattle',
                      'buffalo',
                      'goat',
                      'sheep',
                      'poultry',
                      'horse',
                      'donkey',
                      'other',
                    ],
                    (v) => setState(() => species = v),
                  ),
                  TextFormField(
                    controller: condition,
                    maxLines: 3,
                    validator: (value) => (value?.trim().length ?? 0) < 3
                        ? 'Please describe what happened.'
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'What happened? *',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  drop(
                    'Consciousness',
                    consciousness,
                    const ['conscious', 'unconscious', 'unsure'],
                    (v) => setState(() => consciousness = v),
                  ),
                  drop(
                    'Bleeding',
                    bleeding,
                    const ['none', 'minor', 'severe'],
                    (v) => setState(() => bleeding = v),
                  ),
                  drop(
                    'Mobility',
                    mobility,
                    const ['mobile', 'limping', 'immobile', 'unsure'],
                    (v) => setState(() => mobility = v),
                  ),
                  drop(
                    'Breathing difficulty',
                    breathing,
                    const ['no', 'yes', 'unsure'],
                    (v) => setState(() => breathing = v),
                  ),
                  drop(
                    'Surrounding danger',
                    danger,
                    const [
                      'none',
                      'traffic',
                      'fire',
                      'water',
                      'electrical',
                      'violence',
                      'other',
                    ],
                    (v) => setState(() => danger = v),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FormSection(
                title: 'Location',
                icon: Icons.location_on_outlined,
                children: [
                  LocationPawPicker(onChanged: (point) {
                    animalLatitude = point.latitude;
                    animalLongitude = point.longitude;
                  }),
                  TextFormField(
                    controller: district,
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? 'District is required.'
                        : null,
                    decoration: const InputDecoration(labelText: 'District *'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: village,
                    decoration:
                        const InputDecoration(labelText: 'Village or area'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: landmark,
                    decoration:
                        const InputDecoration(labelText: 'Nearby landmark'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: loading ? null : submit,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Send rescue report'),
              ),
            ],
          ),
        ),
      );

  Widget drop(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> change,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(labelText: label),
          items: values
              .map(
                (v) => DropdownMenuItem(value: v, child: Text(humanize(v))),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) change(v);
          },
        ),
      );
}

class FormSection extends StatelessWidget {
  const FormSection({
    required this.title,
    required this.icon,
    required this.children,
    super.key,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: deepGreen),
                  const SizedBox(width: 9),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ...children,
            ],
          ),
        ),
      );
}

class CasesPanel extends StatefulWidget {
  const CasesPanel({required this.api, required this.session, super.key});
  final ApiClient api;
  final Session session;

  @override
  State<CasesPanel> createState() => _CasesPanelState();
}

class _CasesPanelState extends State<CasesPanel> {
  late Future<List<Map<String, dynamic>>> future = widget.api.getCases();

  Future<void> refresh() async {
    final next = widget.api.getCases();
    if (!mounted) return;
    setState(() {
      future = next;
    });
    await next;
  }

  Future<void> act(Map<String, dynamic> item) async {
    try {
      await withRescueBuddy<void>(
        context,
        message: item['status'] == 'reported'
            ? 'Double-checking the paw prints…'
            : 'Alerting the rescue team…',
        animal: animalEmoji(item['species'] as String),
        action: () async {
          if ({'ngo_coordinator', 'system_admin'}
              .contains(widget.session.role)) {
            if (item['status'] == 'reported') {
              await widget.api.verifyCase(item['id'] as String);
            } else if (item['status'] == 'verified') {
              final volunteers = await widget.api.getVolunteers();
              if (volunteers.isEmpty) {
                throw ApiException('No volunteer is available', 422);
              }
              await widget.api.assignCase(
                item['id'] as String,
                volunteers.first['id'] as String,
              );
            }
          } else if (widget.session.role == 'rescue_volunteer') {
            final next = {
              'assigned': 'accepted',
              'accepted': 'en_route',
              'en_route': 'on_scene',
              'on_scene': 'rescued',
              'rescued': 'closed',
            }[item['status']];
            if (next != null) {
              await widget.api.updateStatus(
                item['id'] as String,
                next,
                item['version'] as int,
              );
            }
          }
        },
      );
      await refresh();
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(exception.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingBuddy(
              message: 'Sniffing out rescue updates…',
              animal: '🐈',
            );
          }
          if (snapshot.hasError) {
            return StateMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Could not load cases',
              subtitle: snapshot.error.toString(),
              onAction: refresh,
            );
          }
          final cases = snapshot.data ?? [];
          if (cases.isEmpty) {
            return StateMessage(
              icon: Icons.pets_rounded,
              title: 'No rescue cases yet',
              subtitle: widget.session.role == 'public_reporter'
                  ? 'Your submitted reports will appear here.'
                  : 'New community reports will appear here.',
              onAction: refresh,
            );
          }
          return RefreshIndicator(
            color: rescueGreen,
            onRefresh: refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
              itemCount: cases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) => CaseCard(
                item: cases[index],
                session: widget.session,
                api: widget.api,
                onAction: () => act(cases[index]),
              ),
            ),
          );
        },
      );
}

class CaseCard extends StatelessWidget {
  const CaseCard({
    required this.item,
    required this.session,
    required this.onAction,
    required this.api,
    super.key,
  });
  final Map<String, dynamic> item;
  final Session session;
  final VoidCallback onAction;
  final ApiClient api;

  bool get actionable =>
      ({'ngo_coordinator', 'system_admin'}.contains(session.role) &&
          {'reported', 'verified'}.contains(item['status'])) ||
      (session.role == 'rescue_volunteer' &&
          item['assigned_volunteer_id'] == session.userId &&
          {'assigned', 'accepted', 'en_route', 'on_scene', 'rescued'}
              .contains(item['status']));

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9F5EC),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      animalEmoji(item['species'] as String),
                      style: const TextStyle(fontSize: 25),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['case_reference'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${humanize(item['species'] as String)} • ${item['district']}',
                          style: const TextStyle(color: Color(0xFF617083)),
                        ),
                      ],
                    ),
                  ),
                  PriorityBadge(priority: item['priority'] as String),
                ],
              ),
              const SizedBox(height: 14),
              if ((item['photo_count'] as num? ?? 0) > 0)
                FutureBuilder<Uint8List>(
                    future: api.getPhoto(item['id'] as String),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(snapshot.data!,
                                height: 170,
                                width: double.infinity,
                                fit: BoxFit.cover));
                      }
                      return Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(snapshot.hasError
                              ? 'Photo unavailable — refresh to retry'
                              : 'Loading rescue photo…'));
                    }),
              Text(
                item['visible_condition'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.35),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  const Icon(Icons.circle, size: 9, color: softSky),
                  const SizedBox(width: 6),
                  Text(
                    humanize(item['status'] as String),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF617083),
                    ),
                  ),
                  const Spacer(),
                  if (actionable)
                    FilledButton(
                      onPressed: onAction,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(94, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(actionLabel(item['status'] as String)),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({required this.priority, super.key});
  final String priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      'critical' => rescueCoral,
      'urgent' => const Color(0xFFE49A2D),
      _ => rescueGreen,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        humanize(priority),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class StateMessage extends StatelessWidget {
  const StateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onAction,
    super.key,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: const BoxDecoration(
                  color: Color(0xFFD9F5EC),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 42, color: deepGreen),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF617083), height: 1.4),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}

class LoadingBuddy extends StatefulWidget {
  const LoadingBuddy({
    required this.message,
    this.animal = '🐈',
    this.compact = false,
    super.key,
  });
  final String message;
  final String animal;
  final bool compact;

  @override
  State<LoadingBuddy> createState() => _LoadingBuddyState();
}

class _LoadingBuddyState extends State<LoadingBuddy>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  )..repeat(reverse: true);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(widget.compact ? 20 : 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: controller,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, -10 * controller.value),
                    child: Transform.rotate(
                      angle: math.sin(controller.value * math.pi) * 0.08,
                      child: child,
                    ),
                  ),
                  child: Text(
                    widget.animal,
                    style: TextStyle(fontSize: widget.compact ? 48 : 64),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: deepGreen,
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(
                  width: 72,
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    color: rescueGreen,
                    backgroundColor: Color(0xFFD9F5EC),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

Future<T> withRescueBuddy<T>(
  BuildContext context, {
  required String message,
  required String animal,
  required Future<T> Function() action,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        child: LoadingBuddy(message: message, animal: animal, compact: true),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 120));
  try {
    return await action();
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

String humanize(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

String actionLabel(String status) => switch (status) {
      'reported' => 'Verify',
      'verified' => 'Assign',
      'assigned' => 'Accept',
      'accepted' => 'En route',
      'en_route' => 'On scene',
      'on_scene' => 'Rescued',
      'rescued' => 'Close',
      _ => 'Update',
    };

String animalEmoji(String species) => switch (species) {
      'dog' => '🐕',
      'cat' => '🐈',
      'cattle' => '🐄',
      'buffalo' => '🐃',
      'goat' => '🐐',
      'sheep' => '🐑',
      'poultry' => '🐓',
      'horse' => '🐎',
      'donkey' => '🫏',
      _ => '🐾',
    };
