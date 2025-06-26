// Automatic FlutterFlow imports
// Imports other custom widgets
// Imports custom actions
// Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Imports other custom widgets
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/responsive_helper.dart';

class FeatureUsageHeatmapWidget extends StatefulWidget {
  const FeatureUsageHeatmapWidget({
    super.key,
    required this.venueId,
    this.width,
    this.height,
    this.backgroundColor = const Color(0xFF363740),
    this.textColor = const Color(0xFFFCFDFF),
    this.highUsageColor = const Color(0xFFF24738),
    this.mediumUsageColor = const Color(0xFFFF9800),
    this.lowUsageColor = const Color(0xFF6FA6A0),
    this.showPreviewData = false,
  });

  final String venueId;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color textColor;
  final Color highUsageColor;
  final Color mediumUsageColor;
  final Color lowUsageColor;
  final bool showPreviewData;

  @override
  _FeatureUsageHeatmapWidgetState createState() => _FeatureUsageHeatmapWidgetState();
}

class _FeatureUsageHeatmapWidgetState extends State<FeatureUsageHeatmapWidget> {
  Map<String, int> _featureUsage = {};
  Map<String, int> _buttonClicks = {};
  bool _isLoading = true;
  bool _showInfo = false;
  int _totalInteractions = 0;

  @override
  void initState() {
    super.initState();
    _loadFeatureData();
  }

  @override
  void didUpdateWidget(FeatureUsageHeatmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venueId != widget.venueId) {
      _loadFeatureData();
    }
  }

  Future<void> _loadFeatureData() async {
    if (widget.venueId.isEmpty) {
      setState(() {
        _featureUsage = {};
        _buttonClicks = {};
        _totalInteractions = 0;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('FeatureUsageHeatmapWidget: Loading feature data for venue: ${widget.venueId}');
      
      // Query userVenueProgress for this venue
      final userVenueProgressQuery = await FirebaseFirestore.instance
          .collection('userVenueProgress')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      Map<String, int> featureUsage = {};
      Map<String, int> buttonClicks = {};
      int totalInteractions = 0;

      for (var doc in userVenueProgressQuery.docs) {
        final data = doc.data();
        final sessionMap = data['sessionMap'] as Map<String, dynamic>?;
        
        if (sessionMap != null) {
          // Process each session in the sessionMap
          for (var sessionEntry in sessionMap.entries) {
            final sessionData = sessionEntry.value as Map<String, dynamic>?;
            if (sessionData == null) continue;

            final events = sessionData['events'] as List<dynamic>?;
            if (events == null) continue;

            // Process events to count feature usage and button clicks
            for (var event in events) {
              if (event is Map<String, dynamic>) {
                final eventType = event['type'] as String?;
                totalInteractions++;

                if (eventType == 'feature_used') {
                  final feature = event['feature'] as String?;
                  if (feature != null) {
                    featureUsage[feature] = (featureUsage[feature] ?? 0) + 1;
                  }
                } else if (eventType == 'button_click') {
                  final buttonId = event['buttonId'] as String?;
                  if (buttonId != null) {
                    buttonClicks[buttonId] = (buttonClicks[buttonId] ?? 0) + 1;
                  }
                }
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _featureUsage = featureUsage;
          _buttonClicks = buttonClicks;
          _totalInteractions = totalInteractions;
          _isLoading = false;
        });
      }

      print('FeatureUsageHeatmapWidget: Updated feature data - Features: ${featureUsage.length}, Buttons: ${buttonClicks.length}, Total: $totalInteractions');
    } catch (e) {
      print('FeatureUsageHeatmapWidget: Error loading feature data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getUsageColor(int usage) {
    if (_totalInteractions == 0) return widget.lowUsageColor;
    
    final percentage = (usage / _totalInteractions) * 100;
    if (percentage >= 20) return widget.highUsageColor;
    if (percentage >= 10) return widget.mediumUsageColor;
    return widget.lowUsageColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minWidth: 300,
      ),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(31.0),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(32.0, 32.0, 32.0, 32.0),
            child: _showInfo ? _buildInfoView() : _buildDataView(),
          ),
          // Info/Close button
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showInfo = !_showInfo;
                });
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.textColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _showInfo ? Icons.close : Icons.info_outline,
                  color: widget.textColor.withOpacity(0.7),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
          child: Text(
            'Feature Usage',
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: widget.textColor,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_totalInteractions == 0)
          Text(
            'No feature usage data available',
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: widget.textColor.withOpacity(0.7),
              fontSize: 14.0,
            ),
          )
        else ...[
          // Total interactions
          _buildMetricSection(
            'Total Interactions',
            _totalInteractions.toString(),
            widget.textColor.withOpacity(0.8),
          ),
          const SizedBox(height: 16),

          // Top features
          if (_featureUsage.isNotEmpty) ...[
            Text(
              'Top Features',
              style: TextStyle(
                fontFamily: 'Roboto Flex',
                color: widget.textColor,
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ..._getTopItems(_featureUsage, 3).map((item) => _buildUsageItem(item.key, item.value)),
          ],

          const SizedBox(height: 16),

          // Top buttons
          if (_buttonClicks.isNotEmpty) ...[
            Text(
              'Top Buttons',
              style: TextStyle(
                fontFamily: 'Roboto Flex',
                color: widget.textColor,
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ..._getTopItems(_buttonClicks, 3).map((item) => _buildUsageItem(item.key, item.value)),
          ],
        ],
      ],
    );
  }

  Widget _buildInfoView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Usage Heatmap',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'This widget analyzes user interaction patterns:',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor.withOpacity(0.9),
            fontSize: 14.0,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem('Total Interactions', 'All button clicks and feature usage events'),
        _buildInfoItem('Top Features', 'Most used app features (wallet, offers, etc.)'),
        _buildInfoItem('Top Buttons', 'Most clicked buttons and interface elements'),
        const SizedBox(height: 12),
        Text(
          'Color coding:',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor,
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildColorLegend(widget.highUsageColor, '20%+ usage'),
            const SizedBox(width: 16),
            _buildColorLegend(widget.mediumUsageColor, '10-20% usage'),
            const SizedBox(width: 16),
            _buildColorLegend(widget.lowUsageColor, '<10% usage'),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Data is collected from user session tracking and updates automatically as users interact with your venue page.',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor.withOpacity(0.7),
            fontSize: 12.0,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildColorLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor.withOpacity(0.8),
            fontSize: 10.0,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: widget.textColor.withOpacity(0.7),
              fontSize: 14.0,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontFamily: 'Roboto Flex',
                      color: widget.textColor,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: TextStyle(
                      fontFamily: 'Roboto Flex',
                      color: widget.textColor.withOpacity(0.8),
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageItem(String name, int count) {
    final percentage = _totalInteractions > 0 ? (count / _totalInteractions * 100) : 0.0;
    final color = _getUsageColor(count);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontFamily: 'Roboto Flex',
                color: widget.textColor,
                fontSize: 14.0,
              ),
            ),
          ),
          Text(
            '$count (${percentage.toStringAsFixed(1)}%)',
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: color,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSection(String label, String value, Color valueColor) {
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    final valueFontSize = isLargeScreen ? 18.0 : 18.0;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: widget.textColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: valueColor,
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, int>> _getTopItems(Map<String, int> items, int count) {
    final sortedItems = items.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedItems.take(count).toList();
  }
} 