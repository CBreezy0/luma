import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../library/library_models.dart';
import '../library/library_provider.dart';
import '../library/library_viewer_page.dart';

class LumaGalleryPage extends ConsumerStatefulWidget {
  const LumaGalleryPage({super.key});

  @override
  ConsumerState<LumaGalleryPage> createState() => _LumaGalleryPageState();
}

class _LumaGalleryPageState extends ConsumerState<LumaGalleryPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = <String>{};
  bool _isImporting = false;

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels > (position.maxScrollExtent - 600)) {
      ref.read(lumaLibraryProvider.notifier).loadMore();
    }
  }

  Future<void> _importPhotos() async {
    if (_isImporting) return;
    setState(() {
      _isImporting = true;
    });

    try {
      List<XFile> selected = const <XFile>[];
      try {
        selected = await _imagePicker.pickMultiImage(
          requestFullMetadata: false,
        );
      } catch (_) {
        final fallback = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          requestFullMetadata: false,
        );
        if (fallback != null) {
          selected = <XFile>[fallback];
        }
      }

      if (selected.isEmpty) return;
      final paths = selected
          .map((item) => item.path)
          .where((p) => p.isNotEmpty)
          .toList(growable: false);
      await ref.read(lumaLibraryProvider.notifier).importPhotoPaths(paths);
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      } else {
        _isImporting = false;
      }
    }
  }

  void _toggleSelection(String photoId) {
    setState(() {
      if (_selectedIds.contains(photoId)) {
        _selectedIds.remove(photoId);
      } else {
        _selectedIds.add(photoId);
      }
    });
  }

  void _clearSelection() {
    if (_selectedIds.isEmpty) return;
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _openViewer(List<LumaPhoto> ordered, int index) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LumaLibraryViewerPage(
          orderedPhotoIds: ordered
              .map((photo) => photo.photoId)
              .toList(growable: false),
          initialIndex: index,
        ),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    await ref.read(lumaLibraryProvider.notifier).deletePhotos(_selectedIds);
    if (!mounted) return;
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _favoriteSelected(bool favorite) async {
    if (_selectedIds.isEmpty) return;
    final ids = Set<String>.from(_selectedIds);
    await ref.read(lumaLibraryProvider.notifier).setFavorites(ids, favorite);
    if (!mounted) return;
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _rateSelected(int rating) async {
    if (_selectedIds.isEmpty) return;
    final ids = Set<String>.from(_selectedIds);
    await ref.read(lumaLibraryProvider.notifier).setRatings(ids, rating);
    if (!mounted) return;
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _labelSelected(LumaColorLabel label) async {
    if (_selectedIds.isEmpty) return;
    final ids = Set<String>.from(_selectedIds);
    await ref.read(lumaLibraryProvider.notifier).setColorLabels(ids, label);
    if (!mounted) return;
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _batchEditSelected() async {
    if (_selectedIds.isEmpty) return;
    final instructions = <LumaEditInstruction>[
      const LumaEditInstruction(key: 'exposure', value: '+0.3'),
      const LumaEditInstruction(key: 'contrast', value: '-10'),
      const LumaEditInstruction(key: 'grain', value: '+12'),
      const LumaEditInstruction(key: 'look', value: 'slate'),
    ];
    await ref
        .read(lumaLibraryProvider.notifier)
        .addEditInstructions(_selectedIds, instructions);
    if (!mounted) return;
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _exportSelected() async {
    if (_selectedIds.isEmpty) return;
    final controller = ref.read(lumaLibraryProvider.notifier);
    var exported = 0;
    for (final id in _selectedIds) {
      final path = await controller.exportPhoto(id);
      if (path != null) exported += 1;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported $exported photo(s) to LumaLibrary/Edited'),
      ),
    );
    setState(() {
      _selectedIds.clear();
    });
  }

  void _setSort(LumaPhotoSort sort) {
    ref.read(lumaLibraryProvider.notifier).setSort(sort);
  }

  void _setAlbum(LumaSmartAlbum album) {
    ref.read(lumaLibraryProvider.notifier).setAlbum(album);
  }

  void _setMinimumRating(int rating) {
    ref.read(lumaLibraryProvider.notifier).setMinimumRating(rating);
  }

  Color _labelColor(LumaColorLabel label) {
    switch (label) {
      case LumaColorLabel.red:
        return const Color(0xFFFF4D4F);
      case LumaColorLabel.yellow:
        return const Color(0xFFFACC15);
      case LumaColorLabel.green:
        return const Color(0xFF34D399);
      case LumaColorLabel.blue:
        return const Color(0xFF60A5FA);
      case LumaColorLabel.none:
        return Colors.transparent;
    }
  }

  String _sortLabel(LumaPhotoSort sort) {
    switch (sort) {
      case LumaPhotoSort.newest:
        return 'Newest';
      case LumaPhotoSort.oldest:
        return 'Oldest';
      case LumaPhotoSort.ratingHigh:
        return 'Rating';
      case LumaPhotoSort.favoritesFirst:
        return 'Favorites';
    }
  }

  String _albumLabel(LumaSmartAlbum album) {
    switch (album) {
      case LumaSmartAlbum.all:
        return 'All';
      case LumaSmartAlbum.favorites:
        return 'Favorites';
      case LumaSmartAlbum.raw:
        return 'RAW';
      case LumaSmartAlbum.edited:
        return 'Edited';
      case LumaSmartAlbum.imported:
        return 'Imported';
      case LumaSmartAlbum.recentlyEdited:
        return 'Recently Edited';
      case LumaSmartAlbum.portrait:
        return 'Portrait';
      case LumaSmartAlbum.landscape:
        return 'Landscape';
    }
  }

  String _ratingFilterLabel(int minimumRating) {
    if (minimumRating <= 0) return 'All ratings';
    return '$minimumRating★ & up';
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(lumaLibraryProvider);
    final photos = library.visiblePhotos;
    final pairCounts = library.pairedCaptureCounts;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _isSelectionMode ? '${_selectedIds.length} selected' : 'Luma Gallery',
        ),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              onPressed: () => _favoriteSelected(true),
              tooltip: 'Favorite',
              icon: const Icon(Icons.favorite_outline),
            ),
            IconButton(
              onPressed: () => _favoriteSelected(false),
              tooltip: 'Unfavorite',
              icon: const Icon(Icons.heart_broken_outlined),
            ),
            PopupMenuButton<int>(
              tooltip: 'Rate',
              onSelected: _rateSelected,
              itemBuilder: (context) {
                return List<PopupMenuEntry<int>>.generate(
                  5,
                  (i) => PopupMenuItem<int>(
                    value: i + 1,
                    child: Text('${i + 1} Star${i == 0 ? '' : 's'}'),
                  ),
                );
              },
              icon: const Icon(Icons.star_outline),
            ),
            PopupMenuButton<LumaColorLabel>(
              tooltip: 'Label',
              onSelected: _labelSelected,
              itemBuilder: (context) {
                return LumaColorLabel.values
                    .map(
                      (label) => PopupMenuItem<LumaColorLabel>(
                        value: label,
                        child: Text(label.label),
                      ),
                    )
                    .toList(growable: false);
              },
              icon: const Icon(Icons.label_outline),
            ),
            IconButton(
              onPressed: _batchEditSelected,
              tooltip: 'Batch Edit',
              icon: const Icon(Icons.tune),
            ),
            IconButton(
              onPressed: _exportSelected,
              tooltip: 'Export',
              icon: const Icon(Icons.ios_share_outlined),
            ),
            IconButton(
              onPressed: _deleteSelected,
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
            ),
            IconButton(
              onPressed: _clearSelection,
              tooltip: 'Clear',
              icon: const Icon(Icons.close),
            ),
          ] else ...[
            PopupMenuButton<LumaPhotoSort>(
              initialValue: library.sort,
              onSelected: _setSort,
              itemBuilder: (context) {
                return LumaPhotoSort.values
                    .map(
                      (sort) => PopupMenuItem<LumaPhotoSort>(
                        value: sort,
                        child: Text(_sortLabel(sort)),
                      ),
                    )
                    .toList(growable: false);
              },
              icon: const Icon(Icons.sort),
            ),
            PopupMenuButton<int>(
              initialValue: library.minimumRating,
              onSelected: _setMinimumRating,
              itemBuilder: (context) {
                return List<PopupMenuEntry<int>>.generate(
                  6,
                  (index) => PopupMenuItem<int>(
                    value: index,
                    child: Text(_ratingFilterLabel(index)),
                  ),
                );
              },
              icon: const Icon(Icons.filter_alt_outlined),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isImporting ? null : _importPhotos,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        label: Text(_isImporting ? 'Importing…' : 'Import Photo'),
        icon: const Icon(Icons.add_photo_alternate_outlined),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: ref.read(lumaLibraryProvider.notifier).setSearchQuery,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search (lens, date, location, id)',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF171717),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: LumaSmartAlbum.values
                  .map((album) {
                    final active = library.album == album;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        selected: active,
                        label: Text(_albumLabel(album)),
                        onSelected: (_) => _setAlbum(album),
                        selectedColor: Colors.white.withValues(alpha: 0.18),
                        labelStyle: TextStyle(
                          color: active ? Colors.white : Colors.white70,
                        ),
                        backgroundColor: const Color(0xFF171717),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 4),
          if (library.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Text(
                library.errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          Expanded(
            child: library.isLoading
                ? const Center(child: CircularProgressIndicator())
                : photos.isEmpty
                ? const Center(
                    child: Text(
                      'No photos in Luma Library.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 90),
                    itemCount: photos.length + (library.hasMore ? 1 : 0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemBuilder: (context, index) {
                      if (index >= photos.length) {
                        return const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      final photo = photos[index];
                      final isSelected = _selectedIds.contains(photo.photoId);
                      final pairCount =
                          pairCounts[photo.captureIdentifier] ?? 1;
                      final thumbPath = photo.thumbnailPath;
                      final hasThumbnailPath =
                          thumbPath != null && thumbPath.isNotEmpty;

                      return GestureDetector(
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(photo.photoId);
                          } else {
                            unawaited(_openViewer(photos, index));
                          }
                        },
                        onLongPress: () => _toggleSelection(photo.photoId),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              DecoratedBox(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF181818),
                                ),
                                child: hasThumbnailPath
                                    ? Image.file(
                                        File(thumbPath),
                                        fit: BoxFit.cover,
                                        cacheWidth: 360,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              unawaited(
                                                ref
                                                    .read(
                                                      lumaLibraryProvider
                                                          .notifier,
                                                    )
                                                    .ensureThumbnail(
                                                      photo.photoId,
                                                    ),
                                              );
                                              return const Icon(
                                                Icons.photo_outlined,
                                                color: Colors.white54,
                                              );
                                            },
                                      )
                                    : Builder(
                                        builder: (_) {
                                          unawaited(
                                            ref
                                                .read(
                                                  lumaLibraryProvider.notifier,
                                                )
                                                .ensureThumbnail(photo.photoId),
                                          );
                                          return const Icon(
                                            Icons.photo_outlined,
                                            color: Colors.white54,
                                          );
                                        },
                                      ),
                              ),
                              if (photo.isFavorite)
                                const Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Icon(
                                    Icons.favorite,
                                    size: 14,
                                    color: Color(0xFFFF6B6B),
                                  ),
                                ),
                              if (photo.rating > 0)
                                Positioned(
                                  left: 6,
                                  bottom: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.55,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '★' * photo.rating,
                                      style: const TextStyle(
                                        color: Color(0xFFFFD166),
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ),
                              if (photo.colorLabel != LumaColorLabel.none)
                                Positioned(
                                  right: 6,
                                  bottom: 6,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _labelColor(photo.colorLabel),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        width: 0.7,
                                      ),
                                    ),
                                  ),
                                ),
                              if (pairCount > 1)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.55,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${photo.format.wireValue.toUpperCase()}+$pairCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ),
                                ),
                              if (isSelected)
                                Container(
                                  color: const Color(0x8034C759),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
