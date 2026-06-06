import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VendorBookingsScreen extends StatefulWidget {
  final int vendorId; // Pass vendor ID from login/dashboard

  const VendorBookingsScreen({super.key, required this.vendorId});

  @override
  State<VendorBookingsScreen> createState() => _VendorBookingsScreenState();
}

class _VendorBookingsScreenState extends State<VendorBookingsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    final response = await http.get(Uri.parse(
        'http://your-api-url.com/api/vendor/${widget.vendorId}/bookings'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      Map<DateTime, List<Map<String, dynamic>>> bookingsByDate = {};

      for (var booking in data) {
        DateTime date = DateTime.parse(booking['booking_date']);
        date = DateTime(date.year, date.month, date.day); // normalize
        if (!bookingsByDate.containsKey(date)) {
          bookingsByDate[date] = [];
        }
        bookingsByDate[date]!.add(booking);
      }

      setState(() {
        _events = bookingsByDate;
      });
    } else {
      print('Failed to load bookings');
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final eventsForDay = _getEventsForDay(_selectedDay!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Bookings'),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                  color: Colors.redAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: eventsForDay.isEmpty
                ? const Center(child: Text("No bookings for this day."))
                : ListView.builder(
                    itemCount: eventsForDay.length,
                    itemBuilder: (context, index) {
                      var booking = eventsForDay[index];
                      return Card(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        elevation: 2,
                        child: ListTile(
                          title: Text(
                            booking['service_name'] ?? 'Unknown Service',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                              "Time: ${booking['booking_time']} | Customer ID: ${booking['customer_id']}"),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
