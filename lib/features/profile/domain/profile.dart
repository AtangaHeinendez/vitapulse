class Profile {
  const Profile({
    required this.id,
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.heightCm,
    this.stepGoal = 8000,
    this.waterGoalMl = 2000,
  });

  final String id;
  final String? fullName;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? heightCm;
  final int stepGoal;
  final int waterGoalMl;

  /// Setup is considered done once the user has saved a name.
  bool get isComplete => fullName != null && fullName!.trim().isNotEmpty;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        fullName: json['full_name'] as String?,
        dateOfBirth: json['date_of_birth'] != null
            ? DateTime.parse(json['date_of_birth'] as String)
            : null,
        gender: json['gender'] as String?,
        heightCm: (json['height_cm'] as num?)?.toDouble(),
        stepGoal: (json['step_goal'] as num?)?.toInt() ?? 8000,
        waterGoalMl: (json['water_goal_ml'] as num?)?.toInt() ?? 2000,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'date_of_birth': dateOfBirth?.toIso8601String().substring(0, 10),
        'gender': gender,
        'height_cm': heightCm,
        'step_goal': stepGoal,
        'water_goal_ml': waterGoalMl,
      };

  Profile copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    double? heightCm,
    int? stepGoal,
    int? waterGoalMl,
  }) =>
      Profile(
        id: id,
        fullName: fullName ?? this.fullName,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        heightCm: heightCm ?? this.heightCm,
        stepGoal: stepGoal ?? this.stepGoal,
        waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      );
}
