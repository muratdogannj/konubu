import 'package:equatable/equatable.dart';

class Province extends Equatable {
  final int id;
  final String name;
  final int plateCode;
  final int? population;
  final int? area;

  const Province({
    required this.id,
    required this.name,
    required this.plateCode,
    this.population,
    this.area,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'] as int,
      name: json['name'] as String,
      plateCode: json['plateCode'] as int? ?? json['id'] as int,
      population: json['population'] as int?,
      area: json['area'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'plateCode': plateCode,
      'population': population,
      'area': area,
    };
  }

  @override
  List<Object?> get props => [id, name, plateCode, population, area];
}

class District extends Equatable {
  final int id;
  final String name;
  final int provinceId;
  final int? population;
  final int? area;

  const District({
    required this.id,
    required this.name,
    required this.provinceId,
    this.population,
    this.area,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] as int,
      name: json['name'] as String,
      provinceId: json['provinceId'] as int,
      population: json['population'] as int?,
      area: json['area'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provinceId': provinceId,
      'population': population,
      'area': area,
    };
  }

  @override
  List<Object?> get props => [id, name, provinceId, population, area];
}
