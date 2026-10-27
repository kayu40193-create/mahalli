import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();

await Supabase.initialize(
url: 'https://dmlvymwzsmbzfxgqyafx.supabase.co',
anonKey: 'sb_publishable_CiJl0yHA-MI24qCo-BKeDg_BNqPt5Na',
);

runApp(const MahalliApp());
}

const green = Color(0xFF087F5B);
const categories = ['إلكترونيات', 'أزياء', 'المنزل', 'أخرى'];

Future<List<Map<String, dynamic>>> fetchProductsFromSupabase() async {
final data = await Supabase.instance.client
.from('products')
.select()
.order('created_at', ascending: false);
return List<Map<String, dynamic>>.from(data);
}

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

Map<String, dynamic> toJson() => {
'name': name,
'category': category,
'description': description,
'size': size,
'colorName': colorName,
'price': price,
'imagePath': imagePath,
};

factory Product.fromJson(Map<String, dynamic> json) => Product(
name: json['name'] as String? ?? '',
category: json['category'] as String? ?? 'أخرى',
description: json['description'] as String? ?? '',
size: json['size'] as String? ?? '',
colorName: json['colorName'] as String? ?? 'غير محدد',
price: (json['price'] as num?)?.toInt() ?? 0,
imagePath: json['imagePath'] as String?,
);
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
bool loading = true;
String? loadError;

final ImagePicker picker = ImagePicker();
final Set<String> favorites = {};
final Map<String, int> cart = {};
List<Product> products = [];

@override
void initState() {
super.initState();
_loadData();
}

int get cartCount =>
cart.values.fold<int>(0, (sum, quantity) => sum + quantity);

int get cartTotal {
int total = 0;
for (final product in products) {
total += product.price * (cart[product.name] ?? 0);
}
return total;
}

Future<void> _loadData() async {
try {
final prefs = await SharedPreferences.getInstance();
final savedProducts = prefs.getString('mahalli_products');
final savedFavorites = prefs.getStringList('mahalli_favorites');
final savedCart = prefs.getString('mahalli_cart');

if (savedProducts != null) {  
    final decoded = jsonDecode(savedProducts) as List<dynamic>;  
    products = decoded  
        .map((item) => Product.fromJson(  
              Map<String, dynamic>.from(item as Map),  
            ))  
        .toList();  
  }  

  if (savedFavorites != null) {  
    favorites  
      ..clear()  
      ..addAll(savedFavorites);  
  }  

  if (savedCart != null) {  
    final decoded = jsonDecode(savedCart) as Map<String, dynamic>;  
    cart  
      ..clear()  
      ..addAll(decoded.map(  
        (key, value) => MapEntry(key, (value as num).toInt()),  
      ));  
  }  
} catch (e) {  
  debugPrint('تعذر تحميل البيانات المحلية: $e');  
}  

if (mounted) {  
  setState(() {});  
}  

await loadProducts();

}

Future<void> loadProducts() async {
try {
final rows = await fetchProductsFromSupabase();
final remoteProducts = rows.map((row) {
return Product(
name: row['name'] as String? ?? '',
category: row['category'] as String? ?? 'أخرى',
description: row['description'] as String? ?? '',
size: row['size'] as String? ?? '',
colorName: row['color_name'] as String? ?? 'غير محدد',
price: (row['price'] as num?)?.toInt() ?? 0,
imagePath: row['image_url'] as String?,
);
}).toList();

if (!mounted) return;  
  setState(() {  
    // قاعدة البيانات هي المصدر الأساسي للمنتجات المشتركة.  
    products = remoteProducts;  
    loadError = null;  

    final names = products.map((p) => p.name).toSet();  
    cart.removeWhere((key, value) => !names.contains(key));  
    favorites.removeWhere((name) => !names.contains(name));  
  });  
} catch (e) {  
  debugPrint('خطأ في تحميل المنتجات من Supabase: $e');  
  if (!mounted) return;  
  setState(() {  
    loadError = 'تعذّر تحميل المنتجات من الإنترنت.\nتفاصيل الخطأ: $e';  
  });  
} finally {  
  if (mounted) {  
    setState(() => loading = false);  
  }  
}

}

