import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_service.dart';

class UserJobsPage extends StatefulWidget {
  const UserJobsPage({super.key});

  @override
  State<UserJobsPage> createState() => _UserJobsPageState();
}

class _UserJobsPageState extends State<UserJobsPage> {
  late Future<List<Map<String, dynamic>>> jobFuture;
  Map<String, dynamic>? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    jobFuture = fetchUserJobs();
  }

  Future<void> _loadUserLocation() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final location = await LocationService.getUserLocation(user.id);
      setState(() {
        _userLocation = location;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserJobs() async {
    final uid = Supabase.instance.client.auth.currentUser!.id;

    final response = await Supabase.instance.client
        .from('jobs')
        .select('*, users!jobs_accepted_by_fkey(name, id)')
        .eq('created_by', uid)
        .order('created_at');

    final jobs = List<Map<String, dynamic>>.from(response);

    // Add distance information if user location is available
    if (_userLocation != null) {
      for (var job in jobs) {
        if (job['accepted_by'] != null) {
          final providerLocation = await LocationService.getUserLocation(job['accepted_by']);
          if (providerLocation != null) {
            final distance = LocationService.calculateDistance(
              _userLocation!['latitude'],
              _userLocation!['longitude'],
              providerLocation['latitude'],
              providerLocation['longitude'],
            );
            job['distance'] = distance;
          }
        }
      }
    }

    return jobs;
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
        title: const Text('My Job Requests'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _loadUserLocation();
              setState(() {
                jobFuture = fetchUserJobs();
              });
            },
            tooltip: 'Refresh',
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
            return const Center(child: Text('No job requests yet.'));
          }

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              final status = job['status'];
              final providerName = job['users']?['name'] ?? 'Unknown';
              final distance = job['distance'];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
                    child: Icon(
                      status == 'accepted' ? Icons.check : Icons.pending,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    job['title'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: $status'),
                      if (status == 'accepted') ...[
                        Text('Accepted by: $providerName'),
                        if (distance != null)
                          Text(
                            _formatDistance(distance),
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
