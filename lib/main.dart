import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const MahalliApp());

const green = Color(0xFF087F5B);
const categories = ['إلكترونيات', 'أزياء', 'المنزل', 'أخرى'];

class Product {
  final String name;
  final String category;
  final String description;
  final String size;
  final String colorName;
  final int price;
  final String? imagePath;

  const Product({
    required this.name,
    required this.category,
    required this.price,
    this.description = '',
    this.size = '',
    this.colorName = 'غير محدد',
    this.imagePath,
  });
}

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
        scaffoldBackgroundColor: const Color(0xFFF5F8F5),
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
  int tab = 0;
  String search = '';
  String category = 'الكل';

  final ImagePicker picker = ImagePicker();
  final Set<String> favorites = {};
  final Set<String> cart = {};

  final List<Product> products = [
    const Product(
      name: 'سماعات لاسلكية',
      category: 'إلكترونيات',
      price: 15,
    ),
    const Product(
      name: 'حقيبة أنيقة',
      category: 'أزياء',
      price: 12,
    ),
    const Product(
      name: 'ساعة يد',
      category: 'إلكترونيات',
      price: 20,
    ),
    const Product(
      name: 'نبات منزلي',
      category: 'المنزل',
      price: 5,
    ),
  ];

  Future<String?> _pickImage() async {
    try {
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      return file?.path;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح معرض الصور. حاول مرة أخرى.'),
          ),
        );
      }
      return null;
    }
  }

  Widget _productImage(Product product, {double iconSize = 58}) {
    final path = product.imagePath;

    if (path != null && File(path).existsSync()) {
      return Image.file(
        File(path),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(iconSize),
      );
    }

    return _imagePlaceholder(iconSize);
  }

  Widget _imagePlaceholder(double iconSize) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFDDF0DF),
      child: Icon(
        Icons.add_a_photo_outlined,
        size: iconSize,
        color: green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = products.where((p) {
      final matchesSearch =
          p.name.contains(search) || p.category.contains(search);
      final matchesCategory =
          category == 'الكل' || p.category == category;
      final matchesTab = tab != 1 || favorites.contains(p.name);
      return matchesSearch && matchesCategory && matchesTab;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'محلّي',
            style: TextStyle(
              color: green,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => setState(() => tab = 2),
              icon: Badge(
                isLabelVisible: cart.isNotEmpty,
                label: Text('${cart.length}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
          ],
        ),
        body: switch (tab) {
          0 || 1 => _market(shown),
          2 => _cartPage(),
          3 => _messagePage(
              Icons.person_outline,
              'حسابي',
              'سنضيف تسجيل الدخول وإنشاء الحساب لاحقًا.',
            ),
          4 => _storePage(),
          _ => const SizedBox.shrink(),
        },
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) => setState(() => tab = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              label: 'المفضلة',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              label: 'السلة',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'حسابي',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              label: 'متجري',
            ),
          ],
        ),
      ),
    );
  }

  Widget _market(List<Product> shown) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: green,
            borderRadius: BorderRadius.circular(20),
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
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) => setState(() => search = value.trim()),
          decoration: InputDecoration(
            hintText: 'ابحث عن منتج...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'الأقسام',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 45,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ['الكل', ...categories].map((c) {
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: category == c,
                  onSelected: (_) => setState(() => category = c),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          tab == 1 ? 'المفضلة' : 'المنتجات',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (shown.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('لا توجد منتجات هنا بعد')),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shown.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 235,
            ),
            itemBuilder: (context, index) {
              final p = shown[index];
              final fav = favorites.contains(p.name);
              final added = cart.contains(p.name);

              return Card(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _productImage(p),
                              Positioned(
                                top: 0,
                                left: 0,
                                child: IconButton(
                                  onPressed: () => setState(() {
                                    fav
                                        ? favorites.remove(p.name)
                                        : favorites.add(p.name);
                                  }),
                                  icon: Icon(
                                    fav
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: fav ? Colors.red : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        p.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${p.price} د.أ',
                              style: const TextStyle(
                                color: green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() {
                              added ? cart.remove(p.name) : cart.add(p.name);
                            }),
                            icon: Icon(
                              added
                                  ? Icons.check_circle
                                  : Icons.add_shopping_cart,
                              color: green,
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
      ],
    );
  }

  Widget _storePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'إدارة متجري',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('أضف منتجاتك وصورها لتظهر في السوق على هذا الجهاز.'),
        const SizedBox(height: 18),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: green,
            padding: const EdgeInsets.all(16),
          ),
          onPressed: _addProduct,
          icon: const Icon(Icons.add),
          label: const Text('إضافة منتج جديد'),
        ),
        const SizedBox(height: 20),
        Text(
          'المنتجات (${products.length})',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...products.map(
          (p) => Card(
            color: Colors.white,
            child: ListTile(
              leading: SizedBox(
                width: 54,
                height: 54,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _productImage(p, iconSize: 28),
                ),
              ),
              title: Text(p.name),
              subtitle: Text('${p.category} • ${p.price} د.أ'),
              trailing: IconButton(
                tooltip: 'حذف المنتج',
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => setState(() {
                  products.remove(p);
                  favorites.remove(p.name);
                  cart.remove(p.name);
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'ملاحظة: هذه نسخة تجريبية؛ المنتجات لا تُحفظ بعد إغلاق التطبيق.',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _addProduct() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final price = TextEditingController();
    final description = TextEditingController();
    final size = TextEditingController();
    final colorName = TextEditingController();

    String selectedCategory = categories.first;
    String? selectedImage;

    final product = await showDialog<Product>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refreshDialog) => AlertDialog(
          title: const Text('إضافة منتج'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () async {
                        final path = await _pickImage();
                        if (path != null) {
                          refreshDialog(() => selectedImage = path);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDF0DF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: green),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: selectedImage == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 45,
                                    color: green,
                                  ),
                                  SizedBox(height: 8),
                                  Text('اضغط لاختيار صورة المنتج'),
                                ],
                              )
                            : Image.file(
                                File(selectedImage!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) =>
                                    const Center(
                                  child: Text('تعذر عرض الصورة'),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'اسم المنتج *',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'أدخل اسم المنتج'
                              : null,
                    ),
                    TextFormField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'السعر بالدينار الأردني *',
                      ),
                      validator: (v) {
                        final value = int.tryParse(v ?? '');
                        return value == null || value <= 0
                            ? 'أدخل سعرًا صحيحًا'
                            : null;
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'التصنيف'),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          refreshDialog(() => selectedCategory = v);
                        }
                      },
                    ),
                    TextFormField(
                      controller: description,
                      decoration: const InputDecoration(labelText: 'الوصف'),
                    ),
                    TextFormField(
                      controller: size,
                      decoration: const InputDecoration(
                        labelText: 'الحجم أو المقاس',
                      ),
                    ),
                    TextFormField(
                      controller: colorName,
                      decoration: const InputDecoration(labelText: 'اللون'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                Navigator.pop(
                  dialogContext,
                  Product(
                    name: name.text.trim(),
                    category: selectedCategory,
                    price: int.parse(price.text),
                    description: description.text.trim(),
                    size: size.text.trim(),
                    colorName: colorName.text.trim().isEmpty
                        ? 'غير محدد'
                        : colorName.text.trim(),
                    imagePath: selectedImage,
                  ),
                );
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    price.dispose();
    description.dispose();
    size.dispose();
    colorName.dispose();

    if (product != null && mounted) {
      setState(() {
        products.insert(0, product);
        tab = 4;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة المنتج إلى السوق')),
      );
    }
  }

  Widget _cartPage() {
    final items = products.where((p) => cart.contains(p.name)).toList();

    if (items.isEmpty) {
      return _messagePage(
        Icons.shopping_cart_outlined,
        'سلة المشتريات',
        'سلتك فارغة. أضف منتجات من السوق.',
      );
    }

    final total = items.fold<int>(0, (sum, p) => sum + p.price);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'سلة المشتريات',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        ...items.map(
          (p) => Card(
            child: ListTile(
              leading: SizedBox(
                width: 48,
                height: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _productImage(p, iconSize: 24),
                ),
              ),
              title: Text(p.name),
              subtitle: Text('${p.price} د.أ'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => cart.remove(p.name)),
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
        const Text('إتمام الطلب والدفع غير مفعّلين بعد.'),
      ],
    );
  }

  Widget _messagePage(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 70, color: green),
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
          ],
        ),
      ),
    );
  }
}