Future<void> _saveData() async {
try {
final prefs = await SharedPreferences.getInstance();
await prefs.setString(
'mahalli_products',
jsonEncode(products.map((p) => p.toJson()).toList()),
);
await prefs.setStringList('mahalli_favorites', favorites.toList());
await prefs.setString('mahalli_cart', jsonEncode(cart));
} catch (e) {
debugPrint('تعذر حفظ البيانات: $e');
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('تعذر حفظ البيانات على الجهاز.')),
);
}
}
}

Future<String?> _pickAndSaveImage() async {
try {
final XFile? picked = await picker.pickImage(
source: ImageSource.gallery,
imageQuality: 80,
maxWidth: 1200,
);
if (picked == null) return null;

final directory = await getApplicationDocumentsDirectory();  
  final imagesDirectory = Directory('${directory.path}/product_images');  
  if (!await imagesDirectory.exists()) {  
    await imagesDirectory.create(recursive: true);  
  }  

  final extension =  
      picked.path.contains('.') ? picked.path.split('.').last : 'jpg';  
  final fileName =  
      'product_${DateTime.now().microsecondsSinceEpoch}.$extension';  
  final savedFile = await File(picked.path).copy(  
    '${imagesDirectory.path}/$fileName',  
  );  
  return savedFile.path;  
} catch (e) {  
  debugPrint('تعذر حفظ الصورة: $e');  
  if (mounted) {  
    ScaffoldMessenger.of(context).showSnackBar(  
      const SnackBar(  
        content: Text('تعذر اختيار الصورة أو حفظها. حاول مرة أخرى.'),  
      ),  
    );  
  }  
  return null;  
}

}

Widget _imagePlaceholder({double iconSize = 48}) {
return Container(
color: const Color(0xFFDDF0DF),
alignment: Alignment.center,
child: Icon(Icons.add_a_photo_outlined, size: iconSize, color: green),
);
}

Widget _productImage(Product product, {double iconSize = 48}) {
final path = product.imagePath;
if (path == null || path.isEmpty) {
return _imagePlaceholder(iconSize: iconSize);
}

if (path.startsWith('https://') || path.startsWith('http://')) {  
  return Image.network(  
    path,  
    width: double.infinity,  
    height: double.infinity,  
    fit: BoxFit.cover,  
    errorBuilder: (_, __, ___) =>  
        _imagePlaceholder(iconSize: iconSize),  
  );  
}  

if (File(path).existsSync()) {  
  return Image.file(  
    File(path),  
    width: double.infinity,  
    height: double.infinity,  
    fit: BoxFit.cover,  
    errorBuilder: (_, __, ___) =>  
        _imagePlaceholder(iconSize: iconSize),  
  );  
}  
return _imagePlaceholder(iconSize: iconSize);

}

void _addToCart(Product product) {
setState(() {
cart[product.name] = (cart[product.name] ?? 0) + 1;
});
_saveData();
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('أُضيف ${product.name} إلى السلة'),
duration: const Duration(seconds: 1),
),
);
}

void _decreaseQuantity(Product product) {
setState(() {
final quantity = cart[product.name] ?? 0;
if (quantity <= 1) {
cart.remove(product.name);
} else {
cart[product.name] = quantity - 1;
}
});
_saveData();
}

void _removeFromCart(Product product) {
setState(() => cart.remove(product.name));
_saveData();
}

@override
Widget build(BuildContext context) {
if (loading) {
return const Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
body: Center(child: CircularProgressIndicator(color: green)),
),
);
}

final shown = products.where((p) {  
  final matchesSearch =  
      p.name.contains(search) || p.category.contains(search);  
  final matchesCategory = category == 'الكل' || p.category == category;  
  final matchesTab = tab != 1 || favorites.contains(p.name);  
  return matchesSearch && matchesCategory && matchesTab;  
}).toList();  

