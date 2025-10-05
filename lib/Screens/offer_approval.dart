import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class OfferApprovalScreen extends StatefulWidget {
  const OfferApprovalScreen({super.key});

  @override
  State<OfferApprovalScreen> createState() => _OfferApprovalScreenState();
}

class _OfferApprovalScreenState extends State<OfferApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // Update offer status and verificationStatus
  Future<void> updateOfferStatus(
      BuildContext context, String id, bool isApproved) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isApproved ? 'Approve Offer' : 'Reject Offer',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to ${isApproved ? 'approve' : 'reject'} this offer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestore.collection('offers').doc(id).update({
        'verificationStatus': isApproved ? 'verified' : 'rejected',
        'status': isApproved ? 'Active' : 'Rejected',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offer ${isApproved ? 'Approved' : 'Rejected'} successfully!'),
          backgroundColor: isApproved ? Colors.green : Colors.redAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating offer status.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Stream based on tab
  Stream<QuerySnapshot> getOffersStream(String tab) {
    switch (tab) {
      case 'Pending':
        return _firestore
            .collection('offers')
            .where('verificationStatus', isEqualTo: 'pending')
            .where('status', whereIn: ['Active', 'Rejected']) // exclude expired
            .snapshots();
      case 'Approved':
        return _firestore
            .collection('offers')
            .where('verificationStatus', isEqualTo: 'verified')
            .where('status', isEqualTo: 'Active')
            .snapshots();
      case 'Expired':
        return _firestore
            .collection('offers')
            .where('status', isEqualTo: 'Expired')
            .snapshots();
      default:
        return _firestore.collection('offers').snapshots();
    }
  }


  // Load image from Firebase Storage if needed
  Future<String> getOfferImageUrl(String url) async {
    if (url.isEmpty) return '';
    // If the url is already public, just return it
    if (url.startsWith('http')) return url;
    try {
      final ref = _storage.ref().child(url);
      return await ref.getDownloadURL();
    } catch (_) {
      return '';
    }
  }

  // Build each offer card
  Widget buildOfferCard(DocumentSnapshot offerDoc, String tab) {
    final data = offerDoc.data() as Map<String, dynamic>;

    final brandName = data['brandName'] ?? 'Unknown Brand';
    final title = data['title'] ?? 'No Title';
    final couponCode = data['couponCode'] ?? '-';
    final imageUrl = data['imageUrl'] ?? '';
    final offerDetail = data['offerDetail'] ?? '-';
    final location = data['location'] ?? '-';
    final redemptionTerm = data['redemptionTerm'] ?? '-';
    final providerId = data['providerId'] ?? '-';
    final createdAt = data['createdAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
        : DateTime.now();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ExpansionTile(
        leading: SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isEmpty
                ? const Icon(Icons.broken_image, size: 60, color: Colors.grey)
                : Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'Brand: $brandName\nCreated: ${createdAt.toLocal().toString().split(' ')[0]}',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coupon: $couponCode'),
                const SizedBox(height: 6),
                Text('Offer Details: $offerDetail'),
                const SizedBox(height: 6),
                Text('Location: $location'),
                const SizedBox(height: 6),
                Text('Redemption Term: $redemptionTerm'),
                const SizedBox(height: 6),
                Text('Provider ID: $providerId'),
                const SizedBox(height: 12),
                if (tab == 'Pending')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () =>
                            updateOfferStatus(context, offerDoc.id, true),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            updateOfferStatus(context, offerDoc.id, false),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offer Approval Panel'),
        backgroundColor: Colors.orange,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Expired'),
          ],
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: ['Pending', 'Approved', 'Expired'].map((tab) {
          return StreamBuilder<QuerySnapshot>(
            stream: getOffersStream(tab),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No $tab Offers'));
              }
              final offers = snapshot.data!.docs;
              return ListView.builder(
                itemCount: offers.length,
                itemBuilder: (context, index) => buildOfferCard(offers[index], tab),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
