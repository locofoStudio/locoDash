import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'offers_card.dart';
import 'item_creation_widget.dart';

class OffersTabContent extends StatefulWidget {
  final String venueId;
  const OffersTabContent({Key? key, required this.venueId}) : super(key: key);

  @override
  State<OffersTabContent> createState() => _OffersTabContentState();
}

class _OffersTabContentState extends State<OffersTabContent> {
  bool showForm = false;
  Map<String, dynamic>? editingOffer;

  void _showAddForm() {
    setState(() {
      editingOffer = null;
      showForm = true;
    });
  }

  void _showEditForm(Map<String, dynamic> offer) {
    setState(() {
      editingOffer = offer;
      showForm = true;
    });
  }

  void _hideForm() {
    setState(() {
      showForm = false;
      editingOffer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showForm) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ItemCreationWidget(
              initialData: editingOffer,
              onCancel: _hideForm,
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16, right: 16),
          child: SizedBox(
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE86526),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _showAddForm,
              child: const Text(
                'Add item',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('offers')
              .where('venueId', isEqualTo: widget.venueId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No offers found', style: TextStyle(color: Colors.white)));
            }
            final offers = snapshot.data!.docs;
            return ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              itemCount: offers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final offer = offers[index].data() as Map<String, dynamic>;
                return OffersCard(
                  offerName: offer['OfferName'] ?? 'Offer name',
                  offerDescription: offer['OfferInfo'] ?? 'Offer detail',
                  coinValue: offer['OfferPrice']?.toString() ?? '0',
                  imageUrl: offer['OfferPhoto'],
                  onEdit: () => _showEditForm({...offer, 'id': offers[index].id}),
                );
              },
            );
          },
        ),
      ],
    );
  }
} 