import 'package:flutter/material.dart';
import 'BleClient.dart';
import 'Protocol.dart';

/// Danh sách thông báo của quản lý
class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  List<AnnouncementItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await BleClient.instance.announcements();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = r.ok ? null : r.error;
      if (r.ok) _items = r.items;
    });
  }

  String _fmt(DateTime d) {
    String p(int v) => v.toString().padLeft(2, '0');
    return '${p(d.day)}/${p(d.month)}/${d.year} ${p(d.hour)}:${p(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: (_error != null || _items.isEmpty)
            ? ListView(children: [
          const SizedBox(height: 200),
          Center(child: Text(_error ?? 'Chưa có thông báo nào')),
        ])
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final a = _items[i];
            return Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                title: Text(a.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${a.body}\n${_fmt(a.time)}'),
                isThreeLine: true,
              ),
            );
          },
        ),
      ),
    );
  }
}