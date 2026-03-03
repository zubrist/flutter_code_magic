import 'package:flutter/material.dart';
import 'package:saamay/pages/HomeScreen.dart';
import 'package:saamay/pages/astrologers.dart';
import 'package:saamay/pages/walletTransactions.dart';
import 'package:google_fonts/google_fonts.dart';

class NavigationPage extends StatefulWidget {
  @override
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int _selectedIndex = 0;
  PageController _pageController = PageController();

  final List<Widget> _pages = [
    HomeScreen(),
    AstrologersPage(title: "All"),
    WalletPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bottom Navigation Demo')),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Page 1'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Page 2'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Page 3'),
        ],
      ),
    );
  }
}
