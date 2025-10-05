import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_login_page.dart';
import 'student_id_verification.dart';
import 'internship_approval.dart';
import 'offer_approval.dart';
import 'event_approval.dart';

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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
        title: Text(_getTitle()),
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

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard Overview';
      case 1:
        return 'Internship Verification';
      case 2:
        return 'Offer Verification';
      case 3:
        return 'Student ID Verification';
      case 4:
        return 'Event Approval';
      default:
        return 'Admin Panel';
    }
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
        NavigationRailDestination(
            icon: Icon(Icons.event), label: Text('Event Approval')),
      ],
    );
  }

  Widget _buildDrawerContent() {
    return ListView(
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: Colors.orange),
          child: Text('Admin Panel',
              style: TextStyle(fontSize: 20, color: Colors.white)),
        ),
        _buildDrawerTile(Icons.dashboard, 'Dashboard', 0),
        _buildDrawerTile(Icons.work_outline, 'Internship Verification', 1),
        _buildDrawerTile(Icons.card_travel, 'Offer Verification', 2),
        _buildDrawerTile(Icons.badge, 'Student ID Verification', 3),
        _buildDrawerTile(Icons.event, 'Event Approval', 4),
      ],
    );
  }

  ListTile _buildDrawerTile(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const InternshipApprovalScreen();
      case 2:
        return const OfferApprovalScreen();
      case 3:
        return StudentIdVerificationScreen(
          students: students,
          onView: _showStudentDialog,
          onApprove: _approveStudent,
        );
      case 4:
        return const EventApprovalScreen();
      default:
        return const Center(child: Text('Section not implemented yet'));
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatCard('Pending Internships', '24', Icons.work,
                  Colors.orange),
              _buildStatCard('Pending Offers', '18', Icons.card_travel,
                  Colors.purple),
              _buildStatCard('Pending ID Cards', '31', Icons.badge,
                  Colors.green),
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
                            backgroundColor: Colors.lightBlue,
                            child: Icon(Icons.check, color: Colors.white)),
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

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return SizedBox(
      width: 220,
      child: Card(
        color: color.withAlpha((0.1 * 255).round()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(count,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

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

  void _approveStudent(Student student) {
    setState(() {
      student.status = 'Approved';
    });
  }
}
