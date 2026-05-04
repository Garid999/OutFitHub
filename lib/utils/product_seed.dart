import 'package:cloud_firestore/cloud_firestore.dart';

const _tStock = {'S': 8, 'M': 14, 'L': 12, 'XL': 10, 'XXL': 6};
const _hStock = {'S': 5, 'M': 10, 'L': 8,  'XL': 7,  'XXL': 4};

const List<Map<String, dynamic>> kSeedProducts = [
  {'id':'1',  'name':'Dr. Stone - Senku',           'category':'Dr. Stone',       'price':39.0, 'imageUrl':'assets/images/product_1.png',  'description':'Senku Ishigami t-shirt from Dr. Stone. Green acid wash oversized.'},
  {'id':'2',  'name':'Jujutsu Kaisen Characters',   'category':'Jujutsu Kaisen',  'price':39.0, 'imageUrl':'assets/images/product_2.png',  'description':'Jujutsu Kaisen (呪術廻戦) t-shirt. White oversized. Megumi and JJK characters.'},
  {'id':'3',  'name':'Chainsaw Man - Power',        'category':'Chainsaw Man',    'price':39.0, 'imageUrl':'assets/images/product_3.png',  'description':'Chainsaw Man t-shirt. Black acid wash oversized. Power character design.'},
  {'id':'4',  'name':'Solo Leveling - Igris Dragon','category':'Solo Leveling',   'price':39.0, 'imageUrl':'assets/images/product_4.png',  'description':'Solo Leveling t-shirt. Black acid wash oversized. Armored warrior with purple flame dragon.'},
  {'id':'5',  'name':'Sukuna - King of Curses',     'category':'Jujutsu Kaisen',  'price':39.0, 'imageUrl':'assets/images/product_5.png',  'description':'Ryomen Sukuna t-shirt from Jujutsu Kaisen. Black acid wash oversized.'},
  {'id':'6',  'name':'Vasto Lorde - Bleach',        'category':'Bleach',          'price':39.0, 'imageUrl':'assets/images/product_6.png',  'description':'Vasto Lorde Hollow (最上大虚) t-shirt from Bleach. Beige oversized.'},
  {'id':'7',  'name':'Attack on Titan - Titans',    'category':'Attack on Titan', 'price':39.0, 'imageUrl':'assets/images/product_7.png',  'description':'Attack on Titan multi-titan t-shirt. Black acid wash oversized.'},
  {'id':'8',  'name':'Gojo & Geto',                 'category':'Jujutsu Kaisen',  'price':39.0, 'imageUrl':'assets/images/product_8.png',  'description':'Satoru Gojo & Suguru Geto t-shirt. Black acid wash oversized.'},
  {'id':'9',  'name':'Toji Fushiguro',              'category':'Jujutsu Kaisen',  'price':39.0, 'imageUrl':'assets/images/product_9.png',  'description':'Toji Fushiguro t-shirt. Black oversized. Dynamic two-warrior fight scene.'},
  {'id':'10', 'name':'Solo Leveling - ARISE',       'category':'Solo Leveling',   'price':39.0, 'imageUrl':'assets/images/product_10.png', 'description':'Solo Leveling ARISE t-shirt. Gray acid wash oversized.'},
  {'id':'11', 'name':'Flame Hashira Rengoku',       'category':'Demon Slayer',    'price':39.0, 'imageUrl':'assets/images/product_11.png', 'description':'Rengoku Kyojuro t-shirt from Demon Slayer. Gray acid wash oversized.'},
  {'id':'12', 'name':'Upper Moon Two - Doma',       'category':'Demon Slayer',    'price':39.0, 'imageUrl':'assets/images/product_12.png', 'description':'Doma - Upper Moon Two t-shirt from Demon Slayer. Black acid wash oversized.'},
  {'id':'13', 'name':'Muichiro Tokito',             'category':'Demon Slayer',    'price':39.0, 'imageUrl':'assets/images/product_13.png', 'description':'Muichiro Tokito t-shirt from Demon Slayer. Black acid wash oversized.'},
  {'id':'14', 'name':'Upper Moon One - Kokushibo',  'category':'Demon Slayer',    'price':39.0, 'imageUrl':'assets/images/product_14.png', 'description':'Kokushibo - Upper Moon One t-shirt from Demon Slayer. Black acid wash oversized.'},
  {'id':'15', 'name':'Phantom Troupe - HxH',        'category':'Hunter x Hunter', 'price':39.0, 'imageUrl':'assets/images/product_15.png', 'description':'Phantom Troupe t-shirt from Hunter x Hunter. Gray oversized.'},
  {'id':'16', 'name':'KON - Bleach',                'category':'Bleach',          'price':39.0, 'imageUrl':'assets/images/product_16.png', 'description':'KON (Modified Soul) t-shirt from Bleach. Black oversized.'},
  {'id':'17', 'name':'Denji - Chainsaw Man',        'category':'Chainsaw Man',    'price':39.0, 'imageUrl':'assets/images/product_17.png', 'description':'Denji / Chainsaw Man t-shirt. Black acid wash oversized.'},
  {'id':'18', 'name':"Scout Regiment - Eren's Key", 'category':'Attack on Titan', 'price':39.0, 'imageUrl':'assets/images/product_18.png', 'description':'AOT Scout Regiment t-shirt. Black acid wash oversized.'},
  {'id':'19', 'name':'Founding Titan - AOT',        'category':'Attack on Titan', 'price':39.0, 'imageUrl':'assets/images/product_19.png', 'description':'Attack on Titan Founding Titan t-shirt. Black acid wash oversized.'},
  {'id':'20', 'name':'Denji & Aki Hoodie',          'category':'Hoodie',          'price':69.0, 'imageUrl':'assets/images/hoodie_1.png',   'description':'Chainsaw Man Denji & Aki hoodie. Beige oversized.'},
  {'id':'21', 'name':'HxH Characters Hoodie',       'category':'Hoodie',          'price':69.0, 'imageUrl':'assets/images/hoodie_2.png',   'description':'Hunter x Hunter characters hoodie. Beige oversized.'},
  {'id':'22', 'name':'Chainsaw Man Duo Hoodie',      'category':'Hoodie',          'price':69.0, 'imageUrl':'assets/images/hoodie_3.png',   'description':'Chainsaw Man duo panel hoodie. Beige oversized.'},
  {'id':'23', 'name':'Killua Zoldyck Hoodie',        'category':'Hoodie',          'price':69.0, 'imageUrl':'assets/images/hoodie_4.png',   'description':'Killua Zoldyck hoodie from Hunter x Hunter. White oversized.'},
  {'id':'24', 'name':'Wonderead Hoodie - White',     'category':'Hoodie',          'price':69.0, 'imageUrl':'assets/images/hoodie_6.png',   'description':'Wonderead x Pagoda hoodie. White oversized.'},
  {'id':'25', 'name':'Wonderead Hoodie - Black',     'category':'Hoodie',          'price':69.0, 'imageUrl':'assets/images/hoodie_7.png',   'description':'Wonderead x Pagoda hoodie. Black oversized.'},
];

Future<void> seedAllProducts() async {
  final col   = FirebaseFirestore.instance.collection('products');
  final batch = FirebaseFirestore.instance.batch();

  for (final p in kSeedProducts) {
    final price = (p['price'] as num).toDouble();
    final stock = price >= 69.0 ? _hStock : _tStock;
    batch.set(col.doc(p['id'] as String), {
      'name':           p['name'],
      'category':       p['category'],
      'price':          price,
      'imageUrl':       p['imageUrl'],
      'description':    p['description'],
      'rating':         5.0,
      'availableSizes': stock.keys.toList(),
      'stock':          stock,
      'isActive':       true,
      'createdAt':      FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
}
