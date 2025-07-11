import 'package:flutter/material.dart';

Widget buildDateButton({
  required BuildContext context,
  required DateTime? date,
  required String label,
  required IconData icon,
  required void Function(DateTime?) onDateChanged,
}) {
  return Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          icon: Icon(icon),
          label: Text(date == null
              ? label
              : "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}"),
          onPressed: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              onDateChanged(picked);
            }
          },
        ),
      ),
      if (date != null)
        IconButton(
          icon: const Icon(Icons.clear),
          tooltip: '清除日期',
          onPressed: () => onDateChanged(null),
        ),
    ],
  );
}

Widget buildTypeTags(String types) {
  final typeList = types.split(RegExp(r'[,，]')).map((e) => e.trim()).where((e) => e.isNotEmpty).take(3).toList();
  return Wrap(
    spacing: 8,
    runSpacing: 4,
    children: typeList.map((type) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          type,
          style: const TextStyle(fontSize: 14, color: Colors.blue),
        ),
      );
    }).toList(),
  );
}
