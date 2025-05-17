// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import 'dart:html' as html;
import 'dart:convert';

class UsersListWidget extends StatefulWidget {
  const UsersListWidget({
    Key? key,
    required this.venueId,
    this.width = 368.0,
    this.height = 600.0,
    this.backgroundColor = const Color(0xFF363740),
    this.textColor = const Color(0xFFFCFDFF),
    this.showPreviewData = false,
  }) : super(key: key);

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
            offset: Offset(-4, 5),
            color: Colors.black.withOpacity(0.25),
            spreadRadius: 0,
            blurRadius: 4,
          ),
        ],
      ),
      padding: EdgeInsets.all(32),
      child: widget.showPreviewData
          ? _buildPreviewList()
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _getVenueClients(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
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
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
                  children: [
                    ...snapshot.data!.map((client) => _buildUserCard(client)),
                    SizedBox(height: 20),
                    _buildDownloadAllButton(),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> client) {
    return Container(
      margin: EdgeInsets.only(bottom: 24, left: 4, right: 4),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(31),
        boxShadow: [
          BoxShadow(
            offset: Offset(-4, 5),
            color: Colors.black.withOpacity(0.25),
            spreadRadius: 0,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Image
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: client['photo_url'] != null
                        ? CachedNetworkImage(
                            imageUrl: client['photo_url'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.person, color: widget.textColor),
                          )
                        : Icon(Icons.person, color: widget.textColor),
                  ),
                ),
                SizedBox(width: 12),
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
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat(
                    'Visits', client['sessions'] ?? 0, Color(0xFF6FA6A0)),
                _buildStat('Coins', client['coins'] ?? 0, Color(0xFFFF8B64)),
                _buildStat(
                    'High Score', client['high_score'] ?? 0, Color(0xFFC5C352)),
                _buildStat(
                    'Redeemed', client['redeemed'] ?? 0, Color(0xFFFF6464)),
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
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 9, vertical: 2),
          decoration: BoxDecoration(
            color: Color(0xFF2B2B2B),
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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              'created_time': Timestamp.fromDate(DateTime.now()),
            });

    return ListView(
      padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
      children: [
        ...previewData.map((client) => _buildUserCard(client)),
        SizedBox(height: 20),
        _buildDownloadAllButton(),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _getVenueClients() async {
    try {
      print('Fetching clients for venue: ${widget.venueId}');

      // Query users who have played in this venue through venueProgress
      final usersQuery = await FirebaseFirestore.instance
          .collectionGroup('venueProgress')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      print(
          'Found ${usersQuery.docs.length} venue progress entries for venue ${widget.venueId}');

      Map<String, Map<String, dynamic>> userStats = {};

      // Collect stats for each user
      for (var doc in usersQuery.docs) {
        final userId = doc.reference.parent.parent!.id;
        final data = doc.data();

        if (!userStats.containsKey(userId)) {
          userStats[userId] = {
            'sessions': 0,
            'coins': 0,
            'high_score': 0,
            'redeemed': 0,
            'created_time': null,
          };
        }

        // Track the earliest created_time
        final currentCreatedTime = data['created_time'] as Timestamp?;
        if (currentCreatedTime != null) {
          final existingCreatedTime =
              userStats[userId]!['created_time'] as Timestamp?;
          if (existingCreatedTime == null ||
              currentCreatedTime.compareTo(existingCreatedTime) < 0) {
            userStats[userId]!['created_time'] = currentCreatedTime;
          }
        }

        userStats[userId]!['sessions'] =
            (userStats[userId]!['sessions'] as int) +
                (data['sessions'] as int? ?? 0);
        userStats[userId]!['coins'] = (userStats[userId]!['coins'] as int) +
            (data['coins'] as int? ?? data['coin'] as int? ?? 0);
        userStats[userId]!['high_score'] = math.max(
            (userStats[userId]!['high_score'] as int),
            (data['highScore'] as int? ?? 0));
        userStats[userId]!['redeemed'] =
            (userStats[userId]!['redeemed'] as int) +
                (data['redeemed'] as int? ?? 0);
      }

      // Fetch user details
      List<Map<String, dynamic>> clients = [];
      for (var entry in userStats.entries) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(entry.key)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          clients.add({
            'display_name': userData['display_name'] ??
                userData['displayName'] ??
                'Unknown',
            'email': userData['email'] ?? '',
            'photo_url': userData['photo_url'] ?? userData['photoUrl'],
            ...entry.value,
          });
        }
      }

      // Sort by sessions in descending order
      clients.sort(
          (a, b) => (b['sessions'] as int).compareTo(a['sessions'] as int));

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

    // Format the created_time
    String formatDate(Timestamp? timestamp) {
      if (timestamp == null) return 'N/A';
      final date = timestamp.toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    return '${escapeField(client['display_name'])},'
        '${escapeField(client['email'])},'
        '${escapeField(formatDate(client['created_time'] as Timestamp?))},'
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