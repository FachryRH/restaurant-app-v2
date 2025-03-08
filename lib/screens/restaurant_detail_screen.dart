import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_app/models/restaurant.dart';
import 'package:restaurant_app/providers/restaurant_provider.dart';
import 'package:restaurant_app/providers/favorite_provider.dart';
import 'package:restaurant_app/widgets/loading_indicator.dart';
import 'package:restaurant_app/widgets/error_message.dart';

class RestaurantDetailPage extends StatefulWidget {
  final Restaurant restaurant;
  const RestaurantDetailPage({super.key, required this.restaurant});

  @override
  RestaurantDetailPageState createState() => RestaurantDetailPageState();
}

class RestaurantDetailPageState extends State<RestaurantDetailPage> {
  final _nameController = TextEditingController();
  final _reviewController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<RestaurantProvider>(context, listen: false)
          .fetchRestaurantDetail(widget.restaurant.id);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<RestaurantProvider>(context, listen: false);
      await provider.addReview(
        widget.restaurant.id,
        _nameController.text,
        _reviewController.text,
      );
      await provider.fetchRestaurantDetail(widget.restaurant.id);
      _nameController.clear();
      _reviewController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    }
  }

  Widget _buildReviewSection(List<CustomerReview> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Reviews',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...reviews.map((review) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(review.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.review),
                    const SizedBox(height: 4),
                    Text(
                      review.date,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildReviewForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tulis Ulasan Anda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Nama harus diisi' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _reviewController,
            decoration: const InputDecoration(
              labelText: 'Ulasan',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) =>
                value == null || value.isEmpty ? 'Ulasan harus diisi' : null,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _submitReview,
            child: const Text('Kirim Ulasan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant.name),
        actions: [
          Consumer<FavoriteProvider>(
            builder: (context, favoriteProvider, child) {
              return FutureBuilder<bool>(
                future: favoriteProvider.isFavorite(widget.restaurant.id),
                builder: (context, snapshot) {
                  final isFavorite = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                    ),
                    onPressed: () async {
                      final message = await favoriteProvider.toggleFavorite(widget.restaurant);
                      if (message != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, child) {
          if (provider.restaurantDetailState is Loading) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  Hero(
                    tag: 'restaurant_image_${widget.restaurant.id}',
                    child: Image.network(
                      'https://restaurant-api.dicoding.dev/images/large/${widget.restaurant.pictureId}',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_rounded,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tidak dapat memuat gambar',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(child: loadingLottie()),
                ],
              ),
            );
          } else if (provider.restaurantDetailState is Success<RestaurantDetail>) {
            final restaurantDetail = (provider.restaurantDetailState as Success<RestaurantDetail>).data;
            return buildDetailContent(context, restaurantDetail);
          } else if (provider.restaurantDetailState is Error) {
            return ErrorMessage(message: (provider.restaurantDetailState as Error).message);
          } else {
            return const Center(child: Text('Unknown state'));
          }
        },
      ),
    );
  }

  Widget buildDetailContent(BuildContext context, RestaurantDetail restaurantDetail) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Hero(
            tag: 'restaurant_image_${widget.restaurant.id}',
            child: Image.network(
              'https://restaurant-api.dicoding.dev/images/large/${widget.restaurant.pictureId}',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tidak dapat memuat gambar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Hero(
                        tag: 'title-${widget.restaurant.id}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: Text(
                            restaurantDetail.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            restaurantDetail.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('${restaurantDetail.city} • ${restaurantDetail.address}'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Kategori:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: restaurantDetail.categories.map((category) {
                    return Chip(
                      label: Text(category.name),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(restaurantDetail.description),
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('Menu Makanan'),
                  children: restaurantDetail.menus.foods
                      .map((food) => ListTile(
                            leading: const Icon(Icons.restaurant_menu),
                            title: Text(food.name),
                          ))
                      .toList(),
                ),
                ExpansionTile(
                  title: const Text('Menu Minuman'),
                  children: restaurantDetail.menus.drinks
                      .map((drink) => ListTile(
                            leading: const Icon(Icons.local_drink),
                            title: Text(drink.name),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                _buildReviewSection(restaurantDetail.customerReviews),
                const Divider(),
                _buildReviewForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
