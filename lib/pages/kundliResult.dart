import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/kundali/BasicAstro.dart';
import 'package:saamay/pages/kundali/AstakootMilan.dart';
import 'package:saamay/pages/kundali/Charts.dart';
import 'package:saamay/pages/kundali/DashkootMilan.dart';
import 'package:saamay/pages/kundali/ManglikDasha.dart';
import 'package:saamay/pages/kundali/Nav_panchamyoga.dart';
import 'package:saamay/pages/kundali/VimshottariDasha.dart';
import 'package:saamay/pages/kundali/planitary_positions.dart';

class KundliMatchingResult extends StatefulWidget {
  final Map<String, dynamic> matchData;
  const KundliMatchingResult({Key? key, required this.matchData})
      : super(key: key);

  @override
  _KundliMatchingResultState createState() => _KundliMatchingResultState();
}

class _KundliMatchingResultState extends State<KundliMatchingResult>
    with SingleTickerProviderStateMixin {
  // Custom gradient for buttons and headers
  final Gradient _customGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF89216B), Color(0xFFDA4453), // #AE0074
    ],
  );

  late TabController _tabController;
  String _selectedLanguage = 'hi'; // Default language is Hindi
  Map<String, dynamic> _updatedMatchData = {};
  Key _tabContentKey = UniqueKey(); // Add a key to force refresh of tab content

  // Add cache for tab data
  Map<String, Map<String, dynamic>?> _tabDataCache = {
    'basicAstro': null,
    'ashtakoot': null,
    'planetary': null,
    'charts': null,
    'vimshottari': null,
    'manglik': null,
    'dashakoot': null,
    'navPancham': null,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _updatedMatchData = Map.from(widget.matchData);
    _selectedLanguage = widget.matchData['lan'] ?? 'hi';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
      _updatedMatchData = Map.from(widget.matchData);
      _updatedMatchData['lan'] = language;

      // Clear cache when language changes so tabs will refetch with new language
      _tabDataCache.updateAll((key, value) => null);

      _tabContentKey = UniqueKey(); // Generate a new key to force refresh
    });
  }

  void updateTabCache(String tabKey, Map<String, dynamic> data) {
    setState(() {
      _tabDataCache[tabKey] = data;
    });
  }

  Map<String, dynamic>? getTabCache(String tabKey) {
    return _tabDataCache[tabKey];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7EF),
      appBar: AppBar(
        title: Text(
          'Kundli Matching Result',
          style: GoogleFonts.lora(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: _customGradient),
        ),
      ),
      body: Column(
        children: [
          // Language Selection Radio Buttons
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  'Language:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red[900],
                  ),
                ),
                SizedBox(width: 16),
                Radio<String>(
                  value: 'hi',
                  groupValue: _selectedLanguage,
                  activeColor: Colors.red[900],
                  onChanged: (value) {
                    if (value != null) {
                      _updateLanguage(value);
                    }
                  },
                ),
                Text('Hindi', style: GoogleFonts.poppins(color: Colors.black)),
                SizedBox(width: 16),
                Radio<String>(
                  value: 'en',
                  groupValue: _selectedLanguage,
                  activeColor: Colors.red[900],
                  onChanged: (value) {
                    if (value != null) {
                      _updateLanguage(value);
                    }
                  },
                ),
                Text(
                  'English',
                  style: GoogleFonts.poppins(color: Colors.black),
                ),
              ],
            ),
          ),

          // TabBar
          Container(
            color: const Color(0xFFFCF7EF),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.red[900],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.red[900],
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              unselectedLabelStyle: GoogleFonts.poppins(),
              tabs: const [
                Tab(text: 'Basic Astro Details'),
                Tab(text: 'Ashtakoot Milan'),
                Tab(text: 'Planetary Positions'),
                Tab(text: 'Horoscope Charts'),
                Tab(text: 'Vimshottari Dasha'),
                Tab(text: 'Manglik Dosha'),
                Tab(text: 'Dashakoot Milan'),
                Tab(text: 'Nav Pancham Yoga'),
              ],
            ),
          ),

          // TabBarView with a KeyedSubtree to force refresh
          Expanded(
            child: KeyedSubtree(
              key:
                  _tabContentKey, // This key will force a rebuild when language changes
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Each tab is responsible for its own data fetching
                  BasicAstroTab(
                    matchData: _updatedMatchData,
                    cachedData: _tabDataCache['basicAstro'],
                    onDataCached: (data) => updateTabCache('basicAstro', data),
                  ),
                  AshtakootMilanTab(
                    matchData: _updatedMatchData,
                    cachedData: _tabDataCache['ashtakoot'],
                    onDataCached: (data) => updateTabCache('ashtakoot', data),
                  ),
                  PlanetaryPositionsTab(
                    matchData: _updatedMatchData,
                    cachedData: _tabDataCache['planetary'],
                    onDataCached: (data) => updateTabCache('planetary', data),
                  ),
                  HoroscopeChartsTab(
                    matchData: _updatedMatchData,
                    cachedData: _tabDataCache['charts'],
                    onDataCached: (data) => updateTabCache('charts', data),
                  ),
                  VimshottariDashaTab(
                    matchData: _updatedMatchData,
                    cachedData: _tabDataCache['vimshottari'],
                    onDataCached: (data) => updateTabCache('vimshottari', data),
                  ),
                  ManglikDoshaTab(
                    matchData: _updatedMatchData,
                    cachedData: _tabDataCache['manglik'],
                    onDataCached: (data) => updateTabCache('manglik', data),
                  ),
                  DashakootMilanTab(
                    matchData: _updatedMatchData,
                    cachedData: _tabDataCache['dashakoot'],
                    onDataCached: (data) => updateTabCache('dashakoot', data),
                  ),
                  NavaPanchamYogaTab(
                    matchData: _updatedMatchData,
                    cachedData: _tabDataCache['navPancham'],
                    onDataCached: (data) => updateTabCache('navPancham', data),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
