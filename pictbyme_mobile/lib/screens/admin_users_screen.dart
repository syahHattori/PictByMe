import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController searchController =
    TextEditingController();

List users = [];
List filteredUsers = [];
  final ApiService api = ApiService();

 
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      final resp = await api.getAdminUsers();

      setState(() {
  users = resp.data['data'];
  filteredUsers = users;
});
    } catch (e) {
     debugPrint(e.toString());
      setState(() {
        loading = false;
      });
    }
  }
void filterUsers(String keyword) {
  setState(() {
    filteredUsers = users.where((u) {
      return (u['username'] ?? '')
              .toString()
              .toLowerCase()
              .contains(keyword.toLowerCase()) ||

          (u['email'] ?? '')
              .toString()
              .toLowerCase()
              .contains(keyword.toLowerCase()) ||

          (u['name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(keyword.toLowerCase());
    }).toList();
  });
}
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Admin Panel"),
    ),
    body: loading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Cari user...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: filterUsers,
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];

                   return Card(
  margin: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  ),
  child: ListTile(
    onTap: () {
      _showUserDetail(user);
    },
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                user['username'] ?? '',
                              ),
                            ),

                            if (user['role'] == 'admin')
                              const Chip(
                                label: Text('ADMIN'),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          "Coins: ${user['coin_balance']}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editCoins(user);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.password),
                              onPressed: () {
                                _resetPassword(user);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                _deleteUser(user);
                              },
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
                  

  Future<void> _editCoins(dynamic user) async {
  final controller = TextEditingController(
    text: user['coin_balance'].toString(),
  );

  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Edit Coin ${user['username']}'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Jumlah Coin',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );

  if (result == true) {
    await api.updateUserCoins(
      userId: user['id'],
      coins: int.parse(controller.text),
    );

    loadUsers();
  }
}

Future<void> _resetPassword(dynamic user) async {
  final controller = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Reset Password ${user['username']}'),
      content: TextField(
        controller: controller,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Password Baru',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Reset'),
        ),
      ],
    ),
  );

  if (result == true) {
    await api.resetUserPassword(
      userId: user['id'],
      password: controller.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil diubah'),
        ),
      );
    }
  }
}

Future<void> _deleteUser(dynamic user) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Hapus User'),
      content: Text(
        'Yakin ingin menghapus ${user['username']}?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  if (result == true) {
    await api.deleteUser(
      userId: user['id'],
    );

    loadUsers();
  }
}
Future<void> _showUserDetail(dynamic user) async {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(user['username'] ?? ''),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nama: ${user['name'] ?? '-'}'),
          const SizedBox(height: 8),

          Text('Email: ${user['email'] ?? '-'}'),
          const SizedBox(height: 8),

          Text('Role: ${user['role'] ?? 'user'}'),
          const SizedBox(height: 8),

          Text('Coin: ${user['coin_balance'] ?? 0}'),
          const SizedBox(height: 8),

          Text(
            'Terdaftar: ${user['created_at'] ?? '-'}',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}
}
