class PidParameters {
  double kp;
  double ki;
  double kd;
  double max;
  double base;
  double turn;
  double lostTh;

  PidParameters({
    this.kp = 0.0,
    this.ki = 0.0,
    this.kd = 0.0,
    this.max = 0.0,
    this.base = 0.0,
    this.turn = 0.0,
    this.lostTh = 0.0,
  });

  factory PidParameters.fromJson(Map<String, dynamic> json) {
    return PidParameters(
      kp: json['kp'] as double,
      ki: json['ki'] as double,
      kd: json['kd'] as double,
      max: json['max'] as double,
      base: json['base'] as double,
      turn: json['turn'] as double,
      lostTh: json['lostTh'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kp': kp,
      'ki': ki,
      'kd': kd,
      'max': max,
      'base': base,
      'turn': turn,
      'lostTh': lostTh,
    };
  }
}
