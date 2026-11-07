import 'package:equatable/equatable.dart';
import 'vendor_home_state.dart';

abstract class VendorHomeEvent extends Equatable {
  const VendorHomeEvent();

  @override
  List<Object?> get props => [];
}

class VendorLoadRequested extends VendorHomeEvent {
  const VendorLoadRequested();
}

class VendorToggleLiveRoute extends VendorHomeEvent {
  final bool isActive;
  const VendorToggleLiveRoute(this.isActive);

  @override
  List<Object?> get props => [isActive];
}

class VendorToggleDeliveryMode extends VendorHomeEvent {
  final bool isDeliveryModeActive;
  const VendorToggleDeliveryMode(this.isDeliveryModeActive);

  @override
  List<Object?> get props => [isDeliveryModeActive];
}

class VendorNavIndexChanged extends VendorHomeEvent {
  final int index;
  const VendorNavIndexChanged(this.index);

  @override
  List<Object?> get props => [index];
}

class VendorToggleItemStock extends VendorHomeEvent {
  final String itemId;
  final bool inStock;
  const VendorToggleItemStock(this.itemId, this.inStock);

  @override
  List<Object?> get props => [itemId, inStock];
}

class VendorUpdateStockLevel extends VendorHomeEvent {
  final String itemId;
  final String newStockLevel;
  const VendorUpdateStockLevel(this.itemId, this.newStockLevel);

  @override
  List<Object?> get props => [itemId, newStockLevel];
}

class VendorAddItem extends VendorHomeEvent {
  final InventoryItem item;
  const VendorAddItem(this.item);

  @override
  List<Object?> get props => [item];
}

class VendorUpdateVehiclePhoto extends VendorHomeEvent {
  final String imagePath;
  const VendorUpdateVehiclePhoto(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class VendorUpdateOperatingHours extends VendorHomeEvent {
  final String operatingHours;
  const VendorUpdateOperatingHours(this.operatingHours);

  @override
  List<Object?> get props => [operatingHours];
}

class VendorUpdateEnquiryStatus extends VendorHomeEvent {
  final String enquiryId;
  final String newStatus;
  const VendorUpdateEnquiryStatus(this.enquiryId, this.newStatus);

  @override
  List<Object?> get props => [enquiryId, newStatus];
}

class VendorRingBuyer extends VendorHomeEvent {
  final String enquiryId;
  final String buyerName;
  const VendorRingBuyer(this.enquiryId, this.buyerName);

  @override
  List<Object?> get props => [enquiryId, buyerName];
}

class VendorSelectRoute extends VendorHomeEvent {
  final String routeId;
  const VendorSelectRoute(this.routeId);

  @override
  List<Object?> get props => [routeId];
}

class VendorSaveNewRoute extends VendorHomeEvent {
  final VendorRoute route;
  const VendorSaveNewRoute(this.route);

  @override
  List<Object?> get props => [route];
}

class VendorUpdateRoute extends VendorHomeEvent {
  final VendorRoute route;
  const VendorUpdateRoute(this.route);

  @override
  List<Object?> get props => [route];
}

class VendorDeleteRoute extends VendorHomeEvent {
  final String routeId;
  const VendorDeleteRoute(this.routeId);

  @override
  List<Object?> get props => [routeId];
}

class VendorUpdateProfile extends VendorHomeEvent {
  final String vendorName;
  final String vehicleNumber;
  final String category;
  const VendorUpdateProfile(this.vendorName, this.vehicleNumber, this.category);

  @override
  List<Object?> get props => [vendorName, vehicleNumber, category];
}
