import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Label Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const FoodLabelPage(title: 'Food Label Manager'),
    );
  }
}

class FoodItem {
  String name;
  double quantity;
  String unit;

  FoodItem({required this.name, required this.quantity, required this.unit});

  // Add JSON conversion methods
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'],
      quantity: json['quantity'].toDouble(),
      unit: json['unit'],
    );
  }
}

class FoodLabelPage extends StatefulWidget {
  const FoodLabelPage({super.key, required this.title});

  final String title;

  @override
  State<FoodLabelPage> createState() => _FoodLabelPageState();
}

class _FoodLabelPageState extends State<FoodLabelPage> {
  final List<FoodItem> _foodItems = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedUnit = 'g'; // Default unit

  final List<String> _units = ['g', 'kg', 'ml', 'L', 'pieces'];

  @override
  void initState() {
    super.initState();
    _loadFoodItems(); // Load saved items when the app starts
  }

  // Load saved food items
  Future<void> _loadFoodItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? foodItemsJson = prefs.getString('foodItems');

    if (foodItemsJson != null) {
      final List<dynamic> decodedItems = jsonDecode(foodItemsJson);
      setState(() {
        _foodItems.clear();
        _foodItems.addAll(
          decodedItems.map((item) => FoodItem.fromJson(item)).toList(),
        );
      });
    }
  }

  // Save food items
  Future<void> _saveFoodItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedItems = jsonEncode(
      _foodItems.map((item) => item.toJson()).toList(),
    );
    await prefs.setString('foodItems', encodedItems);
  }

  void _addFoodItem() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _foodItems.add(
          FoodItem(
            name: _nameController.text,
            quantity: double.parse(_quantityController.text),
            unit: _selectedUnit,
          ),
        );
        // Clear the form
        _nameController.clear();
        _quantityController.clear();
      });
      _saveFoodItems(); // Save after adding
    }
  }

  void _removeFoodItem(int index) {
    setState(() {
      _foodItems.removeAt(index);
    });
    _saveFoodItems(); // Save after removing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Food Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a food name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter quantity';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                          ),
                          items: _units.map((String unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedUnit = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addFoodItem,
                    child: const Text('Add Food Item'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _foodItems.length,
                itemBuilder: (context, index) {
                  final item = _foodItems[index];
                  return Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text('${item.quantity} ${item.unit}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeFoodItem(index),
                      ),
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

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}