return Directionality(  
  textDirection: TextDirection.rtl,  
  child: Scaffold(  
    appBar: AppBar(  
      title: const Text(  
        'محلّي',  
        style: TextStyle(color: green, fontWeight: FontWeight.bold),  
      ),  
      actions: [  
        IconButton(  
          tooltip: 'تحديث المنتجات',  
          onPressed: () {  
            setState(() => loading = true);  
            loadProducts();  
          },  
          icon: const Icon(Icons.refresh),  
        ),  
        IconButton(  
          tooltip: 'سلة المشتريات',  
          onPressed: () => setState(() => tab = 2),  
          icon: Badge(  
            isLabelVisible: cartCount > 0,  
            label: Text('$cartCount'),  
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
      destinations: [  
        const NavigationDestination(  
          icon: Icon(Icons.home_outlined),  
          label: 'الرئيسية',  
        ),  
        const NavigationDestination(  
          icon: Icon(Icons.favorite_border),  
          label: 'المفضلة',  
        ),  
        NavigationDestination(  
          icon: Badge(  
            isLabelVisible: cartCount > 0,  
            label: Text('$cartCount'),  
            child: const Icon(Icons.shopping_cart_outlined),  
          ),  
          label: 'السلة',  
        ),  
        const NavigationDestination(  
          icon: Icon(Icons.person_outline),  
          label: 'حسابي',  
        ),  
        const NavigationDestination(  
          icon: Icon(Icons.storefront_outlined),  
          label: 'متجري',  
        ),  
      ],  
    ),  
  ),  
);

}

Widget market(List<Product> shown) {
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
onSelected: () => setState(() => category = c),
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
if (loadError != null && products.isEmpty)
Padding(
padding: const EdgeInsets.all(20),
child: Column(
children: [
const Icon(Icons.cloud_off, size: 48, color: Colors.red),
const SizedBox(height: 10),
Text(loadError!, textAlign: TextAlign.center),
const SizedBox(height: 10),
FilledButton.icon(
onPressed: () {
setState(() {
loading = true;
loadError = null;
});
loadProducts();
},
icon: const Icon(Icons.refresh),
label: const Text('إعادة المحاولة'),
),
],
),
)
else if (shown.isEmpty)
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
final product = shown[index];
final isFavorite = favorites.contains(product.name);
final quantity = cart[product.name] ?? 0;
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
_productImage(product),
Positioned(
top: 0,
left: 0,
child: IconButton(
onPressed: () {
setState(() {
if (isFavorite) {
favorites.remove(product.name);
} else {
favorites.add(product.name);
}
});
_saveData();
},
icon: Icon(
isFavorite
? Icons.favorite
: Icons.favorite_border,
color: isFavorite ? Colors.red : Colors.black54,
),
),
),
],
),
),
),
const SizedBox(height: 7),
Text(
product.name,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(fontWeight: FontWeight.bold),
),
Text(
product.category,
style: const TextStyle(fontSize: 12, color: Colors.grey),
),
Row(
children: [
Expanded(
child: Text(
'${product.price} د.أ',
style: const TextStyle(
color: green,
fontWeight: FontWeight.bold,
),
),
),
IconButton(
visualDensity: VisualDensity.compact,
tooltip: 'إضافة إلى السلة',
onPressed: () => _addToCart(product),
icon: Icon(
quantity > 0
? Icons.add_shopping_cart
: Icons.shopping_cart_outlined,
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

Widget _cartPage() {
final items = products
.where((product) => (cart[product.name] ?? 0) > 0)
.toList();
if (items.isEmpty) {
return _messagePage(
Icons.shopping_cart_outlined,
'سلة المشتريات',
'سلتك فارغة. اذهب إلى الرئيسية وأضف المنتجات التي تريدها.',
);
}

return ListView(  
  padding: const EdgeInsets.all(16),  
  children: [  
    Row(  
      children: [  
        const Expanded(  
          child: Text(  
            'سلة المشتريات',  
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),  
          ),  
        ),  
        TextButton.icon(  
          onPressed: _confirmClearCart,  
          icon: const Icon(Icons.delete_outline, color: Colors.red),  
          label: const Text('تفريغ السلة', style: TextStyle(color: Colors.red)),  
        ),  
      ],  
    ),  
    const SizedBox(height: 8),  
    Text('$cartCount قطعة في السلة', style: const TextStyle(color: Colors.grey)),  
    const SizedBox(height: 12),  
    ...items.map((product) {  
      final quantity = cart[product.name] ?? 0;  
      final lineTotal = product.price * quantity;  
      return Card(  
        color: Colors.white,  
        margin: const EdgeInsets.only(bottom: 12),  
        child: Padding(  
          padding: const EdgeInsets.all(12),  
          child: Column(  
            children: [  
              Row(  
                children: [  
                  SizedBox(  
                    width: 82,  
                    height: 82,  
                    child: ClipRRect(  
                      borderRadius: BorderRadius.circular(12),  
                      child: _productImage(product, iconSize: 30),  
                    ),  
                  ),  
                  const SizedBox(width: 12),  
                  Expanded(  
                    child: Column(  
                      crossAxisAlignment: CrossAxisAlignment.start,  
                      children: [  
                        Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),  
                        const SizedBox(height: 4),  
                        Text('${product.price} د.أ للقطعة'),  
                        const SizedBox(height: 4),  
                        Text('المجموع: $lineTotal د.أ', style: const TextStyle(color: green, fontWeight: FontWeight.bold)),  
                      ],  
                    ),  
                  ),  
                  IconButton(  
                    tooltip: 'حذف المنتج',  
                    onPressed: () => _removeFromCart(product),  
                    icon: const Icon(Icons.delete_outline, color: Colors.red),  
                  ),  
                ],  
              ),  
              const Divider(height: 24),  
              Row(  
                children: [  
                  const Text('الكمية'),  
                  const Spacer(),  
                  IconButton(  
                    tooltip: 'تقليل الكمية',  
                    onPressed: () => _decreaseQuantity(product),  
                    icon: const Icon(Icons.remove_circle_outline),  
                  ),  
                  Container(  
                    constraints: const BoxConstraints(minWidth: 36),  
                    alignment: Alignment.center,  
                    child: Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),  
                  ),  
                  IconButton(  
                    tooltip: 'زيادة الكمية',  
                    onPressed: () => _addToCart(product),  
                    icon: const Icon(Icons.add_circle_outline, color: green),  
                  ),  
                ],  
              ),  
            ],  
          ),  
        ),  
      );  
    }),  
    const SizedBox(height: 8),  
    Card(  
      color: Colors.white,  
      child: Padding(  
        padding: const EdgeInsets.all(16),  
        child: Column(  
          children: [  
            _summaryRow('عدد القطع', '$cartCount'),  
            const SizedBox(height: 12),  
            _summaryRow('الإجمالي', '$cartTotal د.أ', bold: true),  
            const SizedBox(height: 6),  
            const Text(  
              'الإجمالي قبل أي رسوم توصيل؛ الدفع وإتمام الطلب غير مفعّلين بعد.',  
              style: TextStyle(color: Colors.grey, fontSize: 12),  
            ),  
          ],  
        ),  
      ),  
    ),  
    const SizedBox(height: 16),  
    FilledButton.icon(  
      style: FilledButton.styleFrom(backgroundColor: green, padding: const EdgeInsets.all(16)),  
      onPressed: () {  
        ScaffoldMessenger.of(context).showSnackBar(  
          const SnackBar(content: Text('سيتم تفعيل إتمام الطلب بعد إضافة نظام الطلبات.')),  
        );  
      },  
      icon: const Icon(Icons.receipt_long_outlined),  
      label: const Text('متابعة لإتمام الطلب'),  
    ),  
  ],  
);

}

Widget _summaryRow(String label, String value, {bool bold = false}) {
final style = TextStyle(
fontSize: bold ? 19 : 16,
fontWeight: bold ? FontWeight.bold : FontWeight.normal,
color: bold ? green : null,
);
return Row(
children: [
Text(label, style: style),
const Spacer(),
Text(value, style: style),
],
);
}

Future<void> _confirmClearCart() async {
final confirmed = await showDialog<bool>(
context: context,
builder: (context) => AlertDialog(
title: const Text('تفريغ السلة'),
content: const Text('هل تريد حذف جميع المنتجات من السلة؟'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context, false),
child: const Text('إلغاء'),
),
FilledButton(
onPressed: () => Navigator.pop(context, true),
child: const Text('تفريغ'),
),
],
),
);
if (confirmed == true && mounted) {
setState(() => cart.clear());
await _saveData();
}
}

