import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BudgetScreen extends StatefulWidget {
  final int userId;
  const BudgetScreen({super.key, required this.userId});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final String baseUrl = 'http://localhost:5000';
  final Color themeColor = const Color(0xFFEFBBCF);

  List<Map<String, dynamic>> transactions = [];
  Map<String, double> categoryBudgets = {};

  List<String> categories = [
    'Venue',
    'Catering',
    'Attire',
    'Photography',
    'Decor',
    'Music',
    'Misc',
  ];

  DateTime? startDate;
  DateTime? endDate;
  String selectedCategory = 'All';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => loading = true);
    await fetchBudgets();
    await fetchTransactions();
    setState(() => loading = false);
  }

  // ================= API =================

  Future<void> fetchBudgets() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/budget/categories/${widget.userId}'),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;

        categoryBudgets = {
          for (final row in data)
            (row['category'] as String): (row['planned'] as num).toDouble(),
        };
      } else {
        categoryBudgets = {for (final c in categories) c: 0.0};
      }
    } catch (_) {
      categoryBudgets = {for (final c in categories) c: 0.0};
    }

    setState(() {});
  }

  Future<void> fetchTransactions() async {
    try {
      final qp = <String>[];

      if (selectedCategory != 'All') {
        qp.add('category=$selectedCategory');
      }

      if (startDate != null && endDate != null) {
        qp.add('start=${DateFormat('yyyy-MM-dd').format(startDate!)}');
        qp.add('end=${DateFormat('yyyy-MM-dd').format(endDate!)}');
      }

      final url =
          '$baseUrl/budget/${widget.userId}${qp.isEmpty ? '' : '?${qp.join('&')}'}';

      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;

        transactions =
            data
                .map(
                  (e) => {
                    'id': e['id'],
                    'type': e['type'],
                    'amount': (e['amount'] as num).toDouble(),
                    'category': e['category'],
                    'vendor': e['vendor'],
                    'date': e['date'],
                    'notes': e['notes'],
                  },
                )
                .toList();
      } else {
        transactions = [];
      }
    } catch (_) {
      transactions = [];
    }

    setState(() {});
  }

  Future<void> addTransaction(Map<String, dynamic> t) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/budget/transaction'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId, ...t}),
      );
    } catch (_) {}

    await refreshData();
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await http.delete(Uri.parse('$baseUrl/budget/transaction/$id'));
    } catch (_) {}

    await refreshData();
  }

  Future<void> refreshData() async {
    await fetchBudgets();
    await fetchTransactions();
    setState(() {});
  }

  // ================= CALCULATIONS =================

  double get totalPlanned => categoryBudgets.values.fold(0.0, (a, b) => a + b);

  double get totalSpent => transactions
      .where((t) => t['type'] == 'expense')
      .fold(0.0, (a, t) => a + (t['amount'] as double));

  double get totalIncome => transactions
      .where((t) => t['type'] == 'income')
      .fold(0.0, (a, t) => a + (t['amount'] as double));

  double get remaining => (totalPlanned + totalIncome) - totalSpent;

  Map<String, double> get spentByCategory {
    final map = <String, double>{};

    for (final t in transactions.where((t) => t['type'] == 'expense')) {
      map[t['category']] = (map[t['category']] ?? 0) + (t['amount'] as double);
    }

    return map;
  }

  // ================= PIE CHART =================

  List<PieChartSectionData> _pieData() {
    final data = spentByCategory;

    if (data.isEmpty) {
      return [PieChartSectionData(value: 1, title: 'No Data', radius: 50)];
    }

    final total = data.values.fold(0.0, (a, b) => a + b);

    return data.entries.map((e) {
      final percent = (e.value / total) * 100;

      return PieChartSectionData(
        value: e.value,
        title: "${e.key}\n${percent.toStringAsFixed(1)}%",
        radius: 60,
      );
    }).toList();
  }

  // ================= DATE FILTER =================

  Future<void> _pickDateRange() async {
    final start = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (start == null) return;

    final end = await showDatePicker(
      context: context,
      firstDate: start,
      lastDate: DateTime(2100),
    );

    if (end == null) return;

    setState(() {
      startDate = start;
      endDate = end;
    });

    await fetchTransactions();
  }

  // ================= ADD TRANSACTION =================

  Future<void> _showAddDialog() async {
    String type = 'expense';
    String category = categories.first;
    double amount = 0;
    String vendor = '';
    String notes = '';

    await showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text("Add Transaction"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: type,
                      items: const [
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text('Expense'),
                        ),
                        DropdownMenuItem(
                          value: 'income',
                          child: Text('Income'),
                        ),
                      ],
                      onChanged: (v) => setDialogState(() => type = v!),
                    ),

                    DropdownButton<String>(
                      value: category,
                      items:
                          categories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                      onChanged: (v) => setDialogState(() => category = v!),
                    ),

                    TextField(
                      decoration: const InputDecoration(labelText: "Amount"),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => amount = double.tryParse(v) ?? 0,
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: "Vendor"),
                      onChanged: (v) => vendor = v,
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: "Notes"),
                      onChanged: (v) => notes = v,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await addTransaction({
                        'type': type,
                        'amount': amount,
                        'category': category,
                        'vendor': vendor,
                        'notes': notes,
                        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      });

                      Navigator.pop(context);
                    },
                    child: const Text("Add"),
                  ),
                ],
              );
            },
          ),
    );
  }

  // ================= PDF REPORT =================

  Future<void> downloadPdfReport() async {
    final pdf = pw.Document();

    final filteredTransactions =
        transactions.where((t) {
          if (startDate == null || endDate == null) return true;

          final date = DateTime.parse(t['date']);
          return date.isAfter(startDate!.subtract(const Duration(days: 1))) &&
              date.isBefore(endDate!.add(const Duration(days: 1)));
        }).toList();

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Text(
                "Wedding Budget Report",
                style: pw.TextStyle(fontSize: 20),
              ),

              pw.SizedBox(height: 10),

              pw.Text("Planned: Rs ${totalPlanned.toStringAsFixed(0)}"),
              pw.Text("Spent: Rs ${totalSpent.toStringAsFixed(0)}"),
              pw.Text("Income: Rs ${totalIncome.toStringAsFixed(0)}"),
              pw.Text("Remaining: Rs ${remaining.toStringAsFixed(0)}"),

              pw.SizedBox(height: 20),

              pw.Text("Transactions"),

              pw.Table.fromTextArray(
                headers: ["Date", "Category", "Type", "Amount", "Notes"],
                data:
                    filteredTransactions.map((t) {
                      return [
                        t['date'],
                        t['category'],
                        t['type'],
                        "Rs ${t['amount']}",
                        t['notes'] ?? '',
                      ];
                    }).toList(),
              ),
            ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // ================= UI =================

  Widget _card(String title, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(title),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Budget"),
        backgroundColor: themeColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: downloadPdfReport,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeColor,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Row(
                    children: [
                      _card(
                        "Planned",
                        "Rs ${totalPlanned.toStringAsFixed(0)}",
                        Colors.blue,
                      ),
                      _card(
                        "Spent",
                        "Rs ${totalSpent.toStringAsFixed(0)}",
                        Colors.red,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _card(
                        "Income",
                        "Rs ${totalIncome.toStringAsFixed(0)}",
                        Colors.green,
                      ),
                      _card(
                        "Remaining",
                        "Rs ${remaining.toStringAsFixed(0)}",
                        Colors.teal,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 220,
                    child: PieChart(PieChartData(sections: _pieData())),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _pickDateRange,
                          child: const Text("Filter Date"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: downloadPdfReport,
                          child: const Text("Download PDF"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  ...transactions.map(
                    (t) => ListTile(
                      title: Text(t['category']),
                      subtitle: Text(t['notes'] ?? ''),
                      trailing: Text(
                        "Rs ${t['amount']}",
                        style: TextStyle(
                          color:
                              t['type'] == 'expense'
                                  ? Colors.red
                                  : Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
