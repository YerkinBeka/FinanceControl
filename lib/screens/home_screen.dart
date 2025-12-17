import 'package:flutter/material.dart';
import '../ui/app_styles.dart';
import '../api/api.dart';
import 'category_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String range = 'month'; // today | week | month
  bool loading = true;

  double total = 0;
  List categories = [];

  final searchCtrl = TextEditingController();
  DateTimeRange? customRange;

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<void> loadSummary() async {
    setState(() => loading = true);
    try {
      final data = await Api.getSummary(
        range,
        start: customRange == null ? null : _fmt(customRange!.start),
        end: customRange == null ? null : _fmt(customRange!.end),
      );
      total = (data['total'] as num).toDouble();
      categories = data['categories'];
    } catch (_) {}
    setState(() => loading = false);
  }

  void changeRange(String value) {
    setState(() {
      range = value;
      customRange = null;
    });
    loadSummary();
  }

  void pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: customRange,
    );

    if (picked == null) return;

    setState(() => customRange = picked);
    loadSummary();
  }

  void clearCustomRange() {
    setState(() => customRange = null);
    loadSummary();
  }

  void showAddCategoryDialog() {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add category'),
        content: TextField(
          controller: ctrl,
          decoration: inputStyle('Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: buttonStyle,
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await Api.createCategory(ctrl.text.trim());
              if (!mounted) return;
              Navigator.pop(context);
              loadSummary();
            },
            child: const Text('Yes', style: buttonTextStyle),
          ),
        ],
      ),
    );
  }

  void goToProfile() async {
    await Navigator.pushNamed(context, '/profile');
    loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    final q = searchCtrl.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? categories
        : categories.where((c) => c['name'].toString().toLowerCase().contains(q)).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            onPressed: goToProfile,
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _filters(),
            const SizedBox(height: 12),
            TextField(
              controller: searchCtrl,
              decoration: inputStyle('Search category'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: buttonStyle,
                    onPressed: pickDateRange,
                    child: Text(
                      customRange == null
                          ? 'Select date'
                          : '${_fmt(customRange!.start)} - ${_fmt(customRange!.end)}',
                      style: buttonTextStyle,
                    ),
                  ),
                ),
                if (customRange != null)
                  IconButton(
                    onPressed: clearCustomRange,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _totalCard(),
            const SizedBox(height: 16),
            Expanded(child: _categoriesList(filtered)),
          ],
        ),
      ),
    );
  }

  Widget _filters() => Container(
        padding: const EdgeInsets.all(6),
        decoration: cardDecoration,
        child: Row(
          children: [
            _rangeButton('Today', 'today'),
            _rangeButton('Week', 'week'),
            _rangeButton('Month', 'month'),
          ],
        ),
      );

  Widget _rangeButton(String text, String value) => Expanded(
        child: GestureDetector(
          onTap: () => changeRange(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: range == value ? primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: range == value ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _totalCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TOTAL', style: titleStyle),
            Text(
              '${total.toStringAsFixed(2)} ₸',
              style: titleStyle,
            ),
          ],
        ),
      );

  Widget _categoriesList(List list) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (list.isEmpty) {
      return const Center(child: Text('No categories'));
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final c = list[i];

        return GestureDetector(
          onTap: () async {
            final changed = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryDetailsScreen(
                  categoryId: c['id'],
                  categoryName: c['name'],
                  range: range,
                  start: customRange == null ? null : _fmt(customRange!.start),
                  end: customRange == null ? null : _fmt(customRange!.end),
                ),
              ),
            );

            if (changed == true) {
              loadSummary();
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(c['name'], style: titleStyle),
                Text('${c['sum']} ₸'),
              ],
            ),
          ),
        );
      },
    );
  }
}
