import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const StudentListScreen(),
    );
  }
}

class StudentListScreen extends StatelessWidget {
  const StudentListScreen({super.key});

  void addStudent(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StudentForm();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'รายชื่อนักศึกษา',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.teal[50],
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('students').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('ไม่มีข้อมูลนักศึกษา'));
            }

            final students = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: students.length,
              itemBuilder: (context, index) {
                var student = students[index].data() as Map<String, dynamic>;
                String docId = students[index].id;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    title: Text(
                      '${student['firstname']} ${student['lastname']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'รหัส: ${student['student_id']} | สาขา: ${student['major']} | ชั้นปี: ${student['year']}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return StudentForm(
                                  docId: docId,
                                  studentData: student,
                                );
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('students')
                                .doc(docId)
                                .delete();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addStudent(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class StudentForm extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? studentData;

  const StudentForm({super.key, this.docId, this.studentData});

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController majorController = TextEditingController();
  final TextEditingController yearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.studentData != null) {
      firstnameController.text = widget.studentData!['firstname'] ?? '';
      lastnameController.text = widget.studentData!['lastname'] ?? '';
      studentIdController.text = widget.studentData!['student_id'] ?? '';
      majorController.text = widget.studentData!['major'] ?? '';
      yearController.text = widget.studentData!['year'] ?? '';
    }
  }

  void saveStudent() {
    var studentData = {
      'firstname': firstnameController.text,
      'lastname': lastnameController.text,
      'student_id': studentIdController.text,
      'major': majorController.text,
      'year': yearController.text,
    };

    if (widget.docId == null) {
      FirebaseFirestore.instance.collection('students').add(studentData);
    } else {
      FirebaseFirestore.instance
          .collection('students')
          .doc(widget.docId)
          .update(studentData);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(widget.docId == null ? 'เพิ่มนักศึกษา' : 'แก้ไขข้อมูล'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildTextField('ชื่อ', firstnameController),
          buildTextField('นามสกุล', lastnameController),
          buildTextField('รหัสนักศึกษา', studentIdController),
          buildTextField('สาขา', majorController),
          buildTextField('ชั้นปี', yearController),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: saveStudent,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          child: const Text('บันทึก'),
        ),
      ],
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.teal[50],
        ),
      ),
    );
  }
}
