import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../services/subscription_service.dart';
import 'add_edit_client_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final SubscriptionService _service = SubscriptionService();
  bool _isLoading = true;
  List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    try {
      final clients = await _service.getClients();
      setState(() {
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading clients: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients (Institutes)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadClients),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditClientScreen(),
            ),
          );
          if (result == true) {
            _loadClients();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clients.isEmpty
          ? const Center(child: Text('No clients found.'))
          : ListView.builder(
              itemCount: _clients.length,
              itemBuilder: (context, index) {
                final client = _clients[index];
                return ListTile(
                  title: Text(
                    '#${client.clientNumber} - ${client.instituteName}',
                  ),
                  subtitle: Text('${client.ownerName} • ${client.phone}'),
                  trailing: Chip(
                    label: Text(
                      client.status.toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: client.status == 'active'
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddEditClientScreen(client: client),
                      ),
                    );
                    if (result == true) {
                      _loadClients();
                    }
                  },
                );
              },
            ),
    );
  }
}
