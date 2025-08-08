import 'package:booking/userppagejob.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'user_jobs_page.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});
  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  int _selectedIndex = 0;
  final List<Widget> _pages = [const UserHomeBody(), const UserJobsPage()];

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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Post Job'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'My Jobs'),
        ],
      ),
    );
  }
}

class UserHomeBody extends StatelessWidget {
  const UserHomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    final _UserHomeState? parent = context
        .findAncestorStateOfType<_UserHomeState>();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: parent?.titleController,
            decoration: const InputDecoration(labelText: 'Job Title'),
          ),
          TextField(
            controller: parent?.descController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          ElevatedButton(
            onPressed: () async {
              final uid = Supabase.instance.client.auth.currentUser!.id;
              await Supabase.instance.client.from('jobs').insert({
                'title': parent?.titleController.text,
                'description': parent?.descController.text,
                'created_by': uid,
              });
              parent?.titleController.clear();
              parent?.descController.clear();
            },
            child: const Text('Submit Job'),
          ),
          SizedBox(height: 200),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              // Navigation will be handled automatically by AuthWrapper
            },
            child: const Text('log out'),
          ),
        ],
      ),
    );
  }
}
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Post Job'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.list_alt),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const UserJobsPage()),
//               );
//             },
//           )
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Job Title')),
//             TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
//             ElevatedButton(onPressed: postJob, child: const Text('Submit Job')),
//           ],
//         ),
//       ),
//     );
//   }
// }