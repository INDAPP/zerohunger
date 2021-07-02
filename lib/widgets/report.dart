import 'package:flutter/material.dart';
import 'package:zero_hunger/models/report.dart';

class ReportWidget extends StatelessWidget {
  final Report report;

  const ReportWidget({
    Key? key,
    required this.report,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.date_range),
              title: Text(report.date.toString()),
            ),
            ListTile(
              leading: Icon(
                Icons.local_drink,
                color: report.water ? Colors.blue : Colors.grey,
              ),
              title: Text(report.water ? "Water needed" : "No need of water"),
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text("Number of people: ${report.people}"),
            ),
          ],
        ),
      );
}
