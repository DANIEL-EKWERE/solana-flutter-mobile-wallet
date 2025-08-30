import 'package:flutter/material.dart';
import 'package:solanaclaim/Example_app.dart';
import 'package:solanaclaim/example_app1.dart';
import 'package:solanaclaim/home_screen.dart';
import 'package:solanaclaim/phantom_wallet_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const WorkshopHomePage(),
    );
  }
}



class WorkshopHomePage extends StatefulWidget {
  const WorkshopHomePage({super.key});

  @override
  State<WorkshopHomePage> createState() => _WorkshopHomePageState();
}

class _WorkshopHomePageState extends State<WorkshopHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    SendSOLScreen(),
    //Day2Screen(),
    ExampleApp(),
    SendSOLScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text(
      //     'Solana Flutter Workshop',
      //     style: TextStyle(color: Colors.white),
      //   ),
      //   backgroundColor: Theme.of(context).colorScheme.primary,
      // ),
      body: Center(child: _screens.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.looks_one), label: 'Day 1'),
          BottomNavigationBarItem(icon: Icon(Icons.looks_two), label: 'Day 2'),
          BottomNavigationBarItem(icon: Icon(Icons.looks_3), label: 'Day 3'),
          //BottomNavigationBarItem(icon: Icon(Icons.looks_4), label: 'Day 4'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}
