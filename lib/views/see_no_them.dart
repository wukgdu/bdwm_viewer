import 'package:flutter/material.dart';

class SeeNoThemPage extends StatelessWidget {
  final List<String> seeNoThemList;
  final Function removeOne;
  const SeeNoThemPage({super.key, required this.seeNoThemList, required this.removeOne});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: seeNoThemList.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text(seeNoThemList[index]),
            trailing: IconButton(
              icon: const Icon(Icons.person_remove_rounded),
              onPressed: () {
                removeOne(seeNoThemList[index]);
              },
            ),
          )
        );
      },
    );
  }
}