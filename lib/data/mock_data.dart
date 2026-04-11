import 'package:milk_delivery_assist/models/product.dart';


final List<Product> mockProducts = [
  Product(
    id: '1',
    name: 'Fresh Cow Milk',
    description: 'Pure, organic cow milk delivered fresh from the farm within hours of milking. Pasteurized and homogenized.',
    price: 45.0,
    unit: '1 L',
    imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&q=80&w=500',
    rating: 4.8,
    category:'Milk'
  ),
  Product(
    id: '2',
    name: 'Buffalo Milk',
    description: 'Rich and creamy buffalo milk, perfect for making tea, coffee, and traditional sweets.',
    price: 60.0,
    unit: '1 L',
    imageUrl: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&q=80&w=500',
    rating: 4.7,
    category:'Milk'
  ),
  Product(
    id: '3',
    name: 'Farm Fresh Paneer',
    description: 'Soft and fresh malai paneer made from pure cow milk. No preservatives added.',
    price: 120.0,
    unit: '200 g',
    imageUrl: 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?auto=format&fit=crop&q=80&w=500',
    isSubscriptionAvailable: true,
    category:'Paneer'
  ),
  Product(
    id: '4',
    name: 'Desi Ghee',
    description: 'Traditional Bilona method ghee with rich aroma and authentic taste.',
    price: 650.0,
    unit: '500 ml',
    imageUrl: 'https://images.unsplash.com/photo-1631452180539-96e99e76df62?auto=format&fit=crop&q=80&w=500',
    isSubscriptionAvailable: false,
    category:'Ghee'
  ),
  Product(
    id: '5',
    name: 'Curd (Dahi)',
    description: 'Thick and creamy set curd, rich in probiotics.',
    price: 30.0,
    unit: '400 g',
    imageUrl: 'https://images.unsplash.com/photo-1571212515416-f223d9098302?auto=format&fit=crop&q=80&w=500',
    category:'Curd'
  ),
];
