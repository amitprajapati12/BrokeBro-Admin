import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InternshipApprovalScreen extends StatelessWidget {
  const InternshipApprovalScreen({super.key});

  Future<void> updateVerificationStatus(
    BuildContext context,
    String docId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('internship')
          .doc(docId)
          .update({'verificationStatus': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Internship marked as $newStatus ✅')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> showConfirmationDialog(
    BuildContext context,
    String docId,
    String action,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('$action Internship'),
          content: Text('Are you sure you want to $action this internship?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                final newStatus = action == 'Approve' ? 'Verified' : 'Rejected';
                updateVerificationStatus(context, docId, newStatus);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: action == 'Approve'
                    ? Colors.green
                    : Colors.red,
              ),
              child: Text(action),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internship Approvals'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('internship')
            .where('verificationStatus', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending internships.'));
          }

          final internships = snapshot.data!.docs;

          return ListView.builder(
            itemCount: internships.length,
            itemBuilder: (context, index) {
              final doc = internships[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data['imageUrl'] != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        child: Image.network(
                          data['imageUrl'],
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? 'No Title',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("Brand: ${data['brandName'] ?? ''}"),
                          Text("Location: ${data['location'] ?? ''}"),
                          Text("Stipend: ${data['stipend'] ?? ''}"),
                          Text("Duration: ${data['duration'] ?? ''}"),
                          const SizedBox(height: 8),
                          Text(
                            "Verification: ${data['verificationStatus'] ?? 'Pending'}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: (data['verificationStatus'] == 'Verified')
                                  ? Colors.green
                                  : (data['verificationStatus'] == 'Rejected')
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => showConfirmationDialog(
                                  context,
                                  doc.id,
                                  'Approve',
                                ),
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => showConfirmationDialog(
                                  context,
                                  doc.id,
                                  'Reject',
                                ),
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
