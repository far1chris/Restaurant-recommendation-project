// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'package:restaurant_recommendation/screens/login_screen.dart';
import 'package:restaurant_recommendation/screens/main_layout.dart';
import 'package:restaurant_recommendation/screens/favorite_screen.dart';
import 'package:restaurant_recommendation/screens/community_screen.dart';
import 'package:restaurant_recommendation/screens/map_screen.dart';
import 'package:restaurant_recommendation/screens/myposts_screen.dart';
import 'package:restaurant_recommendation/screens/notification_setting_screen.dart';
import 'package:restaurant_recommendation/screens/profile_setting_screen.dart';
import 'package:restaurant_recommendation/screens/recent_restaurant_screen.dart';
import 'package:restaurant_recommendation/screens/restaurant_detail_screen.dart';
import 'package:restaurant_recommendation/screens/post_detail_screen.dart';
import 'package:restaurant_recommendation/screens/settings_screen.dart';
import 'package:restaurant_recommendation/screens/add_restaurant_screen.dart';
import 'package:restaurant_recommendation/screens/owner_restaurant_screen.dart';
import 'package:restaurant_recommendation/screens/restaurant_editor_screen.dart';
import 'package:restaurant_recommendation/screens/preference_onboarding_screen.dart';
import 'package:restaurant_recommendation/screens/admin_dashboard_screen.dart';

// Models
import 'package:restaurant_recommendation/models/restaurant_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ระบบแนะนำร้านอาหาร',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),

      /// ✅ ใช้ Splash เป็นจุดเริ่ม
      initialRoute: '/',

      /// ✅ หน้าที่เป็น static route เท่านั้น (ที่ไม่ต้องรับ arguments ตอนสร้าง)
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainLayout(),
        '/favorite': (context) => const FavoriteScreen(),
        '/community': (context) => const CommunityScreen(),
        '/map': (context) => const MapScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profileSettings': (context) => const ProfileSettingsScreen(),
        '/notifications': (context) => const NotificationSettingsScreen(),
        '/myPosts': (context) => const MyPostsScreen(),
        '/recentRestaurants': (context) => const RecentRestaurantsScreen(),
        '/addRestaurant': (context) => const AddRestaurantScreen(),
        '/myRestaurants': (context) => const OwnerRestaurantsScreen(),
        '/restaurantEditor': (context) => const RestaurantEditorScreen(),
        '/onboarding': (context) => const PreferenceOnboardingScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
      },

      /// ✅ ใช้ onGenerateRoute สำหรับหน้าที่ต้อง "รับ arguments"
      ///   - /restaurantDetail : คาดหวัง arguments เป็น Restaurant
      ///   - /postDetail       : คาดหวัง arguments เป็น Map<String, dynamic>
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/restaurantDetail':
            {
              final args = settings.arguments;
              // เปิดได้แม่นสุดเมื่อส่ง Restaurant ตรง ๆ (ตามที่ HomeScreen ทำไว้แล้ว)
              if (args is Restaurant) {
                return MaterialPageRoute(
                  builder: (_) => RestaurantDetailScreen(restaurant: args),
                  settings: settings,
                );
              }

              // รองรับกรณีส่ง map เผื่อมาจากหน้าอื่น (ป้องกันพัง)
              if (args is Map) {
                try {
                  // ถ้าส่งเป็น map ของร้านมา
                  final maybe = args['restaurant'] ?? args;
                  if (maybe is Map<String, dynamic>) {
                    final r = Restaurant.fromJson(maybe);
                    return MaterialPageRoute(
                      builder: (_) => RestaurantDetailScreen(restaurant: r),
                      settings: settings,
                    );
                  }
                } catch (_) {}
              }

              // ถ้ารูปแบบไม่ตรง ให้แจ้งเตือนอย่างสุภาพ
              return MaterialPageRoute(
                builder: (_) => const _BadArgumentPage(
                  title: 'เปิดรายละเอียดร้านไม่สำเร็จ',
                  detail:
                      'รูปแบบข้อมูลที่ส่งมาไม่ถูกต้อง ควรส่งเป็นวัตถุ Restaurant ผ่าน arguments',
                ),
                settings: settings,
              );
            }

          case '/postDetail':
            {
              final args = settings.arguments;
              if (args is Map<String, dynamic>) {
                return MaterialPageRoute(
                  builder: (_) => PostDetailScreen(
                    username: args['username'],
                    content: args['content'],
                  ),
                  settings: settings,
                );
              }
              return MaterialPageRoute(
                builder: (_) => const _BadArgumentPage(
                  title: 'เปิดโพสต์ไม่สำเร็จ',
                  detail:
                      'รูปแบบข้อมูลที่ส่งมาไม่ถูกต้อง ควรส่งเป็น Map<String, dynamic> ที่มีค่า username และ content',
                ),
                settings: settings,
              );
            }
        }

        // ไม่รู้จัก route
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('ไม่พบหน้านี้'))),
          settings: settings,
        );
      },

      /// ✅ กันเหนียว: ถ้ามีการเรียกชื่อ route แปลก ๆ ที่ไม่เข้าเงื่อนไขข้างบน
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) =>
            const Scaffold(body: Center(child: Text('ไม่พบหน้านี้'))),
        settings: settings,
      ),
    );
  }
}

/// ✅ SplashScreen เพื่อตรวจสอบสถานะล็อกอิน/Onboarding
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final done = prefs.getBool('pref_done') ?? false;

    // ทำให้มีเอฟเฟ็กต์ splash เล็กน้อย
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    if (userId != null && userId > 0) {
      if (!done) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// ✅ หน้าบอกเหตุผลเวลา arguments ไม่ถูกต้อง เพื่อ debug ง่ายขึ้น
class _BadArgumentPage extends StatelessWidget {
  final String title;
  final String detail;

  const _BadArgumentPage({
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เกิดข้อผิดพลาด')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 72, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              style: TextStyle(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('ย้อนกลับ'),
            ),
          ],
        ),
      ),
    );
  }
}
