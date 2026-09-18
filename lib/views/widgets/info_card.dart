import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final List<MapEntry<String, String>> fields;

  const InfoCard({
    super.key,
    required this.title,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            ...fields.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(entry.value),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}