import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';

void main() {
  runApp(ToDoApp());
}

class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do Calendar App',
      home: ToDoHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ToDoHomePage extends StatefulWidget {
  const ToDoHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ToDoHomePageState createState() => _ToDoHomePageState();
}

class _ToDoHomePageState extends State<ToDoHomePage> {
  final TextEditingController _controller = TextEditingController();
  Map<String, List<Map<String, dynamic>>> _todoMap = {};
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadToDoList();
  }

  void _loadToDoList() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('todoMap');
    if (data != null) {
      setState(() {
        _todoMap = Map<String, List<Map<String, dynamic>>>.from(
          json.decode(data).map((k, v) =>
              MapEntry(k, List<Map<String, dynamic>>.from(v))),
        );
      });
    }
  }

  void _saveToDoList() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('todoMap', json.encode(_todoMap));
  }

  void _addTask(String task) {
    if (task.trim().isEmpty) return;
    final key = _selectedDay.toIso8601String().split('T')[0];

    setState(() {
      if (!_todoMap.containsKey(key)) {
        _todoMap[key] = [];
      }
      _todoMap[key]!.add({'title': task.trim(), 'completed': false});
      _controller.clear();
      _saveToDoList();
    });
  }

  void _toggleTask(int index) {
    final key = _selectedDay.toIso8601String().split('T')[0];
    setState(() {
      _todoMap[key]![index]['completed'] = !_todoMap[key]![index]['completed'];
      _saveToDoList();
    });
  }

  void _deleteTask(int index) {
    final key = _selectedDay.toIso8601String().split('T')[0];
    setState(() {
      _todoMap[key]!.removeAt(index);
      _saveToDoList();
    });
  }

  List<Map<String, dynamic>> _getTasksForDate(DateTime date) {
    final key = date.toIso8601String().split('T')[0];
    return _todoMap[key] ?? [];
  }

  List<Map<String, dynamic>> _getTasksForSelectedDate() {
    final key = _selectedDay.toIso8601String().split('T')[0];
    return _todoMap[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('To-Do Calendar'),centerTitle: true,backgroundColor: Colors.purpleAccent,),
      backgroundColor: const Color.fromARGB(255, 223, 236, 230),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: _getTasksForDate,
              calendarStyle: CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: 'Enter task'),
                    onSubmitted: _addTask,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _addTask(_controller.text),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _getTasksForSelectedDate().length,
                itemBuilder: (context, index) {
                  final task = _getTasksForSelectedDate()[index];
                  return ListTile(
                    leading: Checkbox(
                      value: task['completed'],
                      onChanged: (_) => _toggleTask(index),
                    ),
                    title: Text(
                      task['title'],
                      style: TextStyle(
                        decoration: task['completed']
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: Colors.red,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteTask(index),
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
