class History {
  final int id;
  final int userId;
  final String activity;
  final DateTime dateTime;

  History({
    required this.id,
    required this.userId,
    required this.activity,
    required this.dateTime,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      id: json['id'],
      userId: json['user_id'],
      activity: json['activity'],
      dateTime: DateTime.parse(json['date_time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'activity': activity,
      'date_time': dateTime.toIso8601String(),
    };
  }
}
