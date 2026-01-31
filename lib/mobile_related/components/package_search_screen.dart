import 'dart:async';
import 'package:flutter/material.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
import 'package:traveltalkbd/mobile_related/data/travel_models.dart';
import 'package:traveltalkbd/mobile_related/travel_detail_screen.dart';

class PackageSearchScreen extends StatefulWidget {
  final bool initialIsTourPackages;

  const PackageSearchScreen({
    Key? key,
    required this.initialIsTourPackages,
  }) : super(key: key);

  @override
  State<PackageSearchScreen> createState() => _PackageSearchScreenState();
}

class _PackageSearchScreenState extends State<PackageSearchScreen> {
  bool _isTourPackages = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<SearchItem> _allItems = [];
  List<SearchItem> _filteredItems = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _isTourPackages = widget.initialIsTourPackages;
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Simple debounce to avoid filtering too often while typing
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      _filterResults(_searchController.text);
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final content = await TravelDataService.getContent();
      final items = TravelDataService.buildSearchItems(content);
      setState(() {
        _allItems = items;
        _isLoading = false;
      });
      _filterResults(_searchController.text);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load data';
      });
    }
  }

  void _filterResults(String query) {
    final lowerQuery = query.toLowerCase().trim();
    final source = _allItems.where((item) {
      return _isTourPackages ? item.type == 'tour' : item.type == 'visa';
    });

    setState(() {
      // Only show results when user has typed something (autocomplete behavior)
      if (lowerQuery.isEmpty) {
        _filteredItems = [];
      } else {
        _filteredItems = source.where((item) {
          return item.title.toLowerCase().contains(lowerQuery) ||
              item.subtitle.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  void _openDetails(SearchItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TravelDetailScreen(item: item),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         flexibleSpace: Container(
    decoration:  BoxDecoration(
      gradient: Traveltalktheme.primaryGradient
    ),
  ),
        title: const Text('Search Packages'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: _isTourPackages
                        ? 'Search tour packages...'
                        : 'Search visa information...',
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.purple),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : _filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchController.text.isEmpty
                                      ? Icons.search
                                      : Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'Start typing to search...'
                                      : 'No matches found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              return ListTile(
                                leading: item.imageUrl != null &&
                                        item.imageUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          item.imageUrl!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(Icons.image_not_supported),
                                title: Text(item.title),
                                subtitle: Text(
                                  '${item.subtitle} • ${item.type}',
                                ),
                                onTap: () => _openDetails(item),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

