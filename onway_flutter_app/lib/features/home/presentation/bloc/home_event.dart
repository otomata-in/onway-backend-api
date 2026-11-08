import 'package:equatable/equatable.dart';
import 'home_state.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeLoadRequested extends HomeEvent {
  const HomeLoadRequested();
}

class HomeCategoryChanged extends HomeEvent {
  final String category;
  const HomeCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class HomeNavIndexChanged extends HomeEvent {
  final int index;
  const HomeNavIndexChanged(this.index);

  @override
  List<Object?> get props => [index];
}

class HomeVendorToggleFavorite extends HomeEvent {
  final VendorInfo vendor;
  const HomeVendorToggleFavorite(this.vendor);

  @override
  List<Object?> get props => [vendor];
}

class HomeSearchQueryChanged extends HomeEvent {
  final String query;
  const HomeSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class HomeLocationSelected extends HomeEvent {
  final double latitude;
  final double longitude;
  final String title;
  final String addressLine;

  const HomeLocationSelected({
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.addressLine,
  });

  @override
  List<Object?> get props => [latitude, longitude, title, addressLine];
}

class HomeBookingCancelRequested extends HomeEvent {
  final String bookingId;
  const HomeBookingCancelRequested(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class HomeBookingCreated extends HomeEvent {
  final ActiveOrderInfo order;
  const HomeBookingCreated(this.order);

  @override
  List<Object?> get props => [order];
}
