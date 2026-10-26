
import 'package:flutter/material.dart';

void main() {
  runApp(const MahalliApp());
}

const green = Color(0xFF087F5B);
const background = Color(0xFFF5F8F5);

class Product {
  final String name;
  final String category;
  final int price;
  final IconData icon;
  final Color color;

  const Product(
    this.name,
    this.category,
    this.price,
    this.icon,
    this.color,
  );
}

const products = [
  Product('سماعات لاسلكية', 'إلكترونيات', 15,
      Icons.headphones, Color(0xFFE4EAFB)),
  Product('حقيبة أنيقة', 'أزياء', 12,
      Icons.shopping_bag, Color(0xFFF9E5D9)),
  Product('ساعة يد', 'إلكترونيات', 20,
      Icons.watch, Color(0xFFE6E0F5)),
  Product('نبات منزلي', 'المنزل', 5,
      Icons.local_florist, Color(0xFFDDF0DF)),
  Product('حذاء رياضي', 'أزياء', 18,
      Icons.directions_run, Color(0xFFFFEBCB)),
  Product('كوب للقهوة', 'المنزل', 4,
      Icons.coffee, Color(0xFFF2E2D5)),
];

class MahalliApp extends StatelessWidget {
  const MahalliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'محلّي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: background,
      ),
      home: const MarketPage(),
    );
  }
}

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final searchController = TextEditingController();
  String selectedCategory = 'الكل';
  int selectedTab = 0;
  final Set<String> favorites = {};
  final Set<String> cart = {};

  final categories = [
    'الكل',
    'إلكترونيات',
    'أزياء',
    'المنزل',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim();

    final visibleProducts = products.where((product) {
      final matchesCategory = selectedCategory == 'الكل' ||
          product.category == selectedCategory;
      final matchesSearch = product.name.contains(query);
      final matchesTab = selectedTab != 1 ||
          favorites.contains(product.name);
      return matchesCategory && matchesSearch && matchesTab;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: background,
          title: const Row(
            children: [
              Icon(Icons.storefront, color: green, size: 30),
              SizedBox(width: 8),
              Text(
                'محلّي',
                style: TextStyle(
                  color: green,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'السلة',
              onPressed: () => setState(() => selectedTab = 2),
              icon: Badge(
                label: Text('${cart.length}'),
                isLabelVisible: cart.isNotEmpty,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: selectedTab == 3
            ? _simplePage(
                Icons.person_outline,
                'حسابي',
                'تسجيل الدخول وإنشاء حساب سنضيفهما لاحقًا.',
              )
            : selectedTab == 2
                ? _cartPage()
                : _marketBody(visibleProducts),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedTab,
          onDestinationSelected: (index) {
            setState(() => selectedTab = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'المفضلة',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart),
              label: 'السلة',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }

  Widget _marketBody(List<Product> visibleProducts) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: green,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سوقك أقرب إليك',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'اكتشف المنتجات والمتاجر من حولك',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              SizedBox(height: 14),
              Icon(
                Icons.storefront,
                color: Colors.white,
                size: 48,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'ابحث عن منتج...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'الأقسام',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ChoiceChip(
                label: Text(category),
                selected: selectedCategory == category,
                selectedColor: const Color(0xFFD7EEE3),
                onSelected: (_) {
                  setState(() => selectedCategory = category);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedTab == 1 ? 'منتجاتك المفضلة' : 'منتجات مميزة',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${visibleProducts.length} منتجات',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visibleProducts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Center(
              child: Text('لا توجد منتجات مطابقة حاليًا'),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 235,
            ),
            itemBuilder: (context, index) {
              final product = visibleProducts[index];
              final isFavorite = favorites.contains(product.name);
              final inCart = cart.contains(product.name);

              return Card(
                color: Colors.white,
                elevation: 1,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: product.color,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  product.icon,
                                  size: 62,
                                  color: green,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                left: 2,
                                child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    setState(() {
                                      if (isFavorite) {
                                        favorites.remove(product.name);
                                      } else {
                                        favorites.add(product.name);
                                      }
                                    });
                                  },
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavorite
                                        ? Colors.red
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        product.category,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${product.price} د.أ',
                              style: const TextStyle(
                                color: green,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          IconButton.filled(
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              setState(() {
                                if (inCart) {
                                  cart.remove(product.name);
                                } else {
                                  cart.add(product.name);
                                }
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    inCart
                                        ? 'أُزيل المنتج من السلة'
                                        : 'أُضيف المنتج إلى السلة',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: Icon(
                              inCart
                                  ? Icons.check
                                  : Icons.add_shopping_cart,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'محلّي — تسوّق من حولك',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _cartPage() {
    final cartProducts = products
        .where((product) => cart.contains(product.name))
        .toList();

    if (cartProducts.isEmpty) {
      return _simplePage(
        Icons.shopping_cart_outlined,
        'سلة المشتريات',
        'سلتك فارغة. أضف منتجات من الرئيسية.',
      );
    }

    final total = cartProducts.fold<int>(
      0,
      (sum, product) => sum + product.price,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'سلة المشتريات',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...cartProducts.map(
          (product) => Card(
            color: Colors.white,
            child: ListTile(
              leading: Icon(product.icon, color: green),
              title: Text(product.name),
              subtitle: Text('${product.price} د.أ'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() => cart.remove(product.name));
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'المجموع: $total د.أ',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'الطلب والدفع غير مفعّلين في هذه النسخة التجريبية.',
        ),
      ],
    );
  }

  Widget _simplePage(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: green),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => setState(() => selectedTab = 0),
              child: const Text('العودة إلى السوق'),
            ),
          ],
        ),
      ),
    );
  }
}
