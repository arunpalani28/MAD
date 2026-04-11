import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../models/product.dart';
import '../services/product_api.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  late final ScrollController _scrollController;
  late final PageController _bannerController;
  late final AnimationController _waveController;
  Timer? _bannerTimer;

  List<Product> products = [];
  bool isLoading = false;
  int currentBanner = 0;
  String selectedCategory = "All";
  String currentAddress = "Fetching location...";

  final List<Map<String, String>> ads = [
    {
      "image":
          "https://images.unsplash.com/photo-1440428099904-c6d459a7e7b5?auto=format&fit=crop&w=800&q=80",
      "url": "https://google.com"
    },
    {
      "image":
          "https://plus.unsplash.com/premium_photo-1661962510497-9505129083fa?auto=format&fit=crop&w=800&q=80",
      "url": "https://youtube.com"
    },
  ];

  final List<Map<String, dynamic>> categories = [
    {"title": "All", "icon": Icons.apps},
    {"title": "Milk", "icon": Icons.local_drink},
    {"title": "Curd", "icon": Icons.bakery_dining},
    {"title": "Paneer", "icon": Icons.square},
    {"title": "Butter", "icon": Icons.circle},
    {"title": "Ghee", "icon": Icons.brightness_5},
  ];

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _bannerController = PageController(viewportFraction: 0.92);
    _waveController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat(reverse: true);

    _fetchProducts();
    _determinePosition();

    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      currentBanner = (currentBanner + 1) % ads.length;
      _bannerController.animateToPage(
        currentBanner,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final result = await ProductApi.fetchProducts(selectedCategory);
      if (!mounted) return;
      setState(() => products = result);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _determinePosition() async {
    if (kIsWeb) return;

    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    Position pos = await Geolocator.getCurrentPosition();
    List<Placemark> placemarks =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);

    if (!mounted) return;
    setState(() {
      currentAddress =
          "${placemarks.first.locality}, ${placemarks.first.administrativeArea}";
    });
  }

  Future<void> _openLink(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _scrollController.dispose();
    _bannerController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF81D4FA),
                    Color(0xFF0288D1),
                  ],
                ),
              ),
            ),
          ),
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader()),
                      isLoading
                          ? const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                            )
                          : _buildGrid(),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAds(),
            const SizedBox(height: 16),
            _buildCategories(),
          ],
        ),
      );

  Widget _buildGrid() => SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childCount: products.length,
          itemBuilder: (_, i) => ProductCard(
            product: products[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProductDetailsScreen(product: products[i]),
              ),
            ),
          ),
        ),
      );

  Widget _buildTopBar() => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.location_on),
            const SizedBox(width: 8),
            Text(currentAddress),
          ],
        ),
      );

  Widget _buildAds() => Column(
        children: [
          SizedBox(
            height: 170,
            child: PageView.builder(
              controller: _bannerController,
              itemCount: ads.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _openLink(ads[i]["url"]!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    ads[i]["image"]!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SmoothPageIndicator(
            controller: _bannerController,
            count: ads.length,
          ),
        ],
      );

  Widget _buildCategories() => SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (_, i) {
            final c = categories[i];
            final selected = c["title"] == selectedCategory;

            return GestureDetector(
              onTap: () {
                setState(() => selectedCategory = c["title"]);
                _fetchProducts();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Icon(
                      c["icon"],
                      color:
                          selected ? Colors.white : AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      c["title"],
                      style: TextStyle(
                        color:
                            selected ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _buildBackground() => Positioned.fill(
        child: AnimatedBuilder(
          animation: _waveController,
          builder: (_, __) => CustomPaint(
            painter: BlueWavePainter(_waveController.value),
          ),
        ),
      );
}

class BlueWavePainter extends CustomPainter {
  final double animationValue;
  BlueWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFFFF8E7).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = const Color(0xFFFFF8E7).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    _drawWave(canvas, size, paint1, animationValue, 30.0, 20.0);
    _drawWave(canvas, size, paint2, animationValue, 50.0, 15.0);
  }

  void _drawWave(Canvas canvas, Size size, Paint paint, double anim,
      double offsetY, double amplitude) {
    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i <= size.width; i++) {
      final y = size.height * 0.5 +
          amplitude *
              sin(i / size.width * 2 * pi + anim * 2 * pi) +
          offsetY;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BlueWavePainter oldDelegate) => true;
}
