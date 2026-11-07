import 'package:equatable/equatable.dart';
import '../../domain/models/product.dart';

abstract class VendorDetailsEvent extends Equatable {
  const VendorDetailsEvent();

  @override
  List<Object> get props => [];
}

class VendorDetailsLoadRequested extends VendorDetailsEvent {
  final String vendorId;
  const VendorDetailsLoadRequested({this.vendorId = ''});

  @override
  List<Object> get props => [vendorId];
}

class ToggleFavoriteRequested extends VendorDetailsEvent {
  const ToggleFavoriteRequested();
}

class ToggleDailyTrackRequested extends VendorDetailsEvent {
  const ToggleDailyTrackRequested();
}

class AddToCartRequested extends VendorDetailsEvent {
  final Product product;
  const AddToCartRequested(this.product);

  @override
  List<Object> get props => [product];
}

class RemoveFromCartRequested extends VendorDetailsEvent {
  final Product product;
  const RemoveFromCartRequested(this.product);

  @override
  List<Object> get props => [product];
}
