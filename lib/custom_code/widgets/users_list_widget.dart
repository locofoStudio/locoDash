// Automatic FlutterFlow imports
// Imports other custom widgets
// Imports custom actions
// Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Imports other custom widgets
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:html' as html;
import 'dart:convert';

class UsersListWidget extends StatefulWidget {
  const UsersListWidget({
    super.key,
    required this.venueId,
    this.width = 368.0,
    this.height = 600.0,
    this.backgroundColor = const Color(0xFF363740),
    this.textColor = const Color(0xFFFCFDFF),
    this.showPreviewData = false,
  });

  final String venueId;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color textColor;
  final bool showPreviewData;

  @override
  _UsersListWidgetState createState() => _UsersListWidgetState();
}

class _UsersListWidgetState extends State<UsersListWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(31.0),
        boxShadow: [
          BoxShadow(
            offset: const Offset(-4, 5),
            color: Colors.black.withOpacity(0.25),
            spreadRadius: 0,
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: widget.showPreviewData
          ? _buildPreviewList()
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _getVenueClients(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No clients found',
                      style: TextStyle(color: widget.textColor),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                  children: [
                    ...snapshot.data!.map((client) => _buildUserCard(client)),
                    const SizedBox(height: 20),
                    _buildDownloadAllButton(),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 4, right: 4),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(31),
        boxShadow: [
          BoxShadow(
            offset: const Offset(-4, 5),
            color: Colors.black.withOpacity(0.25),
            spreadRadius: 0,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Image
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: client['photo_url'] != null
                        ? CachedNetworkImage(
                            imageUrl: client['photo_url'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.person, color: widget.textColor),
                          )
                        : Icon(Icons.person, color: widget.textColor),
                  ),
                ),
                const SizedBox(width: 12),
                // Name and Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client['display_name'] ?? 'Unknown',
                        style: TextStyle(
                          color: widget.textColor,
                          fontFamily: 'Roboto Flex',
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        client['email'] ?? '',
                        style: TextStyle(
                          color: widget.textColor.withOpacity(0.7),
                          fontFamily: 'Roboto Flex',
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ),
                // Download Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.textColor.withOpacity(0.2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    onTap: () => _downloadClientData(client),
                    child: Text(
                      'Download',
                      style: TextStyle(
                        color: widget.textColor,
                        fontFamily: 'Roboto Flex',
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat(
                    'Visits', client['sessions'] ?? 0, const Color(0xFF6FA6A0)),
                _buildStat('Coins', client['coins'] ?? 0, const Color(0xFFFF8B64)),
                _buildStat(
                    'High Score', client['high_score'] ?? 0, const Color(0xFFC5C352)),
                _buildStat(
                    'Redeemed', client['redeemed'] ?? 0, const Color(0xFFFF6464)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: widget.textColor,
            fontFamily: 'Roboto Flex',
            fontSize: 12.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value.toString().padLeft(3, '0'),
            style: TextStyle(
              color: valueColor,
              fontFamily: 'Roboto Flex',
              fontSize: 12.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadAllButton() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.textColor.withOpacity(0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: _downloadAllClientsData,
          child: Text(
            'Download all',
            style: TextStyle(
              color: widget.textColor,
              fontFamily: 'Roboto Flex',
              fontSize: 12.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewList() {
    final previewData = List.generate(
        4,
        (index) => {
              'display_name': 'Arlene McCoy',
              'email': 'Customer@email.com',
              'photo_url': null,
              'sessions': 12,
              'coins': 12,
              'high_score': 12,
              'redeemed': 12,
              'createdTime': Timestamp.fromDate(DateTime.now()),
            });

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      children: [
        ...previewData.map((client) => _buildUserCard(client)),
        const SizedBox(height: 20),
        _buildDownloadAllButton(),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _getVenueClients() async {
    try {
      print('Fetching clients for venue: [33m${widget.venueId}[0m');

      // Query userVenueProgress for this venue
      final usersQuery = await FirebaseFirestore.instance
          .collection('userVenueProgress')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      print('Found [36m${usersQuery.docs.length}[0m userVenueProgress entries for venue ${widget.venueId}');

      // Aggregate by userId
      Map<String, Map<String, dynamic>> userStats = {};
      for (var doc in usersQuery.docs) {
        final data = doc.data();
        final userId = doc.id;
        // Only include users with a non-empty email
        final email = data['email'] ?? '';
        if (email == null || (email is String && email.trim().isEmpty)) {
          continue;
        }
        if (!userStats.containsKey(userId)) {
          userStats[userId] = {
            'display_name': data['display_name'] ?? data['displayName'] ?? 'Unknown',
            'email': email,
            'photo_url': data['photo_url'] ?? data['photoUrl'],
            'sessions': 0,
            'coins': 0,
            'high_score': 0,
            'redeemed': 0,
            'createdTime': data['createdTime'],
          };
        }
        // Sum sessions
        userStats[userId]!['sessions'] = (userStats[userId]!['sessions'] as int) + (data['sessions'] is int ? data['sessions'] as int : (data['sessions'] is num ? (data['sessions'] as num).toInt() : 0));
        // Sum coins (coin + coins)
        int coins = 0;
        if (data['coins'] != null && data['coins'] is int) coins += data['coins'] as int;
        if (data['coin'] != null && data['coin'] is int) coins += data['coin'] as int;
        userStats[userId]!['coins'] = (userStats[userId]!['coins'] as int) + coins;
        // Max high score
        int highScore = 0;
        if (data['highScore'] != null && data['highScore'] is int) {
          highScore = data['highScore'] as int;
        } else if (data['high_score'] != null && data['high_score'] is int) highScore = data['high_score'] as int;
        if (highScore > (userStats[userId]!['high_score'] as int)) {
          userStats[userId]!['high_score'] = highScore;
        }
        // Sum redeemed
        userStats[userId]!['redeemed'] = (userStats[userId]!['redeemed'] as int) + (data['redeemed'] is int ? data['redeemed'] as int : (data['redeemed'] is num ? (data['redeemed'] as num).toInt() : 0));
      }

      // Convert to list
      List<Map<String, dynamic>> clients = userStats.values.toList();
      // Sort by sessions in descending order
      clients.sort((a, b) => (b['sessions'] as int).compareTo(a['sessions'] as int));
      return clients;
    } catch (e) {
      print('Error getting venue clients: $e');
      return [];
    }
  }

  void _downloadClientData(Map<String, dynamic> client) {
    final csvData = _convertClientToCSV(client);
    final fileName =
        '${client['display_name'].toString().replaceAll(' ', '_')}_data.csv';
    _downloadCSV(csvData, fileName);
  }

  void _downloadAllClientsData() async {
    try {
      final clients = await _getVenueClients();
      if (clients.isEmpty) return;

      // Create CSV header
      String csvData =
          'Name,Email,Created Date,Visits,Coins,High Score,Redeemed\n';

      // Add data for each client
      for (var client in clients) {
        csvData += _convertClientToCSV(client);
      }

      _downloadCSV(csvData, 'all_clients_data.csv');
    } catch (e) {
      print('Error downloading all clients data: $e');
    }
  }

  String _convertClientToCSV(Map<String, dynamic> client) {
    // Escape special characters and wrap fields in quotes if they contain commas
    String escapeField(dynamic value) {
      String str = value.toString();
      if (str.contains(',') || str.contains('"') || str.contains('\n')) {
        return '"${str.replaceAll('"', '""')}"';
      }
      return str;
    }

    // Format the createdTime
    String formatDate(Timestamp? timestamp) {
      if (timestamp == null) return 'N/A';
      final date = timestamp.toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    return '${escapeField(client['display_name'])},'
        '${escapeField(client['email'])},'
        '${escapeField(formatDate(client['createdTime'] as Timestamp?))},'
        '${escapeField(client['sessions'])},'
        '${escapeField(client['coins'])},'
        '${escapeField(client['high_score'])},'
        '${escapeField(client['redeemed'])}\n';
  }

  void _downloadCSV(String csvData, String fileName) {
    // Create blob and download link
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
} 