import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/league_provider.dart';
import 'services/league_service.dart';
import 'views/admin_view.dart';
import 'views/auction_view.dart';
import 'views/home_view.dart';
import 'views/match_day_view.dart';
import 'views/player_pool_view.dart';
import 'views/rules_guide_view.dart';

void main() {
  runApp(const CricketLeagueApp());
}

class CricketLeagueApp extends StatefulWidget {
  const CricketLeagueApp({super.key});

  @override
  State<CricketLeagueApp> createState() => _CricketLeagueAppState();
}

class _CricketLeagueAppState extends State<CricketLeagueApp> {
  final LeagueService _leagueService = LeagueService();

  @override
  void dispose() {
    _leagueService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundBg = Color(0xFFF1F5F2);
    const deepEmerald = Color(0xFF0D2A20);
    const goldAccent = Color(0xFFD97706);
    const darkText = Color(0xFF0F172A);

    final poppinsTextTheme = GoogleFonts.poppinsTextTheme(
      ThemeData.light().textTheme.apply(
            bodyColor: darkText,
            displayColor: darkText,
          ),
    );

    return Provider<LeagueService>(
      service: _leagueService,
      child: MaterialApp(
        title: 'Cricket League Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: backgroundBg,
          textTheme: poppinsTextTheme,
          colorScheme: ColorScheme.fromSeed(
            seedColor: deepEmerald,
            primary: deepEmerald,
            secondary: goldAccent,
            surface: Colors.white,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: backgroundBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            iconTheme: const IconThemeData(color: darkText),
            titleTextStyle: GoogleFonts.poppins(
              color: darkText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _views = const [
    HomeView(),
    AuctionView(),
    PlayerPoolView(),
    MatchDayView(),
    AdminView(),
    RulesGuideView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: const Color(0xFF0D2A20).withOpacity(0.12),
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF0D2A20)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.gavel_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.gavel_rounded, color: Color(0xFF0D2A20)),
              label: 'Auction',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.groups_rounded, color: Color(0xFF0D2A20)),
              label: 'Players',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_available_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.event_available_rounded, color: Color(0xFF0D2A20)),
              label: 'Match Day',
            ),
            NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF0D2A20)),
              label: 'Admin',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.menu_book_rounded, color: Color(0xFF0D2A20)),
              label: 'Rules',
            ),
          ],
        ),
      ),
    );
  }
}
