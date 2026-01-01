
import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/confession_model.dart';
import 'package:dedikodu_app/data/repositories/confession_repository.dart';
import 'package:dedikodu_app/features/home/widgets/confession_card.dart';
import 'package:dedikodu_app/features/confession/confession_detail_screen.dart';

class ContentSearchScreen extends StatefulWidget {
  const ContentSearchScreen({super.key});

  @override
  State<ContentSearchScreen> createState() => _ContentSearchScreenState();
}

class _ContentSearchScreenState extends State<ContentSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ConfessionRepository _repository = ConfessionRepository();
  
  Stream<List<ConfessionModel>>? _searchStream;
  String _currentQuery = '';

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arama yapmak için en az 2 harf girin.')),
      );
      return;
    }

    // Avoid recreating stream if query hasn't changed
    if (query == _currentQuery && _searchStream != null) return;

    setState(() {
      _currentQuery = query;
      _searchStream = _repository.searchConfessionsStream(query);
    });
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Konu ara... (Ör: araba)',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _performSearch(),
        ),
        actions: [
          IconButton(
            onPressed: _performSearch, 
            icon: const Icon(Icons.search),
          ),
        ],
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_searchStream == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Arama yapmak için yukarıya bir kelime yazın.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<ConfessionModel>>(
      stream: _searchStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Arama sırasında bir hata oluştu: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Aradığınız kriterlere uygun konu bulunamadı.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final confession = results[index];
            return ConfessionCard(
              confession: confession,
              showLocation: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConfessionDetailScreen(
                      confession: confession,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
