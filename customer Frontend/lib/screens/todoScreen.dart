import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdvancedTodoScreen extends StatefulWidget {
  final int userId;
  const AdvancedTodoScreen({super.key, required this.userId});

  @override
  State<AdvancedTodoScreen> createState() => _AdvancedTodoScreenState();
}

class _AdvancedTodoScreenState extends State<AdvancedTodoScreen> {
  List todos = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String selectedPriority = 'All';
  DateTime? selectedDateStart;
  DateTime? selectedDateEnd;

  @override
  void initState() {
    super.initState();
    fetchTodos();
  }

  // Fetch todos from backend with optional filters
  Future<void> fetchTodos() async {
    String url = 'http://localhost:5000/todos/${widget.userId}?';
    if (selectedPriority != 'All') url += 'priority=$selectedPriority&';
    if (selectedDateStart != null && selectedDateEnd != null) {
      url +=
          'start=${DateFormat('yyyy-MM-dd').format(selectedDateStart!)}&end=${DateFormat('yyyy-MM-dd').format(selectedDateEnd!)}';
    }

    final response = await http.get(Uri.parse(url));
    setState(() {
      todos = json.decode(response.body);
    });
  }

  Future<void> toggleDone(int id, bool isDone) async {
    await http.put(
      Uri.parse('http://localhost:5000/todos/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'is_done': !isDone}),
    );
    fetchTodos();
  }

  Future<void> deleteTodo(int id) async {
    await http.delete(Uri.parse('http://localhost:5000/todos/$id'));
    fetchTodos();
  }

  double get progress {
    if (todos.isEmpty) return 0;
    int completed = todos.where((t) => t['is_done'] == 1).length;
    return completed / todos.length;
  }

  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.redAccent;
      case 'Medium':
        return Colors.orangeAccent;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _addTodoDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime dueDate = _selectedDay ?? DateTime.now();
    String priority = 'Medium';
    String recurring = 'None';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Task'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(hintText: 'Title'),
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(hintText: 'Description'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Priority: '),
                      DropdownButton<String>(
                        value: priority,
                        items:
                            ['High', 'Medium', 'Low']
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) priority = value;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Recurring: '),
                      DropdownButton<String>(
                        value: recurring,
                        items:
                            ['None', 'Weekly', 'Monthly']
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) recurring = value;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) dueDate = date;
                    },
                    child: Text(
                      'Due Date: ${DateFormat('yyyy-MM-dd').format(dueDate)}',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await http.post(
                    Uri.parse('http://localhost:5000/todos'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'user_id': widget.userId,
                      'title': titleController.text,
                      'description': descController.text,
                      'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
                      'priority': priority,
                      'recurring': recurring,
                    }),
                  );
                  Navigator.pop(context);
                  fetchTodos();
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  Future<void> generatePdf(List tasks, DateTime start, DateTime end) async {
    final pdf = pw.Document();

    final filteredTasks =
        tasks.where((t) {
          final taskDate = DateTime.parse(t['due_date']);
          return taskDate.isAfter(start.subtract(const Duration(days: 1))) &&
              taskDate.isBefore(end.add(const Duration(days: 1)));
        }).toList();

    pdf.addPage(
      pw.Page(
        build:
            (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'To-Do Tasks (${DateFormat('yyyy-MM-dd').format(start)} - ${DateFormat('yyyy-MM-dd').format(end)})',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                ...filteredTasks.map(
                  (t) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ${t['title']} [${t['priority']}]'),
                      pw.Text('  Description: ${t['description'] ?? '-'}'),
                      pw.Text('  Due Date: ${t['due_date']}'),
                      pw.SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> pickDateRangeAndGeneratePdf() async {
    final pickedStart = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedStart == null) return;

    final pickedEnd = await showDatePicker(
      context: context,
      initialDate: pickedStart.add(const Duration(days: 1)),
      firstDate: pickedStart,
      lastDate: DateTime(2100),
    );
    if (pickedEnd == null) return;

    selectedDateStart = pickedStart;
    selectedDateEnd = pickedEnd;
    await generatePdf(todos, pickedStart, pickedEnd);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        backgroundColor: const Color(0xFFEFBBCF),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: LinearProgressIndicator(
              value: progress,
              color: Colors.green,
              backgroundColor: Colors.grey[300],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: selectedPriority,
                  items:
                      ['All', 'High', 'Medium', 'Low']
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPriority = value!;
                      fetchTodos();
                    });
                  },
                ),
                TextButton.icon(
                  onPressed: pickDateRangeAndGeneratePdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Download PDF'),
                ),
              ],
            ),
          ),

          // Calendar
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),

          // Task List with Drag & Drop
          Expanded(
            child: ReorderableListView.builder(
              itemCount: todos.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = todos.removeAt(oldIndex);
                  todos.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final todo = todos[index];
                return Dismissible(
                  key: ValueKey(todo['id']),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => deleteTodo(todo['id']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          todo['is_done'] == 1
                              ? Colors.green[50]
                              : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: getPriorityColor(todo['priority'] ?? 'Medium'),
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        todo['title'],
                        style: TextStyle(
                          decoration:
                              todo['is_done'] == 1
                                  ? TextDecoration.lineThrough
                                  : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${todo['description'] ?? ''}\nDue: ${todo['due_date']}',
                      ),
                      trailing: Checkbox(
                        value: todo['is_done'] == 1,
                        onChanged:
                            (_) => toggleDone(todo['id'], todo['is_done'] == 1),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEFBBCF),
        child: const Icon(Icons.add),
        onPressed: _addTodoDialog,
      ),
    );
  }
}
