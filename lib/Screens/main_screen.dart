import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_login_page.dart';

void main() {
  runApp(const AdminPanelApp());
}

// Main App
class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Student Model
class Student {
  final String name;
  final String university;
  final String course;
  String status;
  final String submitted;

  Student({
    required this.name,
    required this.university,
    required this.course,
    required this.status,
    required this.submitted,
  });
}

// Main Screen
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Student> students = [
    Student(
        name: 'Alice Johnson',
        university: 'MIT',
        course: 'Computer Science',
        status: 'Pending',
        submitted: '1h ago'),
    Student(
        name: 'Bob Smith',
        university: 'Stanford University',
        course: 'Business',
        status: 'Under Review',
        submitted: '4h ago'),
    Student(
        name: 'Carol Davis',
        university: 'Harvard University',
        course: 'Medicine',
        status: 'Pending',
        submitted: '8h ago'),
    Student(
        name: 'David Wilson',
        university: 'UC Berkeley',
        course: 'Engineering',
        status: 'Approved',
        submitted: '1d ago'),
  ];

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _selectedIndex == 0
                ? 'Dashboard Overview'
                : _selectedIndex == 3
                ? 'Student ID Verification'
                : 'Admin Panel'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                );
              }
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: CircleAvatar(child: Icon(Icons.person)),
          ),
        ],
      ),
      drawer: wide ? null : Drawer(child: _buildDrawerContent()),
      body: Row(
        children: [
          if (wide) _buildSideNav(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNav() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
            icon: Icon(Icons.dashboard), label: Text('Dashboard')),
        NavigationRailDestination(
            icon: Icon(Icons.work_outline),
            label: Text('Internship Verification')),
        NavigationRailDestination(
            icon: Icon(Icons.card_travel), label: Text('Offer Verification')),
        NavigationRailDestination(
            icon: Icon(Icons.badge), label: Text('Student ID Verification')),
      ],
    );
  }

  Widget _buildDrawerContent() {
    return ListView(
      children: [
        const DrawerHeader(
          child: Text('Admin Panel',
              style: TextStyle(fontSize: 20, color: Colors.white)),
          decoration: BoxDecoration(color: Colors.orange),
        ),
        ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => setState(() => _selectedIndex = 0)),
        ListTile(
            leading: const Icon(Icons.work_outline),
            title: const Text('Internship Verification'),
            onTap: () => setState(() => _selectedIndex = 1)),
        ListTile(
            leading: const Icon(Icons.local_offer),
            title: const Text('Offer Verification'),
            onTap: () => setState(() => _selectedIndex = 2)),
        ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('Student ID Verification'),
            onTap: () => setState(() => _selectedIndex = 3)),
      ],
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 3:
        return StudentIdVerification(
          students: students,
          onView: _showStudentDialog,
          onApprove: _approveStudent,
        );
      default:
        return const Center(child: Text('Section not implemented yet'));
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatCard('Pending Internships', '24', Icons.work,
                  Colors.orange),
              const SizedBox(width: 12),
              _buildStatCard('Pending Offers', '18', Icons.card_travel,
                  Colors.purple),
              const SizedBox(width: 12),
              _buildStatCard('Pending ID Cards', '31', Icons.badge,
                  Colors.green),
              const SizedBox(width: 12),
              _buildStatCard(
                  'Verified Today', '12', Icons.verified, Colors.blue),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent Verification Activities',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    separatorBuilder: (_, __) => const Divider(height: 12),
                    itemBuilder: (context, idx) {
                      return ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.check, color: Colors.white),
                            backgroundColor: Colors.lightBlue),
                        title: const Text('Verified internship for John Doe'),
                        subtitle: const Text('2 minutes ago'),
                        trailing: Chip(
                          label: const Text('Approved'),
                          backgroundColor: Colors.green.shade100,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Stat Card Widget
  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(count,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // Show Student Dialog
  void _showStudentDialog(Student student) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(student.name),
        content: Text(
            'Course: ${student.course}\nUniversity: ${student.university}\nStatus: ${student.status}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Approve Student
  void _approveStudent(Student student) {
    setState(() {
      student.status = 'Approved';
    });
  }
}

// Student ID Verification Widget
class StudentIdVerification extends StatelessWidget {
  final List<Student> students;
  final Function(Student) onView;
  final Function(Student) onApprove;

  const StudentIdVerification({
    super.key,
    required this.students,
    required this.onView,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(student.name),
            subtitle: Text('${student.course} - ${student.university}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => onView(student),
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => onApprove(student),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}