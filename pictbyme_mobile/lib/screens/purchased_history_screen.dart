import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import 'pin_detail_screen.dart';

class PurchasedHistoryScreen extends StatefulWidget {
  const PurchasedHistoryScreen({super.key});

  @override
  State<PurchasedHistoryScreen> createState() => _PurchasedHistoryScreenState();
}

class _PurchasedHistoryScreenState extends State<PurchasedHistoryScreen> {
  final ApiService apiService = ApiService();

  List<dynamic> purchases = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchasedPins();
  }

  Future<void> _loadPurchasedPins() async {
    setState(() => loading = true);
    try {
      final resp = await apiService.getPurchasedPins();
      if (resp.statusCode == 200 && resp.data != null) {
        final list = resp.data['data'] as List? ?? [];
        setState(() => purchases = List<dynamic>.from(list));
      }
    } catch (_) {
      // Biarkan list kosong jika gagal, ditampilkan sebagai empty state.
    }
    if (mounted) setState(() => loading = false);
  }

  String _formatCurrency(dynamic value) {
    int amount = 0;
    if (value is int) {
      amount = value;
    } else if (value is double) {
      amount = value.toInt();
    } else if (value is String) {
      amount = int.tryParse(value) ?? 0;
    }
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    try {
      final date = DateTime.parse(value.toString());
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return '-';
    }
  }

  void _openPinDetail(Map pin) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PinDetailScreen(pin: pin)));
  }

  Widget _buildThumbnail(Map? pin) {
    final fileUrl = pin?['file_url']?.toString();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 80,
        height: 80,
        child: (fileUrl == null || fileUrl.isEmpty)
            ? Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              )
            : Image.network(
                fileUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[50],
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black26),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Paid',
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  Widget _buildPurchaseCard(Map purchase) {
    final pin = (purchase['pin'] is Map) ? Map<String, dynamic>.from(purchase['pin']) : <String, dynamic>{};
    final title = pin['title']?.toString() ?? '-';
    final creator = (pin['user'] is Map ? pin['user']['name']?.toString() : null) ??
        pin['creator_name']?.toString() ??
        '-';
    final category = pin['category']?.toString() ?? '-';
    final price = purchase['price'];
    final purchasedAt = purchase['purchased_at'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openPinDetail(pin),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(pin),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By $creator • $category',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(purchasedAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatCurrency(price),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87),
                        ),
                        _buildStatusBadge(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No purchased pins yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              'Purchased premium pins will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Purchased History'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPurchasedPins,
              child: purchases.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        _buildEmptyState(),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: purchases.length,
                      itemBuilder: (context, index) {
                        final purchase = Map<String, dynamic>.from(purchases[index] as Map);
                        return _buildPurchaseCard(purchase);
                      },
                    ),
            ),
    );
  }
}