import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const AdvancedDiaryApp());
}

class DiaryEntry {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String mood;
  final List<String> tags;
  final bool isFavorite;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.mood,
    required this.tags,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'date': date.toIso8601String(),
    'mood': mood,
    'tags': tags,
    'isFavorite': isFavorite,
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
    id: json['id'],
    title: json['title'],
    content: json['content'],
    date: DateTime.parse(json['date']),
    mood: json['mood'],
    tags: List<String>.from(json['tags']),
    isFavorite: json['isFavorite'] ?? false,
  );
}

class AdvancedDiaryApp extends StatelessWidget {
  const AdvancedDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A_Dairy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DiaryHomePage(),
    );
  }
}

class DiaryHomePage extends StatefulWidget {
  const DiaryHomePage({super.key});

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> {
  List<DiaryEntry> _entries = [];
  List<DiaryEntry> _filteredEntries = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedMoodFilter = 'All';
  bool _showFavoritesOnly = false;

  final List<String> _moods = [
    'All',
    '😊 Happy',
    '😢 Sad',
    '😴 Tired',
    '😡 Angry',
    '😍 Excited',
    '😌 Peaceful',
  ];

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _searchController.addListener(_filterEntries);
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList('diary_entries') ?? [];
    setState(() {
      _entries =
          entriesJson
              .map((json) => DiaryEntry.fromJson(jsonDecode(json)))
              .toList();
      _entries.sort((a, b) => b.date.compareTo(a.date));
      _filterEntries();
    });
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson =
        _entries.map((entry) => jsonEncode(entry.toJson())).toList();
    await prefs.setStringList('diary_entries', entriesJson);
  }

  void _filterEntries() {
    setState(() {
      _filteredEntries =
          _entries.where((entry) {
            final matchesSearch =
                entry.title.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                entry.content.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                entry.tags.any(
                  (tag) => tag.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  ),
                );

            final matchesMood =
                _selectedMoodFilter == 'All' ||
                entry.mood == _selectedMoodFilter;
            final matchesFavorite = !_showFavoritesOnly || entry.isFavorite;

            return matchesSearch && matchesMood && matchesFavorite;
          }).toList();
    });
  }

  void _addOrEditEntry([DiaryEntry? existingEntry]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EntryEditorPage(
              entry: existingEntry,
              onSave: (entry) {
                setState(() {
                  if (existingEntry != null) {
                    final index = _entries.indexWhere(
                      (e) => e.id == existingEntry.id,
                    );
                    _entries[index] = entry;
                  } else {
                    _entries.insert(0, entry);
                  }
                  _filterEntries();
                });
                _saveEntries();
              },
            ),
      ),
    );
  }

  void _deleteEntry(DiaryEntry entry) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Entry'),
            content: const Text('Are you sure you want to delete this entry?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _entries.removeWhere((e) => e.id == entry.id);
                    _filterEntries();
                  });
                  _saveEntries();
                  Navigator.pop(context);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _toggleFavorite(DiaryEntry entry) {
    setState(() {
      final index = _entries.indexWhere((e) => e.id == entry.id);
      _entries[index] = DiaryEntry(
        id: entry.id,
        title: entry.title,
        content: entry.content,
        date: entry.date,
        mood: entry.mood,
        tags: entry.tags,
        isFavorite: !entry.isFavorite,
      );
      _filterEntries();
    });
    _saveEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.book,
                color: Colors.deepPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('A_Dairy'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
                _filterEntries();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search entries, tags...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedMoodFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Mood',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _moods
                          .map(
                            (mood) => DropdownMenuItem(
                              value: mood,
                              child: Text(mood),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMoodFilter = value!;
                      _filterEntries();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _filteredEntries.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(
                              Icons.auto_stories,
                              size: 64,
                              color: Colors.deepPurple.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _entries.isEmpty
                                ? 'No entries yet!'
                                : 'No entries match your filters',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap the + button to create your first entry',
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _filteredEntries[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              entry.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.content.length > 100
                                      ? '${entry.content.substring(0, 100)}...'
                                      : entry.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(entry.mood),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                if (entry.tags.isNotEmpty)
                                  Wrap(
                                    spacing: 4,
                                    children:
                                        entry.tags
                                            .map(
                                              (tag) => Chip(
                                                label: Text(
                                                  tag,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                            )
                                            .toList(),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    entry.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: entry.isFavorite ? Colors.red : null,
                                  ),
                                  onPressed: () => _toggleFavorite(entry),
                                ),
                                PopupMenuButton(
                                  itemBuilder:
                                      (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Delete'),
                                            ],
                                          ),
                                        ),
                                      ],
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _addOrEditEntry(entry);
                                    } else if (value == 'delete') {
                                      _deleteEntry(entry);
                                    }
                                  },
                                ),
                              ],
                            ),
                            onTap: () => _addOrEditEntry(entry),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditEntry(),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note),
        label: const Text('New Entry'),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class EntryEditorPage extends StatefulWidget {
  final DiaryEntry? entry;
  final Function(DiaryEntry) onSave;

  const EntryEditorPage({super.key, this.entry, required this.onSave});

  @override
  State<EntryEditorPage> createState() => _EntryEditorPageState();
}

class _EntryEditorPageState extends State<EntryEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  String _selectedMood = '😊 Happy';
  List<String> _tags = [];
  bool _isFavorite = false;

  final List<String> _moods = [
    '😊 Happy',
    '😢 Sad',
    '😴 Tired',
    '😡 Angry',
    '😍 Excited',
    '😌 Peaceful',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _selectedMood = widget.entry!.mood;
      _tags = List.from(widget.entry!.tags);
      _isFavorite = widget.entry!.isFavorite;
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _saveEntry() {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and content')),
      );
      return;
    }

    final entry = DiaryEntry(
      id: widget.entry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      date: widget.entry?.date ?? DateTime.now(),
      mood: _selectedMood,
      tags: _tags,
      isFavorite: _isFavorite,
    );

    widget.onSave(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              widget.entry == null ? Icons.add_circle : Icons.edit,
              color: Colors.deepPurple,
            ),
            const SizedBox(width: 8),
            Text(widget.entry == null ? 'New Entry' : 'Edit Entry'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEntry,
            tooltip: 'Save Entry',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMood,
              decoration: const InputDecoration(
                labelText: 'Mood',
                border: OutlineInputBorder(),
              ),
              items:
                  _moods
                      .map(
                        (mood) =>
                            DropdownMenuItem(value: mood, child: Text(mood)),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMood = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: 'Add Tag',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addTag, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 8),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                children:
                    _tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _removeTag(tag),
                          ),
                        )
                        .toList(),
              ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Mark as Favorite'),
              value: _isFavorite,
              onChanged: (value) {
                setState(() {
                  _isFavorite = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 15,
              textAlignVertical: TextAlignVertical.top,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.entry == null ? 'Create Entry' : 'Update Entry',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}
