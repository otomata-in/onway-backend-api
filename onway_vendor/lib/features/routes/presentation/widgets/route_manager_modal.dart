import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/bloc/vendor_home_bloc.dart';
import '../../../home/presentation/bloc/vendor_home_event.dart';
import '../../../home/presentation/bloc/vendor_home_state.dart';

class LocationSuggestion {
  final String name;
  final String address;
  final LatLng point;

  const LocationSuggestion({
    required this.name,
    required this.address,
    required this.point,
  });
}

const List<LocationSuggestion> _keralaLocations = [
  // THRISSUR DISTRICT VILLAGES & TOWNS (Chittattukara, Brahmamkulam, Elavally, Choondal, Kandanassery, Mattam, etc.)
  LocationSuggestion(name: 'Chittattukara Village', address: 'Chittattukara Panchayat, Thrissur District, Kerala', point: LatLng(10.5890, 76.0450)),
  LocationSuggestion(name: 'Brahmamkulam Village', address: 'Brahmamkulam, Thrissur District, Kerala', point: LatLng(10.6050, 76.0520)),
  LocationSuggestion(name: 'Elavally Village & Temple', address: 'Elavally, Thrissur District, Kerala', point: LatLng(10.5690, 76.0910)),
  LocationSuggestion(name: 'Choondal Junction', address: 'Choondal, Thrissur District, Kerala', point: LatLng(10.6120, 76.1050)),
  LocationSuggestion(name: 'Kandanassery Village', address: 'Kandanassery, Thrissur District, Kerala', point: LatLng(10.5980, 76.0850)),
  LocationSuggestion(name: 'Mattam Junction', address: 'Mattam, Thrissur District, Kerala', point: LatLng(10.5750, 76.0680)),
  LocationSuggestion(name: 'Chittilappilly Village', address: 'Chittilappilly, Thrissur District, Kerala', point: LatLng(10.5520, 76.1550)),
  LocationSuggestion(name: 'Pavaratty Church Road', address: 'Pavaratty, Thrissur District, Kerala', point: LatLng(10.5620, 76.0580)),
  LocationSuggestion(name: 'Peruvallur Village', address: 'Peruvallur, Thrissur District, Kerala', point: LatLng(10.5810, 76.0710)),
  LocationSuggestion(name: 'Iringaprom Village', address: 'Iringaprom, Thrissur District, Kerala', point: LatLng(10.6010, 76.0280)),
  LocationSuggestion(name: 'Pookode Village', address: 'Pookode, Thrissur District, Kerala', point: LatLng(10.6150, 76.0410)),
  LocationSuggestion(name: 'Thaikkad Village', address: 'Thaikkad, Thrissur District, Kerala', point: LatLng(10.6190, 76.0620)),
  LocationSuggestion(name: 'Puvathur Village', address: 'Puvathur, Thrissur District, Kerala', point: LatLng(10.5590, 76.0810)),
  LocationSuggestion(name: 'Kechery Junction', address: 'Kechery, Thrissur District, Kerala', point: LatLng(10.6080, 76.1280)),
  LocationSuggestion(name: 'Mullassery Town', address: 'Mullassery, Thrissur District, Kerala', point: LatLng(10.5480, 76.0780)),
  LocationSuggestion(name: 'Venkitangu Village', address: 'Venkitangu, Thrissur District, Kerala', point: LatLng(10.5320, 76.1020)),
  LocationSuggestion(name: 'Velur Temple Road', address: 'Velur, Thrissur District, Kerala', point: LatLng(10.6420, 76.1380)),
  LocationSuggestion(name: 'Erumapetty Junction', address: 'Erumapetty, Thrissur District, Kerala', point: LatLng(10.6690, 76.1680)),
  LocationSuggestion(name: 'Kadangode Village', address: 'Kadangode, Thrissur District, Kerala', point: LatLng(10.6780, 76.1350)),
  LocationSuggestion(name: 'Porkulam Village', address: 'Porkulam, Thrissur District, Kerala', point: LatLng(10.6650, 76.0520)),
  LocationSuggestion(name: 'Punnayurkulam Village', address: 'Punnayurkulam, Thrissur District, Kerala', point: LatLng(10.6280, 75.9880)),
  LocationSuggestion(name: 'Punnayur Town', address: 'Punnayur, Thrissur District, Kerala', point: LatLng(10.6080, 75.9980)),
  LocationSuggestion(name: 'Vadakkekad Village', address: 'Vadakkekad, Thrissur District, Kerala', point: LatLng(10.6380, 75.9780)),
  LocationSuggestion(name: 'Orumanayur Village', address: 'Orumanayur, Thrissur District, Kerala', point: LatLng(10.5750, 76.0280)),
  LocationSuggestion(name: 'Kadappuram Coastal Belt', address: 'Kadappuram, Thrissur District, Kerala', point: LatLng(10.5680, 76.0080)),
  LocationSuggestion(name: 'Chettuva Harbour', address: 'Chettuva, Thrissur District, Kerala', point: LatLng(10.5280, 76.0410)),
  LocationSuggestion(name: 'Chavakkad Town & Beach', address: 'Chavakkad Bus Stand, Thrissur District, Kerala', point: LatLng(10.5840, 76.0120)),
  LocationSuggestion(name: 'Guruvayur Temple East Gate', address: 'East Nada, Guruvayur, Thrissur District, Kerala', point: LatLng(10.5940, 76.0390)),
  LocationSuggestion(name: 'Kunnamkulam Town', address: 'Market Road, Kunnamkulam, Thrissur District, Kerala', point: LatLng(10.6500, 76.0700)),
  LocationSuggestion(name: 'Vadanappally Beach Junction', address: 'Beach Road, Vadanappally, Thrissur District, Kerala', point: LatLng(10.4570, 76.0720)),
  LocationSuggestion(name: 'Triprayar Temple Junction', address: 'Triprayar Bridge, Thrissur District, Kerala', point: LatLng(10.4180, 76.1130)),
  LocationSuggestion(name: 'Nattika Beach Area', address: 'Nattika, Thrissur District, Kerala', point: LatLng(10.4100, 76.0900)),
  LocationSuggestion(name: 'Valapad Beach Town', address: 'Valapad Junction, Thrissur District, Kerala', point: LatLng(10.4280, 76.1020)),
  LocationSuggestion(name: 'Engandiyur Village', address: 'NH66, Engandiyur, Thrissur District, Kerala', point: LatLng(10.5050, 76.0420)),
  LocationSuggestion(name: 'Kanjany Market Junction', address: 'Kanjany, Thrissur District, Kerala', point: LatLng(10.4980, 76.1340)),
  LocationSuggestion(name: 'Thalikulam Beach', address: 'Thalikulam, Thrissur District, Kerala', point: LatLng(10.4380, 76.0820)),
  LocationSuggestion(name: 'Perinjanam Town', address: 'Perinjanam, Thrissur District, Kerala', point: LatLng(10.3020, 76.1550)),
  LocationSuggestion(name: 'Mathilakam Town', address: 'Mathilakam, Thrissur District, Kerala', point: LatLng(10.2780, 76.1680)),
  LocationSuggestion(name: 'Kaipamangalam Junction', address: 'Kaipamangalam, Thrissur District, Kerala', point: LatLng(10.3280, 76.1450)),
  LocationSuggestion(name: 'Eriyad Village', address: 'Eriyad, Thrissur District, Kerala', point: LatLng(10.2080, 76.1840)),
  LocationSuggestion(name: 'Kodungallur Temple Town', address: 'Kodungallur, Thrissur District, Kerala', point: LatLng(10.2220, 76.1960)),
  LocationSuggestion(name: 'Poyya Village', address: 'Poyya, Thrissur District, Kerala', point: LatLng(10.1880, 76.2680)),
  LocationSuggestion(name: 'Kuzhur Village', address: 'Kuzhur, Thrissur District, Kerala', point: LatLng(10.2280, 76.2580)),
  LocationSuggestion(name: 'Annamanada Junction', address: 'Annamanada, Thrissur District, Kerala', point: LatLng(10.2310, 76.3210)),
  LocationSuggestion(name: 'Mala Town', address: 'Mala Market, Thrissur District, Kerala', point: LatLng(10.2180, 76.2970)),
  LocationSuggestion(name: 'Koratty Infopark', address: 'Koratty, Thrissur District, Kerala', point: LatLng(10.2640, 76.3680)),
  LocationSuggestion(name: 'Chalakudy KSRTC Stand', address: 'Chalakudy, Thrissur District, Kerala', point: LatLng(10.3070, 76.3320)),
  LocationSuggestion(name: 'Aloor Village', address: 'Aloor, Thrissur District, Kerala', point: LatLng(10.3310, 76.2820)),
  LocationSuggestion(name: 'Kodakara Junction', address: 'Kodakara, Thrissur District, Kerala', point: LatLng(10.3680, 76.3020)),
  LocationSuggestion(name: 'Irinjalakuda Town', address: 'Irinjalakuda, Thrissur, Kerala', point: LatLng(10.3420, 76.2140)),
  LocationSuggestion(name: 'Padiyur Village', address: 'Padiyur, Thrissur District, Kerala', point: LatLng(10.3650, 76.1850)),
  LocationSuggestion(name: 'Poomangalam Village', address: 'Poomangalam, Thrissur District, Kerala', point: LatLng(10.3150, 76.2080)),
  LocationSuggestion(name: 'Kattoor Market', address: 'Kattoor, Thrissur District, Kerala', point: LatLng(10.3920, 76.1680)),
  LocationSuggestion(name: 'Karalam Village', address: 'Karalam, Thrissur District, Kerala', point: LatLng(10.3950, 76.1950)),
  LocationSuggestion(name: 'Muriyad Village', address: 'Muriyad, Thrissur District, Kerala', point: LatLng(10.3750, 76.2480)),
  LocationSuggestion(name: 'Parappur Village', address: 'Parappur, Thrissur District, Kerala', point: LatLng(10.5580, 76.1380)),
  LocationSuggestion(name: 'Arimpur Village', address: 'Arimpur, Thrissur District, Kerala', point: LatLng(10.5010, 76.1480)),
  LocationSuggestion(name: 'Anthikad Town', address: 'Anthikad, Thrissur District, Kerala', point: LatLng(10.4680, 76.1420)),
  LocationSuggestion(name: 'Manalur Village', address: 'Manalur, Thrissur District, Kerala', point: LatLng(10.5180, 76.1180)),
  LocationSuggestion(name: 'Thanyam Village', address: 'Thanyam, Thrissur District, Kerala', point: LatLng(10.3980, 76.1480)),
  LocationSuggestion(name: 'Cherpu Temple Junction', address: 'Cherpu, Thrissur District, Kerala', point: LatLng(10.4480, 76.2080)),
  LocationSuggestion(name: 'Vallachira Village', address: 'Vallachira, Thrissur District, Kerala', point: LatLng(10.4420, 76.2280)),
  LocationSuggestion(name: 'Avinissery Village', address: 'Avinissery, Thrissur District, Kerala', point: LatLng(10.4790, 76.2160)),
  LocationSuggestion(name: 'Ayyanthole Civil Station', address: 'Ayyanthole, Thrissur City, Kerala', point: LatLng(10.5280, 76.1910)),
  LocationSuggestion(name: 'Kolazhy Town', address: 'Kolazhy, Thrissur District, Kerala', point: LatLng(10.5640, 76.2180)),
  LocationSuggestion(name: 'Mulagunathukavu Medical College', address: 'Mulagunathukavu, Thrissur District, Kerala', point: LatLng(10.5980, 76.2180)),
  LocationSuggestion(name: 'Madakkathara Village', address: 'Madakkathara, Thrissur District, Kerala', point: LatLng(10.5580, 76.2620)),
  LocationSuggestion(name: 'Nadathara Village', address: 'Nadathara, Thrissur District, Kerala', point: LatLng(10.5180, 76.2580)),
  LocationSuggestion(name: 'Pananchery Village', address: 'Pananchery, Thrissur District, Kerala', point: LatLng(10.5350, 76.3180)),
  LocationSuggestion(name: 'Ollur Station Road', address: 'Ollur Town, Thrissur District, Kerala', point: LatLng(10.4850, 76.2420)),
  LocationSuggestion(name: 'Nenmanikkara Village', address: 'Nenmanikkara, Thrissur District, Kerala', point: LatLng(10.4350, 76.2680)),
  LocationSuggestion(name: 'Amballur Highway Junction', address: 'Amballur, Thrissur District, Kerala', point: LatLng(10.4280, 76.2780)),
  LocationSuggestion(name: 'Pudukad Railway Station', address: 'Pudukad, Thrissur District, Kerala', point: LatLng(10.4210, 76.2620)),
  LocationSuggestion(name: 'Wadakkanchery Station', address: 'Wadakkanchery Town, Thrissur District, Kerala', point: LatLng(10.6640, 76.2520)),
  LocationSuggestion(name: 'Chelakkara Village', address: 'Chelakkara Bus Stand, Thrissur District, Kerala', point: LatLng(10.7020, 76.3530)),
  LocationSuggestion(name: 'Pazhayannur Town', address: 'Pazhayannur, Thrissur District, Kerala', point: LatLng(10.6620, 76.4380)),
  LocationSuggestion(name: 'Varavoor Village', address: 'Varavoor, Thrissur District, Kerala', point: LatLng(10.7080, 76.2380)),
  LocationSuggestion(name: 'Desamangalam Village', address: 'Desamangalam, Thrissur District, Kerala', point: LatLng(10.7520, 76.2780)),
  LocationSuggestion(name: 'Thiruvilwamala Temple Gate', address: 'Thiruvilwamala, Thrissur District, Kerala', point: LatLng(10.7280, 76.4480)),
  LocationSuggestion(name: 'Thrissur Swaraj Round', address: 'City Center, Thrissur, Kerala', point: LatLng(10.5270, 76.2140)),

  // ERNAKULAM DISTRICT (Major & Minor Cities, Towns, Villages)
  LocationSuggestion(name: 'Ernakulam South Station', address: 'Ernakulam South, Kochi, Kerala', point: LatLng(9.9687, 76.2897)),
  LocationSuggestion(name: 'Ernakulam North Station', address: 'Town Hall, Ernakulam North, Kochi, Kerala', point: LatLng(9.9920, 76.2880)),
  LocationSuggestion(name: 'Vyttila Mobility Hub', address: 'Vyttila, Kochi, Kerala', point: LatLng(9.9675, 76.3180)),
  LocationSuggestion(name: 'Lulu Mall Edappally', address: 'Edappally Toll, Kochi, Kerala', point: LatLng(10.0270, 76.3080)),
  LocationSuggestion(name: 'Kakkanad InfoPark', address: 'InfoPark Expressway, Kakkanad, Kochi, Kerala', point: LatLng(10.0100, 76.3620)),
  LocationSuggestion(name: 'Fort Kochi Beach', address: 'Coast Road, Fort Kochi, Kerala', point: LatLng(9.9650, 76.2430)),
  LocationSuggestion(name: 'Mattancherry Palace', address: 'Palace Road, Mattancherry, Kochi, Kerala', point: LatLng(9.9580, 76.2590)),
  LocationSuggestion(name: 'Marine Drive Walkway', address: 'Shanmugham Road, Ernakulam, Kochi, Kerala', point: LatLng(9.9790, 76.2760)),
  LocationSuggestion(name: 'Kaloor Bus Stand', address: 'Kaloor Junction, Kochi, Kerala', point: LatLng(9.9980, 76.2990)),
  LocationSuggestion(name: 'Palarivattom Junction', address: 'Pipeline Junction, Palarivattom, Kochi, Kerala', point: LatLng(10.0070, 76.3080)),
  LocationSuggestion(name: 'Tripunithura Hill Palace', address: 'Statue Junction, Tripunithura, Ernakulam, Kerala', point: LatLng(9.9480, 76.3470)),
  LocationSuggestion(name: 'Aluva Metro & Station', address: 'Bank Junction, Aluva, Ernakulam, Kerala', point: LatLng(10.1090, 76.3500)),
  LocationSuggestion(name: 'Angamaly Town', address: 'KSRTC Bus Stand, Angamaly, Ernakulam, Kerala', point: LatLng(10.1960, 76.3860)),
  LocationSuggestion(name: 'Kalady Sree Sankaracharya Town', address: 'Kalady Junction, Ernakulam District, Kerala', point: LatLng(10.1690, 76.4380)),
  LocationSuggestion(name: 'Malayattoor Pilgrim Center', address: 'Church Road, Malayattoor, Ernakulam, Kerala', point: LatLng(10.1860, 76.4980)),
  LocationSuggestion(name: 'North Paravur Town', address: 'Private Bus Stand, North Paravur, Ernakulam, Kerala', point: LatLng(10.1470, 76.2290)),
  LocationSuggestion(name: 'Cherai Beach Resort Area', address: 'Cherai Beach Road, Vypin, Ernakulam, Kerala', point: LatLng(10.1410, 76.1780)),
  LocationSuggestion(name: 'Vypin Island Bus Stand', address: 'Gosree Bridge End, Vypin, Ernakulam, Kerala', point: LatLng(9.9880, 76.2410)),
  LocationSuggestion(name: 'Perumbavoor Town', address: 'Private Bus Stand, Perumbavoor, Ernakulam, Kerala', point: LatLng(10.1160, 76.4780)),
  LocationSuggestion(name: 'Muvattupuzha KSRTC Terminal', address: 'Market Road, Muvattupuzha, Ernakulam, Kerala', point: LatLng(9.9830, 76.5780)),
  LocationSuggestion(name: 'Kothamangalam Town', address: 'High Range Junction, Kothamangalam, Ernakulam, Kerala', point: LatLng(10.0630, 76.6230)),
  LocationSuggestion(name: 'Piravom Town', address: 'River View Bus Stand, Piravom, Ernakulam, Kerala', point: LatLng(9.8720, 76.4940)),
  LocationSuggestion(name: 'Kolenchery Town', address: 'Medical Mission Junction, Kolenchery, Ernakulam, Kerala', point: LatLng(9.9790, 76.4720)),
  LocationSuggestion(name: 'Pattimattom Junction', address: 'Pattimattom Market, Ernakulam District, Kerala', point: LatLng(10.0140, 76.4480)),
  LocationSuggestion(name: 'Kizhakkambalam Town', address: 'Kitex Road, Kizhakkambalam, Ernakulam, Kerala', point: LatLng(10.0380, 76.4250)),
  LocationSuggestion(name: 'Koothattukulam Market', address: 'MC Road, Koothattukulam, Ernakulam, Kerala', point: LatLng(9.8450, 76.5820)),
  LocationSuggestion(name: 'Mulanthuruthy Station', address: 'Mulanthuruthy Town, Ernakulam District, Kerala', point: LatLng(9.9070, 76.3890)),
  LocationSuggestion(name: 'Kumbalangi Model Tourism Village', address: 'Kumbalangi Backwaters, Kochi, Kerala', point: LatLng(9.8870, 76.2860)),

  // MALAPPURAM DISTRICT (Major & Minor Cities, Towns, Inland Villages)
  LocationSuggestion(name: 'Malappuram KSRTC Terminal', address: 'Down Hill, Malappuram City, Kerala', point: LatLng(11.0730, 76.0740)),
  LocationSuggestion(name: 'Manjeri Town Center', address: 'Seethi Haji Bus Stand, Manjeri, Malappuram, Kerala', point: LatLng(11.1210, 76.1210)),
  LocationSuggestion(name: 'Perinthalmanna Market', address: 'Jubilee Junction, Perinthalmanna, Malappuram, Kerala', point: LatLng(10.9780, 76.2260)),
  LocationSuggestion(name: 'Tirur Railway Station', address: 'Station Road, Tirur, Malappuram District, Kerala', point: LatLng(10.9160, 75.9230)),
  LocationSuggestion(name: 'Kottakkal Arya Vaidya Sala', address: 'Hospital Junction, Kottakkal, Malappuram, Kerala', point: LatLng(11.0010, 75.9980)),
  LocationSuggestion(name: 'Ponnani Harbour & Town', address: 'Bus Stand, Ponnani, Malappuram District, Kerala', point: LatLng(10.7710, 75.9220)),
  LocationSuggestion(name: 'Edapal Junction', address: 'Thrissur-Calicut Highway, Edapal, Malappuram, Kerala', point: LatLng(10.7620, 76.0020)),
  LocationSuggestion(name: 'Kuttippuram Railway Bridge', address: 'Kuttippuram Town, Malappuram District, Kerala', point: LatLng(10.8350, 76.0270)),
  LocationSuggestion(name: 'Valanchery Town', address: 'Kozhikode Road, Valanchery, Malappuram, Kerala', point: LatLng(10.8970, 76.0710)),
  LocationSuggestion(name: 'Tanur Coastal Town', address: 'Tanur Station Road, Malappuram District, Kerala', point: LatLng(10.9780, 75.8680)),
  LocationSuggestion(name: 'Parappanangadi Beach Town', address: 'Parappanangadi, Malappuram District, Kerala', point: LatLng(11.0450, 75.8560)),
  LocationSuggestion(name: 'Kondotty Airport Belt', address: 'Calicut Airport Road, Kondotty, Malappuram, Kerala', point: LatLng(11.1440, 75.9620)),
  LocationSuggestion(name: 'Vengara Town', address: 'Vengara Market, Malappuram District, Kerala', point: LatLng(11.0230, 75.9650)),
  LocationSuggestion(name: 'Nilambur Teak City', address: 'Nilambur Station Road, Malappuram District, Kerala', point: LatLng(11.2770, 76.2290)),
  LocationSuggestion(name: 'Wandoor Town Center', address: 'Wandoor Market, Malappuram District, Kerala', point: LatLng(11.1920, 76.2360)),
  LocationSuggestion(name: 'Edavanna Junction', address: 'Edavanna, Malappuram District, Kerala', point: LatLng(11.2180, 76.1280)),
  LocationSuggestion(name: 'Areacode Town', address: 'Areacode River Road, Malappuram District, Kerala', point: LatLng(11.2380, 76.0480)),
  LocationSuggestion(name: 'Mankada Village', address: 'Mankada Junction, Malappuram District, Kerala', point: LatLng(11.0180, 76.1720)),
  LocationSuggestion(name: 'Changuvetty Kottakkal', address: 'Changuvetty Bypass, Kottakkal, Malappuram, Kerala', point: LatLng(11.0060, 75.9890)),

  // KOZHIKODE DISTRICT (Calicut City, Coastline, Hill Country Villages)
  LocationSuggestion(name: 'Kozhikode Railway Station', address: 'Station Road, Kozhikode, Kerala', point: LatLng(11.2480, 75.7830)),
  LocationSuggestion(name: 'Mananchira Square', address: 'SM Street End, Kozhikode City, Kerala', point: LatLng(11.2520, 75.7800)),
  LocationSuggestion(name: 'Mavoor Road KSRTC Stand', address: 'Mavoor Road, Kozhikode, Kerala', point: LatLng(11.2580, 75.7900)),
  LocationSuggestion(name: 'Kozhikode Beach Promenade', address: 'Beach Road, Kozhikode, Kerala', point: LatLng(11.2610, 75.7700)),
  LocationSuggestion(name: 'Vadakara Town Center', address: 'Old Bus Stand, Vadakara, Kozhikode District, Kerala', point: LatLng(11.6080, 75.5910)),
  LocationSuggestion(name: 'Koyilandy Harbour & Town', address: 'National Highway, Koyilandy, Kozhikode, Kerala', point: LatLng(11.4390, 75.6960)),
  LocationSuggestion(name: 'Thamarassery Churam Base', address: 'Ghat Pass Road, Thamarassery, Kozhikode, Kerala', point: LatLng(11.4170, 75.9360)),
  LocationSuggestion(name: 'Koduvally Gold City', address: 'Koduvally Market, Kozhikode District, Kerala', point: LatLng(11.3560, 75.9080)),
  LocationSuggestion(name: 'Kunnamangalam IIM Belt', address: 'Wayand Road, Kunnamangalam, Kozhikode, Kerala', point: LatLng(11.3020, 75.8780)),
  LocationSuggestion(name: 'Mukkam Town', address: 'KMCT Campus Road, Mukkam, Kozhikode District, Kerala', point: LatLng(11.3190, 75.9860)),
  LocationSuggestion(name: 'Balussery Market Town', address: 'Balussery Junction, Kozhikode District, Kerala', point: LatLng(11.4500, 75.8300)),
  LocationSuggestion(name: 'Feroke Railway Station', address: 'Feroke Bridge, Kozhikode District, Kerala', point: LatLng(11.1760, 75.8280)),
  LocationSuggestion(name: 'Ramanattukara Bypass', address: 'Airport Road, Ramanattukara, Kozhikode, Kerala', point: LatLng(11.1780, 75.8670)),
  LocationSuggestion(name: 'Payyoli Beach Area', address: 'Payyoli Town, Kozhikode District, Kerala', point: LatLng(11.5230, 75.6200)),
  LocationSuggestion(name: 'Perambra Town', address: 'Perambra Market, Kozhikode District, Kerala', point: LatLng(11.5840, 75.7530)),

  // PALAKKAD DISTRICT (Major Towns, Border Belt & Agrarian Villages)
  LocationSuggestion(name: 'Palakkad Fort & KSRTC', address: 'Fort Maidan, Palakkad City, Kerala', point: LatLng(10.7760, 76.6540)),
  LocationSuggestion(name: 'Ottapalam Railway Station', address: 'Main Road, Ottapalam, Palakkad District, Kerala', point: LatLng(10.7720, 76.3770)),
  LocationSuggestion(name: 'Shoranur Railway Junction', address: 'Shoranur Town, Palakkad District, Kerala', point: LatLng(10.7600, 76.2800)),
  LocationSuggestion(name: 'Pattambi Town Center', address: 'Nila River Road, Pattambi, Palakkad District, Kerala', point: LatLng(10.8090, 76.1830)),
  LocationSuggestion(name: 'Cherpulassery Town', address: 'Bus Stand, Cherpulassery, Palakkad District, Kerala', point: LatLng(10.8750, 76.3150)),
  LocationSuggestion(name: 'Mannarkkad Market', address: 'Silent Valley Pass, Mannarkkad, Palakkad, Kerala', point: LatLng(10.9880, 76.4580)),
  LocationSuggestion(name: 'Alathur Swaraj Junction', address: 'Alathur Town, Palakkad District, Kerala', point: LatLng(10.6480, 76.5450)),
  LocationSuggestion(name: 'Nemmara Nelliampathy Gateway', address: 'Nemmara Town, Palakkad District, Kerala', point: LatLng(10.5890, 76.5980)),
  LocationSuggestion(name: 'Kollengode Heritage Palace', address: 'Kollengode, Palakkad District, Kerala', point: LatLng(10.6180, 76.6890)),
  LocationSuggestion(name: 'Chittur Sugar Factory Area', address: 'Chittur Town, Palakkad District, Kerala', point: LatLng(10.7020, 76.7410)),
  LocationSuggestion(name: 'Vadakkencherry Highway Town', address: 'NH544, Vadakkencherry, Palakkad, Kerala', point: LatLng(10.5980, 76.4950)),

  // OTHER KERALA DISTRICTS KEY TOWNS
  LocationSuggestion(name: 'Trivandrum Central Station', address: 'Thiruvananthapuram City, Kerala', point: LatLng(8.4870, 76.9530)),
  LocationSuggestion(name: 'Technopark Trivandrum', address: 'Kazhakkoottam, Thiruvananthapuram, Kerala', point: LatLng(8.5580, 76.8820)),
  LocationSuggestion(name: 'Attingal KSRTC Stand', address: 'Attingal, Thiruvananthapuram District, Kerala', point: LatLng(8.6960, 76.8140)),
  LocationSuggestion(name: 'Kollam Junction', address: 'Kollam City, Kerala', point: LatLng(8.8870, 76.5950)),
  LocationSuggestion(name: 'Karunagappally Town', address: 'Karunagappally, Kollam District, Kerala', point: LatLng(9.0550, 76.5360)),
  LocationSuggestion(name: 'Alappuzha KSRTC Stand', address: 'Alappuzha Town, Kerala', point: LatLng(9.4920, 76.3380)),
  LocationSuggestion(name: 'Cherthala Town', address: 'Cherthala, Alappuzha District, Kerala', point: LatLng(9.6840, 76.3310)),
  LocationSuggestion(name: 'Kottayam Station Road', address: 'Kottayam City, Kerala', point: LatLng(9.5910, 76.5250)),
  LocationSuggestion(name: 'Pala Town', address: 'Pala, Kottayam District, Kerala', point: LatLng(9.7120, 76.6840)),
  LocationSuggestion(name: 'Kannur Railway Station', address: 'Kannur City, Kerala', point: LatLng(11.8680, 75.3730)),
  LocationSuggestion(name: 'Thalassery Fort', address: 'Thalassery, Kannur District, Kerala', point: LatLng(11.7490, 75.4890)),
  LocationSuggestion(name: 'Kalpetta Town Center', address: 'Kalpetta, Wayanad, Kerala', point: LatLng(11.6090, 76.0820)),
  LocationSuggestion(name: 'Sulthan Bathery Market', address: 'Sulthan Bathery, Wayanad, Kerala', point: LatLng(11.6640, 76.2570)),
  LocationSuggestion(name: 'Thodupuzha Private Stand', address: 'Thodupuzha, Idukki District, Kerala', point: LatLng(9.8940, 76.7160)),
  LocationSuggestion(name: 'Munnar Town Center', address: 'Munnar, Idukki District, Kerala', point: LatLng(10.0880, 77.0600)),
  LocationSuggestion(name: 'Pathanamthitta Stand', address: 'Pathanamthitta Town, Kerala', point: LatLng(9.2640, 76.7870)),
  LocationSuggestion(name: 'Kasaragod Railway Station', address: 'Kasaragod Town, Kerala', point: LatLng(12.4980, 74.9890)),
  LocationSuggestion(name: 'Kanhangad Town', address: 'Kanhangad, Kasaragod District, Kerala', point: LatLng(12.3160, 75.0920)),
];

void showVendorRouteManagerModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const VendorRouteManagerWidget(),
  );
}

class VendorRouteManagerWidget extends StatelessWidget {
  const VendorRouteManagerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VendorHomeBloc, VendorHomeState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.alt_route, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Kerala Selling Routes',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.outline),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Select an active Kerala route or create a new route across Kerala:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.outline,
                ),
              ),
              const SizedBox(height: 16),
              // List of Saved Routes
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.savedRoutes.length,
                  itemBuilder: (context, index) {
                    final route = state.savedRoutes[index];
                    final isActive = route.isActive;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? AppColors.primary : AppColors.surfaceContainerHigh,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  context.read<VendorHomeBloc>().add(VendorSelectRoute(route.id));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Active selling route set to "${route.name}"',
                                        style: GoogleFonts.plusJakartaSans(color: Colors.white),
                                      ),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Icon(
                                    isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: isActive ? AppColors.primary : AppColors.outline,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            route.name,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.onSurface,
                                            ),
                                          ),
                                        ),
                                        if (isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'ACTIVE',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      route.description,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: AppColors.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                onPressed: () {
                                  Navigator.pop(context);
                                  showVendorRouteEditorModal(context, existingRoute: route);
                                },
                              ),
                              if (state.savedRoutes.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                  onPressed: () {
                                    context.read<VendorHomeBloc>().add(VendorDeleteRoute(route.id));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Route "${route.name}" deleted', style: GoogleFonts.plusJakartaSans()),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Waypoints Path Chip Chain
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: route.waypoints.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final wp = entry.value;
                                return Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: wp.isStart
                                            ? Colors.green.withValues(alpha: 0.1)
                                            : wp.isEnd
                                                ? Colors.red.withValues(alpha: 0.1)
                                                : AppColors.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${wp.isStart ? "🚩 " : wp.isEnd ? "🏁 " : ""}${wp.name}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: wp.isStart
                                              ? Colors.green.shade800
                                              : wp.isEnd
                                                  ? Colors.red.shade800
                                                  : AppColors.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (idx < route.waypoints.length - 1)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(Icons.arrow_forward, size: 12, color: AppColors.outline),
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Add New Route Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showVendorRouteEditorModal(context);
                  },
                  icon: const Icon(Icons.add_location_alt, size: 20),
                  label: Text(
                    'Create New Route with Kerala Map Places',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Map Waypoint Step-by-Step Interactive Editor Modal
void showVendorRouteEditorModal(BuildContext context, {VendorRoute? existingRoute}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => VendorRouteEditorWidget(existingRoute: existingRoute),
  );
}

class VendorRouteEditorWidget extends StatefulWidget {
  final VendorRoute? existingRoute;
  const VendorRouteEditorWidget({super.key, this.existingRoute});

  @override
  State<VendorRouteEditorWidget> createState() => _VendorRouteEditorWidgetState();
}

class _VendorRouteEditorWidgetState extends State<VendorRouteEditorWidget> {
  late TextEditingController _routeNameController;
  late TextEditingController _searchController;
  final MapController _mapController = MapController();

  // Creation Steps: 1 = Start Point, 2 = End Point, 3 = Intermediate Waypoints
  int _currentStep = 1;

  RouteWaypoint? _startWaypoint;
  RouteWaypoint? _endWaypoint;
  final List<RouteWaypoint> _intermediateWaypoints = [];
  List<LocationSuggestion> _filteredSuggestions = _keralaLocations;
  bool _isSearchingOnline = false;
  bool _isLoadingRoute = false;

  // Real OSRM Road Path Coordinates
  List<LatLng> _roadPolylinePoints = [];

  @override
  void initState() {
    super.initState();
    _routeNameController = TextEditingController(
      text: widget.existingRoute?.name ?? 'Kerala Route #${DateTime.now().second}',
    );
    _searchController = TextEditingController();

    if (widget.existingRoute != null) {
      final wps = widget.existingRoute!.waypoints;
      _startWaypoint = wps.firstWhere((w) => w.isStart, orElse: () => wps.first);
      _endWaypoint = wps.firstWhere((w) => w.isEnd, orElse: () => wps.last);
      _intermediateWaypoints.addAll(wps.where((w) => !w.isStart && !w.isEnd));
      _currentStep = 3;
      _fetchRealRoadRoute();
    }
  }

  Future<void> _fetchRealRoadRoute() async {
    final waypoints = _allSequentialWaypoints;
    if (waypoints.length < 2) {
      if (mounted) {
        setState(() {
          _roadPolylinePoints = waypoints.map((w) => w.point).toList();
          _isLoadingRoute = false;
        });
      }
      return;
    }

    // Format OSRM coordinate string: lon1,lat1;lon2,lat2;lon3,lat3
    final coordsString = waypoints
        .map((w) => '${w.point.longitude},${w.point.latitude}')
        .join(';');

    if (mounted) {
      setState(() {
        _isLoadingRoute = true;
      });
    }

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordsString?overview=full&geometries=geojson'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          final coordinates = geometry['coordinates'] as List;

          final List<LatLng> roadPoints = coordinates.map((c) {
            final lon = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lon);
          }).toList();

          if (mounted) {
            setState(() {
              _roadPolylinePoints = roadPoints;
              _isLoadingRoute = false;
            });
            return;
          }
        }
      }
    } catch (_) {
      // Fallback straight line
    }

    if (mounted) {
      setState(() {
        _roadPolylinePoints = waypoints.map((w) => w.point).toList();
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _filterLocations(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      setState(() {
        _filteredSuggestions = _keralaLocations;
        _isSearchingOnline = false;
      });
      return;
    }

    final localMatches = _keralaLocations
        .where((loc) =>
            loc.name.toLowerCase().contains(cleanQuery.toLowerCase()) ||
            loc.address.toLowerCase().contains(cleanQuery.toLowerCase()))
        .toList();

    setState(() {
      _filteredSuggestions = localMatches;
      _isSearchingOnline = true;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(cleanQuery)},+Kerala,+India&limit=6'
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'OnWayVendorApp/1.0 (com.onway.vendor)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final List<LocationSuggestion> onlineResults = [];

        for (var item in data) {
          final lat = double.tryParse(item['lat'].toString());
          final lon = double.tryParse(item['lon'].toString());
          final displayName = item['display_name'] as String? ?? cleanQuery;

          if (lat != null && lon != null) {
            final parts = displayName.split(',');
            final title = parts.isNotEmpty ? parts.first.trim() : cleanQuery;
            final address = parts.length > 1 ? parts.sublist(1).take(3).join(',').trim() : 'Kerala, India';

            onlineResults.add(LocationSuggestion(
              name: title,
              address: address,
              point: LatLng(lat, lon),
            ));
          }
        }

        if (mounted) {
          setState(() {
            final existingNames = localMatches.map((l) => l.name.toLowerCase()).toSet();
            final newOnline = onlineResults.where((r) => !existingNames.contains(r.name.toLowerCase())).toList();
            _filteredSuggestions = [...localMatches, ...newOnline];
            _isSearchingOnline = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSearchingOnline = false;
        });
      }
    }
  }

  void _selectLocationSuggestion(LocationSuggestion loc) {
    _searchController.text = loc.name;
    FocusScope.of(context).unfocus();
    _setPointForCurrentStep(loc.point, name: loc.name);
  }

  void _setPointForCurrentStep(LatLng point, {String? name}) {
    final locationName = name ?? 'Kerala Location (${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)})';

    setState(() {
      if (_currentStep == 1) {
        _startWaypoint = RouteWaypoint(
          id: 'start_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Start: $locationName',
          point: point,
          isStart: true,
        );
      } else if (_currentStep == 2) {
        _endWaypoint = RouteWaypoint(
          id: 'end_${DateTime.now().millisecondsSinceEpoch}',
          name: 'End: $locationName',
          point: point,
          isEnd: true,
        );
      } else {
        _intermediateWaypoints.add(RouteWaypoint(
          id: 'waypoint_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Stop #${_intermediateWaypoints.length + 1}: $locationName',
          point: point,
        ));
      }
      _searchController.clear();
      _filteredSuggestions = _keralaLocations;
    });

    _mapController.move(point, 14.5);
    _fetchRealRoadRoute();
  }

  List<RouteWaypoint> get _allSequentialWaypoints {
    final List<RouteWaypoint> list = [];
    if (_startWaypoint != null) list.add(_startWaypoint!);
    list.addAll(_intermediateWaypoints);
    if (_endWaypoint != null) list.add(_endWaypoint!);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final allWaypoints = _allSequentialWaypoints;
    final activeRoadPoints = _roadPolylinePoints.isNotEmpty
        ? _roadPolylinePoints
        : allWaypoints.map((w) => w.point).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header title & close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingRoute == null ? 'Create Kerala Route' : 'Edit Kerala Route',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.outline),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Route Title Input Field
            TextField(
              controller: _routeNameController,
              decoration: InputDecoration(
                labelText: 'Route Name (e.g. Chittattukara - Elavally Belt)',
                prefixIcon: const Icon(Icons.edit_road, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            // Step Progress Bar (Step 1: Start -> Step 2: End -> Step 3: Waypoints)
            Row(
              children: [
                Expanded(
                  child: _buildStepBadge(step: 1, title: '1. Start Point', color: Colors.green, isActive: _currentStep == 1),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStepBadge(step: 2, title: '2. End Point', color: Colors.red, isActive: _currentStep == 2),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStepBadge(step: 3, title: '3. Waypoints', color: AppColors.primary, isActive: _currentStep == 3),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Search Bar for Location Search on Map
            TextField(
              controller: _searchController,
              onChanged: _filterLocations,
              decoration: InputDecoration(
                hintText: _currentStep == 1
                    ? 'Search Village (Chittattukara, Brahmamkulam...)'
                    : _currentStep == 2
                        ? 'Search Destination (Elavally, Choondal...)'
                        : 'Search Waypoint Location in Thrissur...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _isSearchingOnline
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _filterLocations('');
                            },
                          )
                        : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            // Instant Search Suggestions Dropdown
            if (_searchController.text.isNotEmpty && _filteredSuggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredSuggestions.length,
                    itemBuilder: (context, index) {
                      final loc = _filteredSuggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on, size: 18, color: AppColors.primary),
                        title: Text(loc.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(loc.address, style: GoogleFonts.plusJakartaSans(fontSize: 11)),
                        onTap: () => _selectLocationSuggestion(loc),
                      );
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Interactive Map Box with Real OSRM Road Route
            Stack(
              children: [
                Container(
                  height: 440,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _currentStep == 1
                          ? Colors.green
                          : _currentStep == 2
                              ? Colors.red
                              : AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: allWaypoints.isNotEmpty
                            ? allWaypoints.first.point
                            : const LatLng(10.5890, 76.0450), // Chittattukara / Thrissur center
                        initialZoom: 13.5,
                        onTap: (tapPos, latLng) {
                          _setPointForCurrentStep(latLng);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.onway.vendor',
                        ),
                        if (activeRoadPoints.length >= 2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: activeRoadPoints,
                                color: AppColors.primary,
                                strokeWidth: 5.0,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: allWaypoints.map((wp) {
                            final isStart = wp.isStart;
                            final isEnd = wp.isEnd;
                            return Marker(
                              point: wp.point,
                              width: 38,
                              height: 38,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isStart
                                      ? Colors.green
                                      : isEnd
                                          ? Colors.red
                                          : AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: Icon(
                                  isStart
                                      ? Icons.flag
                                      : isEnd
                                          ? Icons.sports_score
                                          : Icons.location_on,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoadingRoute)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Fetching Real Road Route...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Route Chain Summary Badges
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: allWaypoints.map((wp) {
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    child: Chip(
                      avatar: Icon(
                        wp.isStart ? Icons.flag : wp.isEnd ? Icons.sports_score : Icons.pin_drop,
                        size: 14,
                        color: wp.isStart ? Colors.green : wp.isEnd ? Colors.red : AppColors.primary,
                      ),
                      label: Text(wp.name, style: GoogleFonts.plusJakartaSans(fontSize: 11)),
                      onDeleted: !wp.isStart && !wp.isEnd
                          ? () {
                              setState(() {
                                _intermediateWaypoints.removeWhere((w) => w.id == wp.id);
                              });
                              _fetchRealRoadRoute();
                            }
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Step Action Controls (Next Step / Confirm Route Line)
            Row(
              children: [
                if (_currentStep > 1)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      child: const Text('Back Step'),
                    ),
                  ),
                if (_currentStep > 1) const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_currentStep == 1) {
                        if (_startWaypoint == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please search or select a Starting Point in Thrissur', style: GoogleFonts.plusJakartaSans())),
                          );
                          return;
                        }
                        setState(() => _currentStep = 2);
                      } else if (_currentStep == 2) {
                        if (_endWaypoint == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please search or select an Ending Point in Thrissur', style: GoogleFonts.plusJakartaSans())),
                          );
                          return;
                        }
                        setState(() => _currentStep = 3);
                      } else {
                        // Final Step: Save & Confirm Route Line
                        final routeName = _routeNameController.text.trim();
                        if (routeName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please enter a route name', style: GoogleFonts.plusJakartaSans())),
                          );
                          return;
                        }
                        final newRoute = VendorRoute(
                          id: widget.existingRoute?.id ?? 'r_${DateTime.now().millisecondsSinceEpoch}',
                          name: routeName,
                          description: '${allWaypoints.length} Waypoints • Real Road Path Verified',
                          waypoints: allWaypoints,
                          customRoadPolyline: activeRoadPoints,
                          isActive: true,
                        );

                        if (widget.existingRoute != null) {
                          context.read<VendorHomeBloc>().add(VendorUpdateRoute(newRoute));
                        } else {
                          context.read<VendorHomeBloc>().add(VendorSaveNewRoute(newRoute));
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Real Road Route "$routeName" saved and activated!', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      _currentStep < 3 ? Icons.arrow_forward : Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: Text(
                      _currentStep == 1
                          ? 'Next: End Point ➔'
                          : _currentStep == 2
                              ? 'Next: Waypoints ➔'
                              : 'Confirm & Save Real Road Route ✅',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStep == 1
                          ? Colors.green
                          : _currentStep == 2
                              ? Colors.red
                              : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBadge({required int step, required String title, required Color color, required bool isActive}) {
    return GestureDetector(
      onTap: () {
        if (step == 1 || (step == 2 && _startWaypoint != null) || (step == 3 && _startWaypoint != null && _endWaypoint != null)) {
          setState(() => _currentStep = step);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color : AppColors.surfaceContainer,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? color : AppColors.outline,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
