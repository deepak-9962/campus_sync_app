import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String department;
  final String semester;

  const HomeScreen({
    Key? key,
    required this.userName,
    required this.department,
    required this.semester,
  }) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Campus Sync'), backgroundColor: Colors.blue),
      body: Center(child: Text('Welcome ${widget.userName}!')),
    );
  }
}
