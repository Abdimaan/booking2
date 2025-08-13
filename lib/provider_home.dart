import 'package:booking/login_page.dart';
import 'package:booking/providerpagejob.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_service.dart';
import 'location_tracker.dart';
// import 'provider_jobs_page.dart';

class ProviderHome extends StatefulWidget {
  const ProviderHome({super.key});
  @override
  State<ProviderHome> createState() => _ProviderHomeState();
}

class _ProviderHomeState extends State<ProviderHome>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const ProviderAvailableJobsPage(),
    const ProviderJobsPage(),
  ];
  final LocationTracker _locationTracker = LocationTracker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLocationTracking();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground - restart location tracking
        print('App resumed - restarting location tracking');
        _startLocationTracking();
        break;
      case AppLifecycleState.paused:
        // App went to background - optionally pause tracking
        print('App paused - location tracking continues in background');
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., phone call, notification panel)
        print('App inactive');
        break;
      case AppLifecycleState.detached:
        // App is detached
        print('App detached');
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        print('App hidden');
        break;
    }
  }

  void _startLocationTracking() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Stop existing tracking before starting new one
      if (_locationTracker.isTracking) {
        _locationTracker.stopTracking();
      }
      _locationTracker.startTracking(user.id);
      print('Location tracking started for provider: ${user.id}');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationTracker.stopTracking();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'My Jobs'),
        ],
      ),
    );
  }
}

class ProviderAvailableJobsPage extends StatefulWidget {
  const ProviderAvailableJobsPage({super.key});

  @override
  State<ProviderAvailableJobsPage> createState() =>
      _ProviderAvailableJobsPageState();
}

class _ProviderAvailableJobsPageState extends State<ProviderAvailableJobsPage> {
  late Future<List<Map<String, dynamic>>> jobFuture;
  Map<String, dynamic>? _providerLocation;

  @override
  void initState() {
    super.initState();
    _loadProviderLocation();
    jobFuture = fetchPendingJobs();
  }

  Future<void> _loadProviderLocation() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final location = await LocationService.getUserLocation(user.id);
      setState(() {
        _providerLocation = location;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchPendingJobs() async {
    final providerId = Supabase.instance.client.auth.currentUser!.id;

    // Get provider location
    final providerLocation = await LocationService.getUserLocation(providerId);
    if (providerLocation == null) return [];

    // Get rejected job IDs for this provider
    final rejectedJobIdsResponse = await Supabase.instance.client
        .from('rejected_jobs')
        .select('job_id')
        .eq('provider_id', providerId);

    final rejectedJobIds = rejectedJobIdsResponse
        .map((e) => e['job_id'] as String)
        .toList();

    // Get all pending jobs with user locations and created_at
    final jobsResponse = await Supabase.instance.client
        .from('jobs')
        .select('*, users!fk_jobs_created_by(name, id)')
        .eq('status', 'pending')
        .order('created_at');

    final allJobs = List<Map<String, dynamic>>.from(jobsResponse);

    final now = DateTime.now();
    final visibleJobs = <Map<String, dynamic>>[];

    for (var job in allJobs) {
      if (rejectedJobIds.contains(job['id'])) continue;

      // Get job requester location
      final userLocation = await LocationService.getUserLocation(
        job['users']['id'],
      );
      if (userLocation == null) continue;

      // Calculate distance
      final distance = LocationService.calculateDistance(
        providerLocation['latitude'],
        providerLocation['longitude'],
        userLocation['latitude'],
        userLocation['longitude'],
      );
      job['distance'] = distance;

      // Calculate time since job creation
      final createdAt = DateTime.parse(job['created_at']);
      final minutesSinceCreation = now.difference(createdAt).inMinutes;

      // Determine allowed distance range based on phase
      double minDistance = 0;
      double maxDistance;

      if (minutesSinceCreation < 1) {
        maxDistance = 80; // 0-80 meters
      } else if (minutesSinceCreation < 2) {
        minDistance = 81;
        maxDistance = 250; // 81-700 meters
      } else if (minutesSinceCreation < 3) {
        minDistance = 251;
        maxDistance = 450; // 701-1100 meters
      } else if (minutesSinceCreation < 4) {
        minDistance = 451;
        maxDistance = 1260; // 1101-1260 meters
      } else if (minutesSinceCreation < 5) {
        minDistance = 1261;
        maxDistance = 1300; // 1261-1300 meters
      } else {
        minDistance = 1301;
        maxDistance = double.infinity; // 1301+ meters (public phase)
      }

      if (distance >= minDistance && distance <= maxDistance) {
        visibleJobs.add(job);
      }
    }

    return visibleJobs;
  }

  Future<void> acceptJob(String jobId) async {
    final uid = Supabase.instance.client.auth.currentUser!.id;

    await Supabase.instance.client
        .from('jobs')
        .update({'status': 'accepted', 'accepted_by': uid})
        .eq('id', jobId);

    setState(() {
      jobFuture = fetchPendingJobs();
    });
  }

  Future<void> rejectJob(String jobId) async {
    final uid = Supabase.instance.client.auth.currentUser!.id;

    await Supabase.instance.client.from('rejected_jobs').insert({
      'job_id': jobId,
      'provider_id': uid,
    });

    setState(() {
      jobFuture = fetchPendingJobs();
    });
  }

  String _formatDistance(double? distance) {
    if (distance == null) return 'Distance unknown';
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m away';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km away';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Jobs'),
        actions: [
          IconButton(
            icon: Icon(Icons.location_on),
            onPressed: () {
              _loadProviderLocation();
              setState(() {
                jobFuture = fetchPendingJobs();
              });
            },
            tooltip: 'Refresh Location',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: jobFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobs = snapshot.data!;
          if (jobs.isEmpty) {
            return const Center(child: Text('No pending jobs'));
          }

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              final requester = job['users']?['name'] ?? 'Unknown';
              final distance = job['distance'];

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(job['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${job['description'] ?? ''}\nRequested by: $requester',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (distance != null)
                        Text(
                          _formatDistance(distance),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 10,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        onPressed: () => acceptJob(job['id']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => rejectJob(job['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Supabase.instance.client.auth.signOut();
          // Navigation will be handled automatically by AuthWrapper
        },
        child: const Icon(Icons.logout),
        tooltip: 'Log Out',
      ),
    );
  }
}
