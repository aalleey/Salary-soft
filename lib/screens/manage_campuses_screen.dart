import 'package:flutter/material.dart';
import '../models/campus.dart';
import '../services/firebase_service.dart';

class ManageCampusesScreen extends StatefulWidget {
  const ManageCampusesScreen({super.key});

  @override
  State<ManageCampusesScreen> createState() => _ManageCampusesScreenState();
}

class _ManageCampusesScreenState extends State<ManageCampusesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Campus> _campuses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCampuses();
  }

  Future<void> _loadCampuses() async {
    setState(() => _isLoading = true);
    try {
      final campuses = await _firebaseService.getCampuses();
      setState(() {
        _campuses = campuses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading campuses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addCampus() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController locationController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Campus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Campus Name',
                hintText: 'e.g., North Campus',
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location (Optional)',
                hintText: 'e.g., 123 Main St',
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              try {
                await _firebaseService.addCampus(
                  nameController.text.trim(),
                  location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                );
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding campus: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadCampuses();
    }
  }

  Future<void> _deleteCampus(Campus campus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Campus'),
        content: Text('Are you sure you want to delete "${campus.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firebaseService.deleteCampus(campus.id);
        _loadCampuses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Campus deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Campuses')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _campuses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No campuses found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap + to add a campus'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _campuses.length,
              itemBuilder: (context, index) {
                final campus = _campuses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.business,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      campus.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: campus.location != null
                        ? Text(campus.location!)
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red.shade400,
                      onPressed: () => _deleteCampus(campus),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCampus,
        child: const Icon(Icons.add),
      ),
    );
  }
}
