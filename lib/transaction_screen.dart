import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  String _transactionType = 'Income';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  void addTransactionToFirestore(double amount, DateTime date, String type, String note) {
    final user = FirebaseAuth.instance.currentUser;
    FirebaseFirestore.instance
      .collection('users')
      .doc(user!.uid)
      .collection('transactions')
      .add({
        'amount': amount,
        'date': date,
        'type': type,
        'note': note,
      }).then((value) {
        print("Transaction Added");
      }).catchError((error) {
        print("Failed to add transaction: $error");
      });
  }

  void showTransactionDialog(BuildContext context, {String? docId, double? amount, DateTime? date, String? type, String? note}) {
    _amountController.text = amount != null ? amount.toString() : '';
    _noteController.text = note ?? '';
    _transactionType = type ?? 'Income';
    _selectedDate = date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null ? "Add new transaction" : "Edit transaction"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Amount",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () {
                      showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      ).then((pickedDate) {
                        if (pickedDate != null) {
                          setState(() {
                            _selectedDate = pickedDate;
                          });
                        }
                      });
                    },
                    child: const Text("Select Date"),
                  ),
                  Text("${_selectedDate.toLocal()}".split(' ')[0]),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: _transactionType,
                items: <String>['Income', 'Expense'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _transactionType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Note",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                double amount = double.tryParse(_amountController.text) ?? 0;
                if (docId == null) {
                  addTransactionToFirestore(amount, _selectedDate, _transactionType, _noteController.text);
                }
                Navigator.pop(context);
              },
              child: Text(docId == null ? "Save" : "Update"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction"),
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
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('transactions')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          double totalIncome = 0;
          double totalExpense = 0;
          final transactions = snapshot.data!.docs;

          for (var doc in transactions) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['type'] == 'Income') {
              totalIncome += data['amount'];
            } else {
              totalExpense += data['amount'];
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Total Income: $totalIncome THB"),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Total Expense: $totalExpense THB"),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    var transaction = transactions[index];
                    final data = transaction.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(
                        "${data['type'] == 'Income' ? "+" : "-"}${data['amount']} THB",
                        style: TextStyle(
                          color: data['type'] == 'Income' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text("${data['note']} \nDate: ${data['date'].toDate()}"),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showTransactionDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}