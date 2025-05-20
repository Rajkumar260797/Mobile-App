import 'package:flutter/cupertino.dart';
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
  DateTime? fromDate;
  DateTime? toDate;
  bool showFilterRow = false;
  bool showSearchBar = false;

  @override
  void initState() {
    super.initState();

    DateTime now = DateTime.now();
    fromDate = DateTime(now.year, now.month, 1); // 1st of this month
    toDate = now; // today

    fetchHistoryData();
  }

  Future<void> fetchHistoryData() async {
    try {
      prefs = await SharedPreferences.getInstance();
      String username = prefs.getString('email') ?? '';

      final String from = DateFormat('yyyy-MM-dd').format(fromDate!);
      final String to = DateFormat('yyyy-MM-dd').format(toDate!);

      List<dynamic> response = await Event.HistoryList(username, from, to);

      setState(() {
        historyData =
            response.map<Map<String, dynamic>>((entry) {
              return {
                'remarks': entry['subject'],
                'from_time': DateTime.parse(entry['starts_on']),
                'to_time': DateTime.parse(entry['ends_on']),
                'total_hours': entry['custom_duration'],
                'custom_distance': entry['custom_distance'] ?? '',
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

  double calculateTotalDistance(List<Map<String, dynamic>> data) {
    double totalMeters = 0.0;

    for (var entry in data) {
      String raw = (entry['custom_distance'] ?? '').toLowerCase().trim();

      if (raw.endsWith('km')) {
        final value = raw.replaceAll('km', '').trim();

        try {
          // Try parsing directly
          totalMeters += double.parse(value) * 1000;
        } catch (e) {
          // Handle malformed strings like "1.18.1"
          final parts = value.split('.');
          double approx = 0.0;
          for (int i = 0; i < parts.length; i++) {
            double part = double.tryParse(parts[i]) ?? 0.0;
            approx += part / (i == 0 ? 1 : (10 * i));
          }
          totalMeters += approx * 1000;
        }
      } else if (raw.endsWith('m')) {
        final value = raw.replaceAll('m', '').trim();
        totalMeters += double.tryParse(value) ?? 0.0;
      }
    }

    return totalMeters / 1000; // Return in km
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
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

    List<Map<String, dynamic>> filteredHistory =
        historyData
            .where(
              (history) => history['remarks'].toString().toLowerCase().contains(
                searchQuery.toLowerCase(),
              ),
            )
            .toList();

    Map<String, List<Map<String, dynamic>>> groupedByDate = {};

    for (var entry in filteredHistory) {
      String dateKey = DateFormat('EEE d, MMM').format(entry['from_time']);
      groupedByDate.putIfAbsent(dateKey, () => []).add(entry);
    }
    final totalKm = calculateTotalDistance(filteredHistory);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('History'),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_alt, color: Colors.white),
                  tooltip: 'Toggle Filter',
                  onPressed: () {
                    setState(() {
                      showFilterRow = !showFilterRow;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  tooltip: 'Toggle Search',
                  onPressed: () {
                    setState(() {
                      showSearchBar = !showSearchBar;
                    });
                  },
                ),

                const Icon(
                  Icons.directions_walk,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  "$totalKm km",
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (showFilterRow)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fromDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => fromDate = picked);
                        if (toDate != null && fromDate!.isAfter(toDate!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "From Date cannot be after To Date",
                              ),
                            ),
                          );
                        } else {
                          fetchHistoryData();
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        fromDate != null
                            ? DateFormat('yyyy-MM-dd').format(fromDate!)
                            : 'From Date',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: toDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => toDate = picked);
                        if (fromDate != null && fromDate!.isAfter(toDate!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "To Date cannot be before From Date",
                              ),
                            ),
                          );
                        } else {
                          fetchHistoryData();
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        toDate != null
                            ? DateFormat('yyyy-MM-dd').format(toDate!)
                            : 'To Date',
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red),
                  tooltip: 'Clear Filters',
                  onPressed: () {
                    setState(() {
                      DateTime now = DateTime.now();
                      fromDate = DateTime(now.year, now.month, 1);
                      toDate = now;
                      searchQuery = '';
                    });
                    fetchHistoryData();
                  },
                ),
              ],
            ),

          if (showSearchBar)
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
            child: RefreshIndicator(
              onRefresh: fetchHistoryData,
              child:
                  filteredHistory.isEmpty
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: Text(
                            'No history found for selected filters.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      )
                      : ListView(
                        children:
                            groupedByDate.entries.map((entry) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ...entry.value.map(
                                    (history) => HistoryItem(history: history),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryOverview(eventid: history['name']),
          ),
        );
      },
      leading: CircleAvatar(child: Text(remarks[0].toUpperCase())),
      title: Text(displayRemarks),
      subtitle: Text(timeRange),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [Text(history['total_hours']), const Text('Working Hours')],
      ),
    );
  }
}
