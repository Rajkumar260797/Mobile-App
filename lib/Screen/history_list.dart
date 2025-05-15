import 'package:flutter/material.dart';
import 'package:homegenie/Screen/history_overview.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api/event.dart';

class HistoryList extends StatefulWidget {
  const HistoryList({super.key});

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  List<Map<String, dynamic>> historyData = [];
  String searchQuery = '';
  bool isLoading = true;
  String? errorMessage;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    fetchHistoryData();
  }

  Future<void> fetchHistoryData() async {
    try {
      
      prefs = await SharedPreferences.getInstance();
      // Replace with actual username/email
      String username = prefs.getString('email') ?? ''; 
      List<dynamic> response = await Event.HistoryList(username);
      print(response);
      setState(() {
        historyData = response.map<Map<String, dynamic>>((entry) {
          return {
            'remarks': entry['subject'],
            'from_time': DateTime.parse(entry['starts_on']),
            'to_time': DateTime.parse(entry['ends_on']),
            'total_hours': entry['custom_duration'],
            'name': entry['name'],
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return  Scaffold(
        appBar: AppBar(title: Text("History")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("History")),
        body: Center(child: Text("Error: $errorMessage")),
      );
    }

    List<Map<String, dynamic>> filteredHistory = historyData
        .where((history) => history['remarks']
            .toString()
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();

    Map<String, List<Map<String, dynamic>>> groupedByDate = {};

    for (var entry in filteredHistory) {
      String dateKey = DateFormat('EEE d, MMM').format(entry['from_time']);
      groupedByDate.putIfAbsent(dateKey, () => []).add(entry);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search history...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: groupedByDate.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...entry.value.map((history) => HistoryItem(history: history)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}


class HistoryItem extends StatelessWidget {
  final Map<String, dynamic> history;

  const HistoryItem({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    String remarks = history['remarks'];
    String displayRemarks =
        remarks.length > 20 ? '${remarks.substring(0, 20)}...' : remarks;

    String fromTime = DateFormat.Hm().format(history['from_time']);
    String toTime = DateFormat.Hm().format(history['to_time']);
    String timeRange = '$fromTime To $toTime';

    return ListTile(
      onTap: () {
        print(history);
        print(history['name']);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryOverview(eventid: history['name']),
      ),
    );
  },
      leading: CircleAvatar(
        child: Text(remarks[0].toUpperCase()),
      ),
      title: Text(displayRemarks),
      subtitle: Text(timeRange),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(history['total_hours']),
          const Text('Working Hours'),
        ],
      ),
    );
  }
}
