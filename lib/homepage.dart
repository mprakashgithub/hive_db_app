import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'model/data_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //textfield controllers
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();

  //form key
  final formGlobalKey = GlobalKey<FormState>();
  dynamic box;

  var items = [];
  dynamic selectedValue;
  // var metrics = ["kg", "ltr", "gram", "dozen", "nos"];

  void getItems() async {
    box = await Hive.openBox('hive_box'); // open box

    setState(() {
      items = box.values
          .toList()
          .reversed
          .toList(); //reversed so as to keep the new data to the top
    });
  }

  @override
  void initState() {
    super.initState();
    getItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hive CRUD")),
      body: items.isEmpty
          ? const Center(child: Text("No Data"))
          : ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (_, index) {
                return Card(
                  child: ListTile(
                    title: Text(items[index].item!),
                    subtitle: Row(
                      children: [
                        Text(items[index].quantity.toString()),
                        const SizedBox(width: 5),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        //edit icon
                        IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _showForm(context, items[index].key, index)),
                        // Delete button
                        IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              box = await Hive.openBox('hive_box');
                              box.delete(items[index].key);
                              getItems();
                            }),
                      ],
                    ),
                  ),
                );
              }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showForm(context, null, null);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showForm(BuildContext ctx, var itemKey, var index) {
    print("itemKey: $itemKey");
    if (itemKey != null) {
      _itemController.text = items[index].item;
      _qtyController.text = items[index].quantity.toString();
    } else {
      setState(() {
        _itemController.clear();
        _qtyController.clear();
      });
    }

    showModalBottomSheet(
        isDismissible: false,
        context: context,
        isScrollControlled: true,
        builder: (_) => Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 15,
                left: 15,
                right: 15),
            child: Form(
              key: formGlobalKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _itemController,
                    validator: (value) {
                      if (value!.isEmpty) return "Required Field";
                      return null;
                    },
                    decoration: const InputDecoration(hintText: 'Name'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: _qtyController,
                    validator: (value) {
                      if (value!.isEmpty) return "Required Field";
                      return null;
                    },
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Quantity'),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Exit")),
                      ElevatedButton(
                        onPressed: () async {
                          if (formGlobalKey.currentState!.validate()) {
                            box = await Hive.openBox('hive_box');
                            DataModel dataModel = DataModel(
                                item: _itemController.text,
                                quantity: int.parse(_qtyController.text));
                            if (itemKey == null) {
                              //if the itemKey is null it means we are creating new data
                              setState(() {
                                _itemController.text = "";
                                _qtyController.text = "";
                              });

                              box.add(dataModel);
                              Navigator.of(context).pop();
                            } else {
                              //if itemKey is present we update the data
                              box.put(itemKey, dataModel);
                              Navigator.of(context).pop();
                            }

                            setState(() {
                              _itemController.clear();
                              _qtyController.clear();
                            });
                            //to get refreshedData
                            getItems();
                          }
                          // Close the bottom sheet
                        },
                        child: Text(itemKey == null ? 'Create New' : 'Update'),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 15,
                  )
                ],
              ),
            )));
  }
}
