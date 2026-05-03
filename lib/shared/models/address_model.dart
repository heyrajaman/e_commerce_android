import 'package:equatable/equatable.dart';

class AddressModel extends Equatable {
  final String id;
  final String addressLine1;
  final String state;
  final String city;
  final String area;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.addressLine1,
    required this.state,
    required this.city,
    required this.area,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? '',
      addressLine1: json['addressLine1']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      isDefault:
          json['isDefault'] == true ||
          json['isDefault'] == 1 ||
          json['isDefault'] == 'true',
    );
  }

  @override
  List<Object?> get props => [id, addressLine1, state, city, area, isDefault];
}
