import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // Import kIsWeb
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesome

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Initialize Firebase for Web
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyCTabSQMXFI72a6-f9HEs3BYQF806Ba8zI",
        authDomain: "todolistapp-d4c0a.firebaseapp.com",
        projectId: "todolistapp-d4c0a",
        storageBucket: "todolistapp-d4c0a.appspot.com",
        messagingSenderId: "637821535458",
        appId: "1:637821535458:web:c889119d1492593d320abb",
        measurementId: "YOUR_MEASUREMENT_ID", // Optional
      ),
    );
  } else {
    // Initialize Firebase for Android or iOS
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light; // Default theme is light mode

  void _toggleTheme() {
    setState(() {
      _themeMode = (_themeMode == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Todo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        hintColor: Colors.orangeAccent,
        brightness: Brightness.light,
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.teal, width: 2.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        hintColor: Colors.orangeAccent,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
      ),
      themeMode: _themeMode, // Switches between light and dark mode
      home: TodoScreen(
        onThemeChanged: _toggleTheme,
        currentThemeMode: _themeMode,
      ),
    );
  }
}

class TodoScreen extends StatefulWidget {
  final Function() onThemeChanged;
  final ThemeMode currentThemeMode;

  TodoScreen({required this.onThemeChanged, required this.currentThemeMode});

  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _detailController = TextEditingController(); // Controller for task details
  final CollectionReference _todosCollection = FirebaseFirestore.instance.collection('todos');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TO DO LIST WITH FIREBASE',
          style: TextStyle(
            fontSize: 24.0,  // Set font size
            fontWeight: FontWeight.bold,  // Set font weight to bold
            color: Colors.white,  // Set font color to white
            letterSpacing: 1.5,  // Add some spacing between letters for a cleaner look
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,  // Keep the background color as primary theme color (teal)
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: _todosCollection.snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                    // Sort tasks: uncompleted tasks first, then completed tasks
                    List<QueryDocumentSnapshot> sortedTasks = snapshot.data!.docs;
                    sortedTasks.sort((a, b) {
                      bool isCompletedA = a['isCompleted'] ?? false;
                      bool isCompletedB = b['isCompleted'] ?? false;
                      // Uncompleted tasks come first
                      return isCompletedA == isCompletedB ? 0 : (isCompletedA ? 1 : -1);
                    });

                    return ListView(
                      children: sortedTasks.asMap().map((index, doc) {
                        bool isCompleted = doc['isCompleted'] ?? false;
                        // Define two colors for alternating based on theme
                        Color backgroundColor;
                        if (Theme.of(context).brightness == Brightness.light) {
                          backgroundColor = index.isEven ? Colors.teal[50]! : Colors.grey[200]!;
                        } else {
                          backgroundColor = index.isEven ? Colors.grey[800]! : Colors.grey[700]!;
                        }

                        return MapEntry(
                          index,
                          ListTile(
                            title: Text(
                              doc['task'],
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.w600,
                                color: isCompleted ? Colors.grey : Theme.of(context).primaryColor,
                                decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                              ),
                            ),
                            subtitle: Text(
                              doc['detail'] ?? '', // Show task detail if available
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey[600],
                              ),
                            ),
                            leading: Checkbox(
                              value: isCompleted,
                              onChanged: (bool? value) {
                                _updateTodoWithPopup(doc.id, value!);
                              },
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: FaIcon(FontAwesomeIcons.pen), // FontAwesome edit icon
                                  color: Colors.blueAccent,
                                  onPressed: () => _showEditTodoDialog(context, doc.id, doc['task'], doc['detail']),
                                ),
                                IconButton(
                                  icon: FaIcon(FontAwesomeIcons.trash), // FontAwesome delete icon
                                  color: Colors.redAccent,
                                  onPressed: () => _deleteTodo(doc.id),
                                ),
                              ],
                            ),
                            tileColor: isCompleted ? Colors.grey[300] : backgroundColor, // Alternate colors
                          ),
                        );
                      }).values.toList(),
                    );
                  },
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                onPressed: widget.onThemeChanged,
                child: Icon(
                  widget.currentThemeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
                ),
                backgroundColor: Colors.teal,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTodoDialog(context);
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _addTodo() {
    if (_taskController.text.isNotEmpty) {
      _todosCollection.add({
        'task': _taskController.text,
        'detail': _detailController.text, // Store task detail
        'isCompleted': false,
      });
      _taskController.clear();
      _detailController.clear(); // Clear detail controller
    }
  }

  void _updateTodoWithPopup(String id, bool isCompleted) {
    _todosCollection.doc(id).update({'isCompleted': isCompleted});

    if (isCompleted) {
      // Show a "Finished" dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Task Finished"),
            content: Text("You have completed the task!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "OK",
                  style: TextStyle(color: Colors.teal),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _deleteTodo(String id) {
    _todosCollection.doc(id).delete();
  }

  void _showAddTodoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskController,
                decoration: InputDecoration(
                  hintText: 'Enter task description',
                ),
              ),
              SizedBox(height: 8.0),
              TextField(
                controller: _detailController, // Controller for detail
                decoration: InputDecoration(
                  hintText: 'Enter task details',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cancel button dismisses dialog
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.redAccent), // Red color for Cancel button
              ),
            ),
            TextButton(
              onPressed: () {
                if (_taskController.text.isNotEmpty) {
                  _addTodo();
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                "Add",
                style: TextStyle(color: Colors.teal), // Teal color for Add button
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditTodoDialog(BuildContext context, String id, String currentTask, String currentDetail) {
    final TextEditingController _editTaskController = TextEditingController(text: currentTask);
    final TextEditingController _editDetailController = TextEditingController(text: currentDetail);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editTaskController,
                decoration: InputDecoration(
                  hintText: 'Edit task description',
                ),
              ),
              SizedBox(height: 8.0),
              TextField(
                controller: _editDetailController, // Controller for editing detail
                decoration: InputDecoration(
                  hintText: 'Edit task details',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cancel button dismisses dialog
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.redAccent), // Red color for Cancel button
              ),
            ),
            TextButton(
              onPressed: () {
                if (_editTaskController.text.isNotEmpty) {
                  _todosCollection.doc(id).update({
                    'task': _editTaskController.text,
                    'detail': _editDetailController.text, // Update task detail
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                "Save",
                style: TextStyle(color: Colors.teal), // Teal color for Save button
              ),
            ),
          ],
        );
      },
    );
  }
}