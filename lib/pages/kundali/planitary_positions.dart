import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/config.dart';

class PlanetaryPositionsTab extends StatefulWidget {
  final Map<String, dynamic> matchData;
  final Map<String, dynamic>? cachedData;
  final Function(Map<String, dynamic>) onDataCached;

  const PlanetaryPositionsTab({
    Key? key,
    required this.matchData,
    this.cachedData,
    required this.onDataCached,
  }) : super(key: key);

  @override
  _PlanetaryPositionsTabState createState() => _PlanetaryPositionsTabState();
}

class _PlanetaryPositionsTabState extends State<PlanetaryPositionsTab> {
  Map<String, dynamic>? resultData;
  bool isLoading = false;
  int _selectedPersonIndex = 0; // 0 for boy (p1), 1 for girl (p2)
  Set<String> _expandedPlanets = {}; // Track which planets are expanded

  // Gender colors
  Color get boyColor => Colors.lightBlue.shade100;
  Color get girlColor => Colors.pink.shade100;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didUpdateWidget(PlanetaryPositionsTab oldWidget) {
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
        resultData = widget.cachedData;
        isLoading = false;
      });
    } else {
      // Fetch data if not cached
      _fetchPlanetaryPositions();
    }
  }

  Future<void> _fetchPlanetaryPositions() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('$api/indian-api/match-making/planetary-positions');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(widget.matchData),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        final data = decodedData['data'] as Map<String, dynamic>;

        setState(() {
          resultData = data;
          isLoading = false;
        });

        // Cache the data in parent
        widget.onDataCached(data);
      } else {
        setState(() => isLoading = false);
        _showError('Error fetching planetary positions');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Network error occurred');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Toggle expanded state for a planet
  void _toggleExpanded(String planetId) {
    setState(() {
      if (_expandedPlanets.contains(planetId)) {
        _expandedPlanets.remove(planetId);
      } else {
        _expandedPlanets.add(planetId);
      }
    });
  }

  Widget _buildPlanetCard(Map<String, dynamic> planet) {
    final planetName = planet['name'] as String;
    final planetId = '${planetName}_${_selectedPersonIndex}';
    final isExpanded = _expandedPlanets.contains(planetId);

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: InkWell(
        onTap: () => _toggleExpanded(planetId),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade100,
                    child: Image.network(
                      planet['image']?.toString() ?? '',
                      width: 32,
                      height: 32,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.public, size: 32, color: Colors.grey),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              planetName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sign: ${planet['sign'] ?? 'N/A'} • House: ${planet['house']?.toString() ?? 'N/A'}',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isExpanded) ...[
                Divider(height: 24),
                _buildDetailGrid(planet),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailGrid(Map<String, dynamic> planet) {
    final detailsMap = <String, String>{
      'Sign':
          '${planet['sign'] ?? 'N/A'} (${planet['sign_no']?.toString() ?? 'N/A'})',
      'House': planet['house']?.toString() ?? 'N/A',
      'Nakshatra': planet['nakshatra'] ?? 'N/A',
      'Nakshatra Pada': planet['nakshatra_pada']?.toString() ?? 'N/A',
      'Nakshatra Lord': planet['nakshatra_lord'] ?? 'N/A',
      'Rashi Lord': planet['rashi_lord'] ?? 'N/A',
      'Sub Lord': planet['sub_lord'] ?? 'N/A',
      'Longitude': planet['longitude'] ?? 'N/A',
      'Full Degree': planet['full_degree'] ?? 'N/A',
      'Type': planet['type'] ?? 'N/A',
      'Lord of': planet['lord_of'] ?? 'N/A',
      'Is Retro': planet['is_retro'] ?? 'N/A',
      'Is Combusted': planet['is_combusted'] ?? 'N/A',
      'Speed': planet['speed'] ?? 'N/A',
      'Awastha': planet['awastha'] ?? 'N/A',
      'Karakamsha': planet['karakamsha'] ?? 'N/A',
    };

    // Remove entries with 'N/A' values
    detailsMap.removeWhere((key, value) => value == 'N/A');

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: detailsMap.entries.map((entry) {
        return SizedBox(
          width: MediaQuery.of(context).size.width > 400
              ? MediaQuery.of(context).size.width / 2 - 40
              : MediaQuery.of(context).size.width - 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.key}: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              Expanded(
                child: Text(
                  entry.value,
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPersonSelector() {
    final boyName = widget.matchData['p1_full_name'] as String;
    final girlName = widget.matchData['p2_full_name'] as String;

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedPersonIndex = 0;
                _expandedPlanets.clear(); // Clear expanded state when switching
              }),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      _selectedPersonIndex == 0 ? boyColor : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
                child: Text(
                  boyName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedPersonIndex = 1;
                _expandedPlanets.clear(); // Clear expanded state when switching
              }),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedPersonIndex == 1
                      ? girlColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(12),
                  ),
                ),
                child: Text(
                  girlName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red[900]!),
            ),
            SizedBox(height: 16),
            Text('Loading planetary positions...'),
          ],
        ),
      );
    }

    if (resultData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('No data available'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _fetchPlanetaryPositions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final p1Planets = (resultData!['p1'] as Map<String, dynamic>)['planets']
        as List<dynamic>?;
    final p2Planets = (resultData!['p2'] as Map<String, dynamic>)['planets']
        as List<dynamic>?;

    final boyPlanets = p1Planets ?? [];
    final girlPlanets = p2Planets ?? [];

    final planets = _selectedPersonIndex == 0 ? boyPlanets : girlPlanets;

    // Sort planets to put Ascendant at the top
    final sortedPlanets = List<dynamic>.from(planets);
    sortedPlanets.sort((a, b) {
      if (a['name'] == 'Ascendant') return -1;
      if (b['name'] == 'Ascendant') return 1;
      return 0;
    });

    return Column(
      children: [
        _buildPersonSelector(),
        Padding(
          padding: const EdgeInsets.only(
            left: 10.0,
            right: 8.0,
            top: 8.0,
            bottom: 8.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Planetary Positions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    if (_expandedPlanets.isEmpty) {
                      // Expand all
                      _expandedPlanets = sortedPlanets
                          .map((p) => '${p['name']}_$_selectedPersonIndex')
                          .toSet();
                    } else {
                      // Collapse all
                      _expandedPlanets.clear();
                    }
                  });
                },
                icon: Icon(
                  _expandedPlanets.isEmpty
                      ? Icons.unfold_more
                      : Icons.unfold_less,
                  size: 20,
                  color: Colors.red[900],
                ),
                label: Text(
                  _expandedPlanets.isEmpty ? 'Expand All' : 'Collapse All',
                  style: TextStyle(fontSize: 14, color: Colors.red[900]),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: sortedPlanets.length,
            itemBuilder: (context, index) =>
                _buildPlanetCard(sortedPlanets[index] as Map<String, dynamic>),
          ),
        ),
      ],
    );
  }
}
