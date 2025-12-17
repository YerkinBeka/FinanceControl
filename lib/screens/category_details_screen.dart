import 'package:flutter/material.dart';
import '../ui/app_styles.dart';
import '../api/api.dart';

class CategoryDetailsScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final String range;

  final String? start;
  final String? end;

  const CategoryDetailsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.range,
    this.start,
    this.end,
  });

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  bool loading = true;
  List expenses = [];

  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadExpenses() async {
    setState(() => loading = true);
    try {
      expenses = await Api.getExpenses(
        categoryId: widget.categoryId,
        range: widget.range,
        start: widget.start,
        end: widget.end,
      );
    } catch (_) {}
    setState(() => loading = false);
  }

  void addExpense() {
    final noteCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime date = DateTime.now();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteCtrl,
              decoration: inputStyle('Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: inputStyle('Amount'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) date = picked;
              },
              child: const Text('Select date'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: buttonStyle,
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text);
              if (noteCtrl.text.trim().isEmpty || amount == null || amount <= 0) return;

              await Api.createExpense(
                categoryId: widget.categoryId,
                note: noteCtrl.text.trim(),
                amount: amount,
                spentAt: date.toIso8601String().substring(0, 10),
              );

              if (!mounted) return;
              Navigator.pop(context);
              loadExpenses();
            },
            child: const Text('Yes', style: buttonTextStyle),
          ),
        ],
      ),
    );
  }

  void editExpense(Map e) {
    final noteCtrl = TextEditingController(text: e['note']);
    final amountCtrl = TextEditingController(text: e['amount'].toString());
    DateTime date = DateTime.parse(e['spent_at']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteCtrl,
              decoration: inputStyle('Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: inputStyle('Amount'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) date = picked;
              },
              child: const Text('Change date'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: buttonStyle,
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text);
              if (noteCtrl.text.trim().isEmpty || amount == null || amount <= 0) return;

              await Api.updateExpense(
                id: e['id'],
                categoryId: widget.categoryId,
                note: noteCtrl.text.trim(),
                amount: amount,
                spentAt: date.toIso8601String().substring(0, 10),
              );

              if (!mounted) return;
              Navigator.pop(context);
              loadExpenses();
            },
            child: const Text('Yes', style: buttonTextStyle),
          ),
        ],
      ),
    );
  }

  void editCategory() {
    final ctrl = TextEditingController(text: widget.categoryName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit category'),
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

              await Api.updateCategory(
                id: widget.categoryId,
                name: ctrl.text.trim(),
              );

              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Yes', style: buttonTextStyle),
          ),
        ],
      ),
    );
  }

  void deleteExpense(int id) async {
    await Api.deleteExpense(id);
    loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final q = searchCtrl.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? expenses
        : expenses.where((e) {
            final note = e['note'].toString().toLowerCase();
            final amount = e['amount'].toString().toLowerCase();
            return note.contains(q) || amount.contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: editCategory,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: addExpense,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchCtrl,
              decoration: inputStyle('Search expense'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(child: Text('No expenses'))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final e = filtered[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: cardDecoration,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e['note'], style: titleStyle),
                                      const SizedBox(height: 4),
                                      Text(e['spent_at'], style: subtitleStyle),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text('${e['amount']} ₸'),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => editExpense(e),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => deleteExpense(e['id']),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
