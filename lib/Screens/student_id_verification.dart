import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class StudentIdVerificationScreen extends StatelessWidget {
  final List<Student> students;
  final Function(Student) onView;
  final Function(Student) onApprove;

  const StudentIdVerificationScreen({
    super.key,
    required this.students,
    required this.onView,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return
      ListView.builder(
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
                    onPressed: () => onView(student)),
                IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => onApprove(student)),
              ],
            ),
          ),
        );
      },
    );
  }
}
