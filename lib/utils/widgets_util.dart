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