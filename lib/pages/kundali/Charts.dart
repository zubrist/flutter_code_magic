import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saamay/pages/config.dart';

class HoroscopeChartsTab extends StatefulWidget {
  final Map<String, dynamic> matchData;
  final Map<String, dynamic>? cachedData;
  final Function(Map<String, dynamic>) onDataCached;

  const HoroscopeChartsTab({
    Key? key,
    required this.matchData,
    this.cachedData,
    required this.onDataCached,
  }) : super(key: key);

  @override
  _HoroscopeChartsTabState createState() => _HoroscopeChartsTabState();
}

class _HoroscopeChartsTabState extends State<HoroscopeChartsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? chartData;
  bool isLoading = false;
  String? currentChartType;
  Map<String, Map<String, dynamic>> chartDataCache = {};

  final List<Map<String, String>> charts = [
    {'value': 'chalit', 'label': 'Chalit'},
    {'value': 'MOON', 'label': 'Moon'},
    {'value': 'SUN', 'label': 'Sun'},
    {'value': 'D2', 'label': 'D2'},
    {'value': 'D3', 'label': 'D3'},
    {'value': 'D4', 'label': 'D4'},
    {'value': 'D7', 'label': 'D7'},
    {'value': 'D10', 'label': 'D10'},
    {'value': 'D12', 'label': 'D12'},
    {'value': 'D16', 'label': 'D16'},
    {'value': 'D20', 'label': 'D20'},
    {'value': 'D24', 'label': 'D24'},
    {'value': 'D27', 'label': 'D27'},
    {'value': 'D30', 'label': 'D30'},
    {'value': 'D40', 'label': 'D40'},
    {'value': 'D45', 'label': 'D45'},
    {'value': 'D60', 'label': 'D60'},
    {'value': 'cuspal', 'label': 'Cuspal'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: charts.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    currentChartType = charts[0]['value']!;
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HoroscopeChartsTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if we need to update data when widget changes
    if (widget.cachedData != oldWidget.cachedData) {
      _initializeData();
    }
  }

  void _initializeData() {
    if (widget.cachedData != null) {
      // Use cached data if available
      setState(() {
        chartDataCache = Map<String, Map<String, dynamic>>.from(
          widget.cachedData!.map(
            (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
          ),
        );
        isLoading = false;
      });
      // Load the current chart if available
      if (currentChartType != null &&
          chartDataCache.containsKey(currentChartType!)) {
        // Chart data is already available from cache
      } else if (currentChartType != null) {
        _fetchChartData(currentChartType!);
      }
    } else {
      // Fetch initial chart data if not cached
      if (currentChartType != null) {
        _fetchChartData(currentChartType!);
      }
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      final newChartType = charts[_tabController.index]['value']!;
      currentChartType = newChartType;

      // Check if we already have this chart data cached
      if (chartDataCache.containsKey(newChartType)) {
        // Data already available, no need to fetch
        setState(() {
          // Trigger rebuild to show cached data
        });
      } else {
        // Fetch new chart data
        _fetchChartData(newChartType);
      }
    }
  }

  Future<void> _fetchChartData(String chartType) async {
    // Check if we already have this data cached
    if (chartDataCache.containsKey(chartType)) {
      setState(() {
        currentChartType = chartType;
      });
      return;
    }

    setState(() {
      isLoading = true;
      currentChartType = chartType;
    });

    try {
      final response = await http.put(
        Uri.parse('$api/indian-api/match-making/horoscope-chart:$chartType'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(widget.matchData),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          chartDataCache[chartType] = decodedData;
          isLoading = false;
        });

        // Cache the updated data in parent
        widget.onDataCached(chartDataCache);
      } else {
        setState(() => isLoading = false);
        _showError('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Network error occurred: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildChartCard(
    String personName,
    Map<String, dynamic> data,
    Color cardColor,
  ) {
    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: cardColor.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                personName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cardColor.withOpacity(0.8),
                ),
              ),
            ),
            if (data['svg'] != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SvgPicture.string(data['svg'], width: 300, height: 300),
              ),
            const SizedBox(height: 16),
            //_buildPlanetList(data['data']),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanetList(Map<String, dynamic>? planetData) {
    if (planetData == null) return const SizedBox.shrink();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: planetData.length,
      itemBuilder: (context, index) {
        final house = planetData[(index + 1).toString()];
        if (house == null || house['planet'] == null)
          return const SizedBox.shrink();

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text('House ${index + 1}'),
            subtitle: Text(
              (house['planet'] as List)
                  .map((p) => p['name'].toString())
                  .join(', '),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentChartData =
        currentChartType != null ? chartDataCache[currentChartType!] : null;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.red[900],
          indicatorColor: Colors.red[900],
          indicatorWeight: 3.0,
          unselectedLabelColor: Colors.grey,
          tabs: charts.map((chart) => Tab(text: chart['label'])).toList(),
        ),
        Expanded(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red[900]!),
                  ),
                )
              : currentChartData != null
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildChartCard(
                            '${widget.matchData['p1_full_name']}',
                            currentChartData['data']['p1'],
                            const Color.fromARGB(255, 47, 33, 243),
                          ),
                          _buildChartCard(
                            '${widget.matchData['p2_full_name']}',
                            currentChartData['data']['p2'],
                            const Color.fromARGB(255, 233, 30, 30),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('No chart data available'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (currentChartType != null) {
                                // Remove from cache and refetch
                                chartDataCache.remove(currentChartType!);
                                _fetchChartData(currentChartType!);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[900],
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Retry',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}
