import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zero_hunger/models/report.dart';

class ReportWidget extends StatelessWidget {
  static final _formatter = DateFormat.yMMMd();

  final ReportModel report;
  final bool navigationButton;

  const ReportWidget({
    Key? key,
    required this.report,
    this.navigationButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.date_range),
              title: Text("Last meal on: " + _formatter.format(report.date)),
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
            if (navigationButton)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  onPressed: () => _startNavigation(context),
                  child: Text("Start Navigation"),
                ),
              ),
          ],
        ),
      );

  _startNavigation(BuildContext context) {
    launch("https://www.google.com/maps/search/?api=1&query=${report.coordinates.latitude},${report.coordinates.longitude}");
  }
}
