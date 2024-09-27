import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo/firebase_options.dart';
import 'package:todo/screen/signin_screen.dart';
import 'package:todo/screen/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth',
      theme: ThemeData(
        primarySwatch: Colors.orange, // เปลี่ยนเป็นสีโทนอบอุ่น
        scaffoldBackgroundColor: Colors.yellow[50], // พื้นหลังโทนอบอุ่น
      ),
      initialRoute: '/signup',
      routes: {
        '/signup': (context) => const SignupScreen(),
        '/signin': (context) => const SigninScreen(),
        '/expense': (context) => const ExpenseTrackerApp(),
      },
    );
  }
}

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  String _type = 'รายรับ'; // เริ่มต้นเป็นรายรับ
  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  // ฟังก์ชันเพิ่มข้อมูลลง Firestore
  void addTransactionToFirestore(String type, double amount, DateTime date, String note) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('transactions').add({
        'userId': user.uid, // ใช้ userId จาก FirebaseAuth
        'type': type,
        'amount': amount,
        'date': date,
        'note': note,
      }).then((value) {
        print("Transaction Added");
      }).catchError((error) {
        print("Failed to add transaction: $error");
      });
    } else {
      print("User is not logged in.");
    }
  }

  // ฟังก์ชันเลือกวันที่
  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ฟังก์ชันเปิด Dialog เพื่อเพิ่มรายการ
  void showTransactionDialog(BuildContext context) {
    _amountController.clear();
    _noteController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add new transaction"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Amount",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Note",
                ),
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: _type,
                onChanged: (String? newValue) {
                  setState(() {
                    _type = newValue!;
                  });
                },
                items: <String>['รายรับ', 'รายจ่าย'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text("Selected date: ${_selectedDate.toLocal()}".split(' ')[0]),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                double? amount = double.tryParse(_amountController.text);
                if (amount != null) {
                  addTransactionToFirestore(_type, amount, _selectedDate, _noteController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันคำนวณยอดรวม
  double _calculateTotal(List<QueryDocumentSnapshot> transactions, String type) {
    return transactions
        .where((transaction) => transaction['type'] == type)
        .fold(0.0, (sum, transaction) => sum + transaction['amount']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expense Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/signin');
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data!.docs;

          double totalIncome = _calculateTotal(transactions, 'รายรับ');
          double totalExpense = _calculateTotal(transactions, 'รายจ่าย');
          double balance = totalIncome - totalExpense;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Balance: ฿$balance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    var transaction = transactions[index];
                    final data = transaction.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text("${data['type']} ฿${data['amount']}"),
                      subtitle: Text("${data['note']} on ${data['date'].toDate()}"),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTransactionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
