import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // อย่าลืมเพิ่ม import นี้
import 'package:firebase_core/firebase_core.dart';
import 'package:firebaseauthen/sreen/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 40, 236, 243)),
        useMaterial3: true,
      ),
      home: const SigninScreen(),
    );
  }
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _noteController;
  String _selectedType = 'รายรับ'; // ค่าเริ่มต้นของประเภท

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _dateController = TextEditingController();
    _noteController = TextEditingController();
  }

  // Function to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor:
                const Color.fromARGB(255, 40, 236, 243), // Header color
            //accentColor: const Color.fromARGB(255, 40, 236, 243), // Accent color
            colorScheme: const ColorScheme.light(
                primary: Color.fromARGB(255, 40, 236, 243)),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat("dd/MM/yyyy").format(picked);
      });
    }
  }

  void addExpenseHandle(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("เพิ่มรายการรายรับ/รายจ่าย"),
              content: SizedBox(
                width: 300,
                height: 400, // ปรับความสูงให้แสดงผลทุกอย่างครบ
                child: Column(
                  children: [
                    TextField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "จำนวนเงิน",
                        filled: true,
                        fillColor: Colors.grey[200], // Fill color for the input
                      ),
                      keyboardType:
                          TextInputType.number, // สำหรับรับค่าเป็นตัวเลข
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () =>
                          _selectDate(context), // Call the date picker on tap
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _dateController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "วันที่ (dd/MM/yyyy)",
                            filled: true,
                            fillColor:
                                Colors.grey[200], // Fill color for the input
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _selectedType,
                      isExpanded: true, // Make it take full width
                      items: ['รายรับ', 'รายจ่าย'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(value),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType =
                              value!; // อัปเดตสถานะให้เปลี่ยนแปลง UI
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "โน้ต",
                        filled: true,
                        fillColor: Colors.grey[200], // Fill color for the input
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // ตรวจสอบว่าผู้ใช้กรอกข้อมูลครบหรือไม่
                    if (_amountController.text.isEmpty ||
                        _dateController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
                        ),
                      );
                      return;
                    }

                    // แปลงข้อมูลจากช่องกรอกเป็นชนิดข้อมูลที่เหมาะสม
                    double? amount = double.tryParse(_amountController.text);
                    if (amount == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กรุณากรอกจำนวนเงินเป็นตัวเลข'),
                        ),
                      );
                      return;
                    }

                    // บันทึกข้อมูลลง Firestore
                    CollectionReference expenses =
                        FirebaseFirestore.instance.collection("expenses");
                    expenses.add({
                      'amount': amount,
                      'date': _dateController.text, // ใช้วันที่ที่เลือก
                      'type': _selectedType,
                      'note': _noteController.text
                    }).then((res) {
                      print(res);
                    }).catchError((onError) {
                      print("Failed to add new expense");
                    });

                    // ล้างข้อมูลใน TextField
                    _amountController.clear();
                    _dateController.clear();
                    _noteController.clear();

                    Navigator.pop(context);
                  },
                  child: const Text("บันทึก"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("ยกเลิก"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SigninScreen()),
    );
  }

  // ฟังก์ชันคำนวณยอดรวมจากข้อมูลที่ดึงมาจาก Firestore
  double calculateTotal(QuerySnapshot snapshot, String type) {
    double total = 0.0;
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data['type'] == type) {
        total += data['amount'];
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Budget Buddy"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout, // เรียกใช้ฟังก์ชัน logout
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("expenses").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var docs = snapshot.data!.docs;
            var incomeTotal = calculateTotal(snapshot.data!, 'รายรับ');
            var expenseTotal = calculateTotal(snapshot.data!, 'รายจ่าย');
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var item = docs[index].data() as Map<String, dynamic>;
                      return ExpenseItem(item: item);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        "ยอดรวมรายรับ: $incomeTotal บาท",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "ยอดรวมรายจ่าย: $expenseTotal บาท",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "ยอดคงเหลือ: ${incomeTotal - expenseTotal} บาท",
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addExpenseHandle(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ExpenseItem extends StatelessWidget {
  const ExpenseItem({
    super.key,
    required this.item,
  });

  final Map<String, dynamic>? item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2, // Adding shadow for depth
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item?["type"] ?? "",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "จำนวน: ${item?["amount"]} บาท",
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      "วันที่: ${item?["date"]}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (item?["note"] != null)
                      Text(
                        "โน้ต: ${item?["note"]}",
                        style: const TextStyle(fontSize: 16),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
