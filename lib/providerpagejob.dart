import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_service.dart';

class ProviderJobsPage extends StatefulWidget {
  const ProviderJobsPage({super.key});

  @override
  State<ProviderJobsPage> createState() => _ProviderJobsPageState();
}

class _ProviderJobsPageState extends State<ProviderJobsPage> {
  Map<String, dynamic>? _providerLocation;

  @override
  void initState() {
    super.initState();
    _loadProviderLocation();
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

  Stream<List<Map<String, dynamic>>> getAcceptedJobs() {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    return Supabase.instance.client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('accepted_by', uid)
        .order('created_at')
        .asyncMap((data) async {
          // Add distance information if provider location is available
          if (_providerLocation != null) {
            for (var job in data) {
              final userLocation = await LocationService.getUserLocation(
                job['created_by'],
              );
              if (userLocation != null) {
                final distance = LocationService.calculateDistance(
                  _providerLocation!['latitude'],
                  _providerLocation!['longitude'],
                  userLocation['latitude'],
                  userLocation['longitude'],
                );
                job['distance'] = distance;
              }
            }
          }
          return data;
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
        title: const Text('My Accepted Jobs'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _loadProviderLocation();
              setState(() {});
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getAcceptedJobs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final jobs = snapshot.data!;
          if (jobs.isEmpty)
            return const Center(child: Text('No accepted jobs yet.'));
          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              final distance = job['distance'];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.work, color: Colors.white),
                  ),
                  title: Text(
                    job['title'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${job['status']}'),
                      if (distance != null)
                        Text(
                          _formatDistance(distance),
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