Widget _storePage() {
return ListView(
padding: const EdgeInsets.all(16),
children: [
const Text('إدارة متجري', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
const Text('المنتجات المعروضة تُجلب من قاعدة البيانات المشتركة.'),
const SizedBox(height: 18),
FilledButton.icon(
style: FilledButton.styleFrom(backgroundColor: green, padding: const EdgeInsets.all(16)),
onPressed: _addProduct,
icon: const Icon(Icons.add),
label: const Text('إضافة منتج جديد'),
),
const SizedBox(height: 20),
Text('المنتجات (${products.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
...products.map(
(product) => Card(
color: Colors.white,
child: ListTile(
leading: SizedBox(
width: 54,
height: 54,
child: ClipRRect(
borderRadius: BorderRadius.circular(8),
child: _productImage(product, iconSize: 28),
),
),
title: Text(product.name),
subtitle: Text('${product.category} • ${product.price} د.أ'),
trailing: IconButton(
tooltip: 'حذف المنتج من العرض المحلي',
icon: const Icon(Icons.delete_outline, color: Colors.red),
onPressed: () async {
setState(() {
products.remove(product);
favorites.remove(product.name);
cart.remove(product.name);
});
await _saveData();
},
),
),
),
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
                    final path = await _pickAndSaveImage();  
                    if (path != null) refreshDialog(() => selectedImage = path);  
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
                              Icon(Icons.add_photo_alternate_outlined, size: 45, color: green),  
                              SizedBox(height: 8),  
                              Text('اضغط لاختيار صورة المنتج'),  
                            ],  
                          )  
                        : Image.file(  
                            File(selectedImage!),  
                            fit: BoxFit.cover,  
                            width: double.infinity,  
                            errorBuilder: (_, __, ___) => const Center(child: Text('تعذر عرض الصورة')),  
                          ),  
                  ),  
                ),  
                const SizedBox(height: 12),  
                TextFormField(  
                  controller: name,  
                  decoration: const InputDecoration(labelText: 'اسم المنتج *'),  
                  validator: (value) => value == null || value.trim().isEmpty ? 'أدخل اسم المنتج' : null,  
                ),  
                TextFormField(  
                  controller: price,  
                  keyboardType: TextInputType.number,  
                  decoration: const InputDecoration(labelText: 'السعر بالدينار الأردني *'),  
                  validator: (value) {  
                    final number = int.tryParse(value ?? '');  
                    return number == null || number <= 0 ? 'أدخل سعرًا صحيحًا' : null;  
                  },  
                ),  
                const SizedBox(height: 8),  
                DropdownButtonFormField<String>(  
                  value: selectedCategory,  
                  decoration: const InputDecoration(labelText: 'التصنيف'),  
                  items: categories.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),  
                  onChanged: (value) {  
                    if (value != null) refreshDialog(() => selectedCategory = value);  
                  },  
                ),  
                TextFormField(controller: description, decoration: const InputDecoration(labelText: 'الوصف')),  
                TextFormField(controller: size, decoration: const InputDecoration(labelText: 'الحجم أو المقاس')),  
                TextFormField(controller: colorName, decoration: const InputDecoration(labelText: 'اللون')),  
              ],  
            ),  
          ),  
        ),  
      ),  
      actions: [  
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),  
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
                colorName: colorName.text.trim().isEmpty ? 'غير محدد' : colorName.text.trim(),  
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
  // ملاحظة: الإضافة هنا محلية فقط؛ يلزم ربط INSERT بـ Supabase لاحقًا.  
  setState(() {  
    products.insert(0, product);  
    tab = 4;  
  });  
  await _saveData();  
  if (mounted) {  
    ScaffoldMessenger.of(context).showSnackBar(  
      const SnackBar(content: Text('تمت إضافة المنتج على هذا الجهاز فقط؛ لم يُرفع إلى المتجر المشترك.')),  
    );  
  }  
}

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
Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
Text(message, textAlign: TextAlign.center),
],
),
),
);
}
}
