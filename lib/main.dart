import 'package:flutter/material.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final textController = TextEditingController();
  int? selectedId;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: Colors.blueGrey),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Type a new Todo",
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: FutureBuilder<List<Todo>>(
                future: DatabaseHelper.instance.getTodos(),
                builder:
                    (BuildContext context, AsyncSnapshot<List<Todo>> snapshot) {
                  //print(snapshot);
                  if (!snapshot.hasData) {
                    return const Center(child: Text('Loading...'));
                  }
                  return snapshot.data!.isEmpty
                      ? const Center(
                          child: Text("no todo in list "),
                        )
                      : ListView(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          children: snapshot.data!.map((todo) {
                            bool? completed() {
                              if (todo.complete == 1) {
                                return true;
                              }
                              if (todo.complete == 0) {
                                return false;
                              }
                            }

                            return Center(
                              child: ListTile(
                                onLongPress: () {
                                  setState(() {
                                    DatabaseHelper.instance.remove(todo.id!);
                                  });
                                },
                                title: Text(todo.name),
                                trailing: Checkbox(
                                  value: completed(),
                                  onChanged: (bool? value) async {
                                    selectedId = todo.id;
                                    await DatabaseHelper.instance.update(Todo(
                                        name: todo.name,
                                        id: selectedId,
                                        complete: todo.complete == 1
                                            ? todo.complete = 0
                                            : todo.complete = 1));
                                    setState(() {
                                      if (value == true) {
                                        todo.complete = 1;
                                      } else if (value == false) {
                                        todo.complete = 0;
                                      }

                                      selectedId = null;
                                    });
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        );
                }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await DatabaseHelper.instance.add(
            Todo(name: textController.text),
          );
          setState(() {
            textController.clear();
          });
        },
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class Todo {
  final int? id;
  final String name;
  int complete;

  Todo({
    this.id,
    required this.name,
    this.complete = 0,
  });

  factory Todo.fromMap(Map<String, dynamic> todoitem) => Todo(
      id: todoitem['id'],
      name: todoitem['name'],
      complete: todoitem['complete']);

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'complete': complete};
  }
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'testing.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE testdb(
          id INTEGER PRIMARY KEY,
          name TEXT,
          complete INTEGER
      )
      ''');
  }

  Future<List<Todo>> getTodos() async {
    Database db = await instance.database;
    var todos = await db.query('testdb');
    List<Todo> todoList =
        todos.isNotEmpty ? todos.map((c) => Todo.fromMap(c)).toList() : [];
    return todoList;
  }

  Future<int> add(Todo todo) async {
    Database db = await instance.database;
    return await db.insert('testdb', todo.toMap());
  }

  Future<int> remove(int id) async {
    Database db = await instance.database;
    return await db.delete('testdb', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(Todo todo) async {
    Database db = await instance.database;
    return await db
        .update('testdb', todo.toMap(), where: 'id = ?', whereArgs: [todo.id]);
  }
}
