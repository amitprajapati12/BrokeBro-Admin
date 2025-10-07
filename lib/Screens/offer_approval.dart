import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class OfferApprovalScreen extends StatefulWidget {
  const OfferApprovalScreen({super.key});

  @override
  State<OfferApprovalScreen> createState() => _OfferApprovalScreenState();
}

class _OfferApprovalScreenState extends State<OfferApprovalScreen>
    with TickerProviderStateMixin {
  late TabController _verificationTabController;
  late TabController _statusTabController;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _verificationTabController = TabController(length: 3, vsync: this); // Pending, Approved, Rejected
    _statusTabController = TabController(length: 2, vsync: this); // Active, Expired
  }

  // ✅ Only update verificationStatus
  Future<void> updateVerificationStatus(
      BuildContext context, String id, String newVerificationStatus) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Change Verification Status',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
            'Are you sure you want to mark this offer as "$newVerificationStatus"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Yes')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestore
          .collection('offers')
          .doc(id)
          .update({'verificationStatus': newVerificationStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Offer verification status changed to $newVerificationStatus successfully!'),
          backgroundColor:
          newVerificationStatus == 'verified' ? Colors.green : Colors.redAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating verification status.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ Only update status
  Future<void> updateStatus(BuildContext context, String id, String newStatus) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Change Status',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Are you sure you want to mark this offer as "$newStatus"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Yes')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestore.collection('offers').doc(id).update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offer status changed to $newStatus successfully!'),
          backgroundColor: newStatus == 'Active' ? Colors.green : Colors.grey,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating status.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Stream for verification tabs
  Stream<QuerySnapshot> getVerificationStream(String tab) {
    switch (tab) {
      case 'Pending':
        return _firestore
            .collection('offers')
            .where('verificationStatus', isEqualTo: 'pending')
            .snapshots();
      case 'Approved':
        return _firestore
            .collection('offers')
            .where('verificationStatus', isEqualTo: 'verified')
            .snapshots();
      case 'Rejected':
        return _firestore
            .collection('offers')
            .where('verificationStatus', isEqualTo: 'rejected')
            .snapshots();
      default:
        return _firestore.collection('offers').snapshots();
    }
  }

  // Stream for status tabs
  Stream<QuerySnapshot> getStatusStream(String tab) {
    return _firestore
        .collection('offers')
        .where('status', isEqualTo: tab) // 'Active' or 'Expired'
        .snapshots();
  }


// ✅ Load image from Firebase Storage using file path
  Widget safeNetworkImage(String fileName) {
    if (fileName.isEmpty) {
      return const Icon(Icons.broken_image, size: 60, color: Colors.grey);
    }

    return FutureBuilder<String>(
      future: _storage.ref(fileName).getDownloadURL(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Icon(Icons.broken_image, size: 60, color: Colors.grey);
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 60, color: Colors.grey),
          ),
        );
      },
    );
  }




  // Build Offer Card
  Widget buildOfferCard(DocumentSnapshot offerDoc, String tab, {bool isVerification = true}) {
    final data = offerDoc.data() as Map<String, dynamic>;

    final brandName = data['brandName'] ?? 'Unknown Brand';
    final title = data['title'] ?? 'No Title';
    final couponCode = data['couponCode'] ?? '-';
    final imageUrl = (data['imageUrl'] ?? '').toString();
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
            child: safeNetworkImage(imageUrl),
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

                // Buttons based on type
                if (isVerification && tab == 'Pending')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => updateVerificationStatus(
                            context, offerDoc.id, 'verified'),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => updateVerificationStatus(
                            context, offerDoc.id, 'rejected'),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      ),
                    ],
                  ),
                if (!isVerification)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => updateStatus(context, offerDoc.id, 'Active'),
                        child: const Text('Mark Active'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => updateStatus(context, offerDoc.id, 'Expired'),
                        child: const Text('Mark Expired'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
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
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // =================== Verification Tabs ===================
            Container(
              decoration:  BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Verification Panel',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TabBar(
                      controller: _verificationTabController,
                      splashBorderRadius: BorderRadius.circular(16),
                      tabs: const [
                        Tab(text: 'Pending'),
                        Tab(text: 'Approved'),
                        Tab(text: 'Rejected'),
                      ],
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
            // Replace the first TabBarView section with this dynamic height version

            SizedBox(
              // dynamic height calculation
              height: 400, // default minimum
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return TabBarView(
                    controller: _verificationTabController,
                    children: ['Pending', 'Approved', 'Rejected'].map((tab) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: getVerificationStream(tab),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(child: Text('No $tab Offers'));
                          }

                          final offers = snapshot.data!.docs;
                          final tileHeight = 150.0; // approx height per card
                          final calculatedHeight = (offers.length * tileHeight) + 50;

                          return SizedBox(
                            height: calculatedHeight < 300 ? 300 : calculatedHeight,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(top: 10),
                              itemCount: offers.length,
                              itemBuilder: (context, index) =>
                                  buildOfferCard(offers[index], tab, isVerification: true),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // =================== Status Tabs ===================
            Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Status Panel',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TabBar(
                      controller: _statusTabController,
                      splashBorderRadius: BorderRadius.circular(16),
                      tabs: const [
                        Tab(text: 'Active'),
                        Tab(text: 'Expired'),
                      ],
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 400, // adjust height for second TabBarView
              child: TabBarView(
                controller: _statusTabController,
                children: ['Active', 'Expired'].map((tab) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: getStatusStream(tab),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No $tab Offers'));
                      }
                      final offers = snapshot.data!.docs;
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 10),
                        itemCount: offers.length,
                        itemBuilder: (context, index) =>
                            buildOfferCard(offers[index], tab, isVerification: false),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
