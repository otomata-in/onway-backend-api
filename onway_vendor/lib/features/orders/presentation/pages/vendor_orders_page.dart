import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/bloc/vendor_home_bloc.dart';
import '../../../home/presentation/bloc/vendor_home_event.dart';
import '../../../home/presentation/bloc/vendor_home_state.dart';

class VendorOrdersPage extends StatefulWidget {
  final VendorHomeState state;
  const VendorOrdersPage({super.key, required this.state});

  @override
  State<VendorOrdersPage> createState() => _VendorOrdersPageState();
}

class _VendorOrdersPageState extends State<VendorOrdersPage> {
  // Filter States
  String _searchQuery = '';
  String _timeRange = 'All Time'; // 'All Time', 'Today', 'Yesterday', 'Last Week', 'Last Month', 'Custom'
  DateTimeRange? _customDateRange;

  String _hourSlot = 'All Hours'; // 'All Hours', 'Morning', 'Afternoon', 'Evening', 'Custom'
  RangeValues _hourRange = const RangeValues(0, 24);

  String _selectedWaypoint = 'All Waypoints';
  double _maxDistanceRadius = 5000; // 100m to 5000m

  String _selectedStatus = 'All Statuses'; // 'All Statuses', 'Completed', 'Pending', 'Missed'

  bool _isFilterDrawerExpanded = false;

  late List<BuyerEnquiry> _allHistoricalOrders;

  @override
  void initState() {
    super.initState();
    _initHistoricalOrders();
  }

  void _initHistoricalOrders() {
    final now = DateTime.now();

    // Comprehensive mock historical dataset combining live state with historical records
    _allHistoricalOrders = [
      ...widget.state.enquiries,
      BuyerEnquiry(
        enquiryId: 'ENQ-106',
        buyerName: 'Deepak V',
        buyerPhone: '+91 98470 11223',
        itemsSummary: '4x Farm Tomatoes, 2kg Onions',
        distanceMeters: 140,
        timeAgo: 'Yesterday 10:15 AM',
        status: 'Completed',
        waypointName: 'Marine Drive Kochi',
        priceAmount: 620.0,
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      BuyerEnquiry(
        enquiryId: 'ENQ-107',
        buyerName: 'Kavya Ramesh',
        buyerPhone: '+91 97455 33445',
        itemsSummary: '1kg Red Bell Peppers, 500g Garlic',
        distanceMeters: 450,
        timeAgo: 'Yesterday 3:30 PM',
        status: 'Completed',
        waypointName: 'Lulu Mall Edappally',
        priceAmount: 840.0,
        timestamp: now.subtract(const Duration(days: 1, hours: 8)),
      ),
      BuyerEnquiry(
        enquiryId: 'ENQ-108',
        buyerName: 'Firoz Khan',
        buyerPhone: '+91 94471 99887',
        itemsSummary: '3x Organic Spinach, 2kg Potatoes',
        distanceMeters: 1200,
        timeAgo: '3 days ago 6:45 PM',
        status: 'Missed',
        waypointName: 'Aluva Railway Station',
        priceAmount: 530.0,
        timestamp: now.subtract(const Duration(days: 3, hours: 5)),
      ),
      BuyerEnquiry(
        enquiryId: 'ENQ-109',
        buyerName: 'Sunil Menon',
        buyerPhone: '+91 99612 88776',
        itemsSummary: '5kg Farm Tomatoes, 2kg Carrots',
        distanceMeters: 310,
        timeAgo: '5 days ago 11:20 AM',
        status: 'Completed',
        waypointName: 'Thrissur Swaraj Round',
        priceAmount: 1150.0,
        timestamp: now.subtract(const Duration(days: 5, hours: 3)),
      ),
      BuyerEnquiry(
        enquiryId: 'ENQ-110',
        buyerName: 'Amina Beegum',
        buyerPhone: '+91 98950 44332',
        itemsSummary: '2x Organic Spinach, 1kg Ginger',
        distanceMeters: 780,
        timeAgo: '6 days ago 8:15 AM',
        status: 'Completed',
        waypointName: 'Guruvayur Temple Gate',
        priceAmount: 420.0,
        timestamp: now.subtract(const Duration(days: 6, hours: 10)),
      ),
      BuyerEnquiry(
        enquiryId: 'ENQ-111',
        buyerName: 'Viju Kurup',
        buyerPhone: '+91 94000 12345',
        itemsSummary: '1kg Tomatoes, 1kg Onions, 500g Chilli',
        distanceMeters: 2100,
        timeAgo: '10 days ago 4:00 PM',
        status: 'Missed',
        waypointName: 'Manjeri Town Center',
        priceAmount: 310.0,
        timestamp: now.subtract(const Duration(days: 10, hours: 4)),
      ),
    ];
  }

  List<BuyerEnquiry> _getFilteredOrders() {
    final now = DateTime.now();

    return _allHistoricalOrders.where((enq) {
      // 1. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = enq.buyerName.toLowerCase().contains(query);
        final matchesPhone = enq.buyerPhone.contains(query);
        final matchesId = enq.enquiryId.toLowerCase().contains(query);
        final matchesItems = enq.itemsSummary.toLowerCase().contains(query);
        if (!matchesName && !matchesPhone && !matchesId && !matchesItems) {
          return false;
        }
      }

      // 2. Status Filter
      if (_selectedStatus != 'All Statuses') {
        if (enq.status != _selectedStatus) {
          return false;
        }
      }

      // 3. Waypoint & Distance Filter
      if (_selectedWaypoint != 'All Waypoints') {
        if (enq.waypointName != _selectedWaypoint) {
          return false;
        }
      }
      if (enq.distanceMeters > _maxDistanceRadius) {
        return false;
      }

      // 4. Time Range Filter
      final orderTime = enq.timestamp ?? now;
      if (_timeRange == 'Today') {
        final isToday = orderTime.year == now.year &&
            orderTime.month == now.month &&
            orderTime.day == now.day;
        if (!isToday) return false;
      } else if (_timeRange == 'Yesterday') {
        final yesterday = now.subtract(const Duration(days: 1));
        final isYesterday = orderTime.year == yesterday.year &&
            orderTime.month == yesterday.month &&
            orderTime.day == yesterday.day;
        if (!isYesterday) return false;
      } else if (_timeRange == 'Last Week') {
        final lastWeek = now.subtract(const Duration(days: 7));
        if (orderTime.isBefore(lastWeek)) return false;
      } else if (_timeRange == 'Last Month') {
        final lastMonth = now.subtract(const Duration(days: 30));
        if (orderTime.isBefore(lastMonth)) return false;
      } else if (_timeRange == 'Custom' && _customDateRange != null) {
        if (orderTime.isBefore(_customDateRange!.start) ||
            orderTime.isAfter(_customDateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // 5. Hour-Wise Filter
      final hour = orderTime.hour;
      if (_hourSlot == 'Morning') {
        if (hour < 6 || hour >= 12) return false;
      } else if (_hourSlot == 'Afternoon') {
        if (hour < 12 || hour >= 17) return false;
      } else if (_hourSlot == 'Evening') {
        if (hour < 17 || hour >= 22) return false;
      } else if (_hourSlot == 'Custom') {
        if (hour < _hourRange.start || hour > _hourRange.end) return false;
      }

      return true;
    }).toList();
  }

  void _resetAllFilters() {
    setState(() {
      _searchQuery = '';
      _timeRange = 'All Time';
      _customDateRange = null;
      _hourSlot = 'All Hours';
      _hourRange = const RangeValues(0, 24);
      _selectedWaypoint = 'All Waypoints';
      _maxDistanceRadius = 5000;
      _selectedStatus = 'All Statuses';
    });
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (_timeRange != 'All Time') count++;
    if (_hourSlot != 'All Hours') count++;
    if (_selectedWaypoint != 'All Waypoints') count++;
    if (_maxDistanceRadius < 5000) count++;
    if (_selectedStatus != 'All Statuses') count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _getFilteredOrders();
    final totalRevenue = filteredOrders.fold<double>(
        0, (sum, item) => sum + (item.status == 'Completed' ? item.priceAmount : 0));
    final completedCount =
        filteredOrders.where((e) => e.status == 'Completed').length;
    final successRate = filteredOrders.isNotEmpty
        ? ((completedCount / filteredOrders.length) * 100).round()
        : 0;

    final activeFilterCount = _getActiveFilterCount();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── PAGE TITLE & ANALYTICS SUMMARY HEADER ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order History & Analytics',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Historical buyer enquiries with smart multi-filtering',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_edu_rounded, color: AppColors.primary, size: 22),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── ANALYTICS SUMMARY CARD ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // 1. Total Filtered Orders
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orders Found',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${filteredOrders.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 30, width: 1, color: Colors.grey.shade800),
                // 2. Filtered Revenue
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Filtered Value',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${totalRevenue.toInt()}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4ADE80),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 30, width: 1, color: Colors.grey.shade800),
                // 3. Success Rate
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Fulfillment Rate',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$successRate%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF60A5FA),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── SENIOR-FRIENDLY QUICK TIME FILTER BAR (Today, Yesterday, Last Week, Last Month, Custom) ──
          _buildSeniorFriendlyQuickTimeFilters(context),

          const SizedBox(height: 16),

          // ── SEARCH BAR & FILTER TOGGLE BUTTON ──
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceContainerHigh),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search buyer name, phone, item...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.outline),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Filter Controls Drawer Button
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isFilterDrawerExpanded = !_isFilterDrawerExpanded);
                },
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(
                  activeFilterCount > 0 ? 'Filters ($activeFilterCount)' : 'Filter ⚙️',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeFilterCount > 0 ? AppColors.primary : Colors.white,
                  foregroundColor: activeFilterCount > 0 ? Colors.white : AppColors.onSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: activeFilterCount > 0 ? AppColors.primary : AppColors.surfaceContainerHigh,
                    ),
                  ),
                  elevation: activeFilterCount > 0 ? 2 : 0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── EXPANDABLE ADVANCED FILTRATION MODULE ──
          if (_isFilterDrawerExpanded) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.filter_list_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Smart Filtration Module',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      if (activeFilterCount > 0)
                        TextButton(
                          onPressed: _resetAllFilters,
                          child: Text(
                            'Reset All',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE11D48),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),

                  // ── FILTER SECTION 1: TIME RANGE FILTER ──
                  Text(
                    '1. Time Range Filter',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'All Time',
                      'Today',
                      'Yesterday',
                      'Last Week',
                      'Last Month',
                      'Custom Calendar Pick',
                    ].map((label) {
                      final isSelected = _timeRange == (label == 'Custom Calendar Pick' ? 'Custom' : label);
                      return ChoiceChip(
                        label: Text(
                          label == 'Custom Calendar Pick' && _customDateRange != null
                              ? '${DateFormat('MMM d').format(_customDateRange!.start)} - ${DateFormat('MMM d').format(_customDateRange!.end)} 📅'
                              : label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.onSurface,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) async {
                          if (label == 'Custom Calendar Pick') {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2025),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _timeRange = 'Custom';
                                _customDateRange = picked;
                              });
                            }
                          } else {
                            setState(() {
                              _timeRange = label;
                              _customDateRange = null;
                            });
                          }
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // ── FILTER SECTION 2: HOUR-WISE FILTER ──
                  Text(
                    '2. Hour-Wise Time Slot Filter',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'All Hours',
                      'Morning (6-12)',
                      'Afternoon (12-5)',
                      'Evening (5-10)',
                      'Custom Hour Range',
                    ].map((slot) {
                      final isSelected = _hourSlot == (slot == 'Morning (6-12)'
                          ? 'Morning'
                          : slot == 'Afternoon (12-5)'
                              ? 'Afternoon'
                              : slot == 'Evening (5-10)'
                                  ? 'Evening'
                                  : slot == 'Custom Hour Range'
                                      ? 'Custom'
                                      : slot);

                      return ChoiceChip(
                        label: Text(
                          slot,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.onSurface,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _hourSlot = slot == 'Morning (6-12)'
                                ? 'Morning'
                                : slot == 'Afternoon (12-5)'
                                    ? 'Afternoon'
                                    : slot == 'Evening (5-10)'
                                        ? 'Evening'
                                        : slot == 'Custom Hour Range'
                                            ? 'Custom'
                                            : slot;
                          });
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      );
                    }).toList(),
                  ),

                  if (_hourSlot == 'Custom') ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hour Range: ${_hourRange.start.toInt()}:00 - ${_hourRange.end.toInt()}:00',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _hourRange,
                      min: 0,
                      max: 24,
                      divisions: 24,
                      activeColor: AppColors.primary,
                      labels: RangeLabels(
                        '${_hourRange.start.toInt()}:00',
                        '${_hourRange.end.toInt()}:00',
                      ),
                      onChanged: (values) {
                        setState(() => _hourRange = values);
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── FILTER SECTION 3: WAYPOINT LOCATION & DISTANCE RADIUS FILTER ──
                  Text(
                    '3. Waypoint Location & Distance Radius Filter',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Waypoint Selector Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAF8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceContainerHigh),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWaypoint,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                        items: [
                          'All Waypoints',
                          'Ernakulam South Station',
                          'Marine Drive Kochi',
                          'Lulu Mall Edappally',
                          'Aluva Railway Station',
                          'Thrissur Swaraj Round',
                          'Guruvayur Temple Gate',
                          'Manjeri Town Center',
                        ].map((wp) {
                          return DropdownMenuItem(
                            value: wp,
                            child: Text(wp),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedWaypoint = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Max Distance Radius:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.outline,
                        ),
                      ),
                      Text(
                        '< ${_maxDistanceRadius.toInt()}m',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _maxDistanceRadius,
                    min: 100,
                    max: 5000,
                    divisions: 49,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _maxDistanceRadius = val);
                    },
                  ),

                  const SizedBox(height: 12),

                  // ── FILTER SECTION 4: ORDER STATUS FILTER ──
                  Text(
                    '4. Order Status Filter',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      'All Statuses',
                      'Completed',
                      'Pending',
                      'Missed',
                    ].map((status) {
                      final isSelected = _selectedStatus == status;
                      final icon = status == 'Completed'
                          ? '✅'
                          : status == 'Pending'
                              ? '⏳'
                              : status == 'Missed'
                                  ? '❌'
                                  : '';
                      return ChoiceChip(
                        label: Text(
                          '$status $icon',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.onSurface,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedStatus = status);
                        },
                        selectedColor: status == 'Completed'
                            ? const Color(0xFF16A34A)
                            : status == 'Missed'
                                ? const Color(0xFFE11D48)
                                : AppColors.primary,
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── APPLIED FILTER BADGES BAR ──
          if (activeFilterCount > 0) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_timeRange != 'All Time')
                    _buildFilterBadge('Time: $_timeRange', () => setState(() => _timeRange = 'All Time')),
                  if (_hourSlot != 'All Hours')
                    _buildFilterBadge('Hour: $_hourSlot', () => setState(() => _hourSlot = 'All Hours')),
                  if (_selectedWaypoint != 'All Waypoints')
                    _buildFilterBadge('Waypoint: $_selectedWaypoint', () => setState(() => _selectedWaypoint = 'All Waypoints')),
                  if (_maxDistanceRadius < 5000)
                    _buildFilterBadge('Radius: <${_maxDistanceRadius.toInt()}m', () => setState(() => _maxDistanceRadius = 5000)),
                  if (_selectedStatus != 'All Statuses')
                    _buildFilterBadge('Status: $_selectedStatus', () => setState(() => _selectedStatus = 'All Statuses')),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── HISTORICAL ORDER ITEMS LIST ──
          if (filteredOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.surfaceContainerHigh),
              ),
              child: Column(
                children: [
                  const Icon(Icons.filter_alt_off_rounded, size: 48, color: AppColors.outline),
                  const SizedBox(height: 12),
                  Text(
                    'No historical orders match your filters',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try broadening your distance radius or time range.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _resetAllFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reset All Filters'),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final enquiry = filteredOrders[index];
                final isCompleted = enquiry.status == 'Completed';
                final isMissed = enquiry.status == 'Missed';
                final isUnder250m = enquiry.distanceMeters <= 250 && enquiry.status == 'Pending';

                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isMissed
                            ? const Color(0xFFFFF1F2)
                            : (isCompleted ? const Color(0xFFF0FDF4) : Colors.white),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isMissed
                              ? const Color(0xFFFECDD3)
                              : (isCompleted
                                  ? Colors.green.shade500
                                  : (isUnder250m ? AppColors.primary : AppColors.surfaceContainerHigh)),
                          width: isMissed || isCompleted || isUnder250m ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isMissed
                                ? const Color(0xFFE11D48).withValues(alpha: 0.08)
                                : (isCompleted
                                    ? Colors.green.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.03)),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: ID, Price & Status Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                enquiry.enquiryId,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isMissed
                                      ? const Color(0xFFFFE4E6)
                                      : (isCompleted
                                          ? const Color(0xFFDCFCE7)
                                          : Colors.amber.withValues(alpha: 0.15)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  enquiry.status.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isMissed
                                        ? const Color(0xFFE11D48)
                                        : (isCompleted
                                            ? const Color(0xFF15803D)
                                            : Colors.amber.shade900),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Buyer Info & Waypoint Location
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person, size: 16, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        enquiry.buyerName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      Text(
                                        enquiry.buyerPhone,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppColors.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                                      const SizedBox(width: 2),
                                      Text(
                                        enquiry.waypointName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${enquiry.distanceMeters}m away • ${enquiry.timeAgo}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Items Summary
                          Text(
                            'Requested Items:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.outline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            enquiry.itemsSummary,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),

                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),

                          // Interactive Status Controls
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isUnder250m
                                      ? () {
                                          context.read<VendorHomeBloc>().add(
                                                VendorRingBuyer(enquiry.enquiryId, enquiry.buyerName),
                                              );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('🔔 Ringing ${enquiry.buyerName}!',
                                                  style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                                              backgroundColor: const Color(0xFF16A34A),
                                            ),
                                          );
                                        }
                                      : null,
                                  icon: const Icon(Icons.notifications_active, size: 16),
                                  label: Text(
                                    isCompleted
                                        ? 'Completed ✅'
                                        : isMissed
                                            ? 'Missed ❌'
                                            : isUnder250m
                                                ? 'Ring Buyer 🔔'
                                                : '<250m to Ring',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isCompleted
                                        ? Colors.green.shade700
                                        : isMissed
                                            ? const Color(0xFFFFE4E6)
                                            : (isUnder250m ? AppColors.primary : Colors.grey.shade300),
                                    foregroundColor: isCompleted || isUnder250m ? Colors.white : Colors.grey.shade700,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                onPressed: () {
                                  context.read<VendorHomeBloc>().add(
                                        VendorUpdateEnquiryStatus(enquiry.enquiryId, 'Completed'),
                                      );
                                  setState(() {
                                    final idx = _allHistoricalOrders.indexWhere((e) => e.enquiryId == enquiry.enquiryId);
                                    if (idx != -1) {
                                      _allHistoricalOrders[idx] = enquiry.copyWith(status: 'Completed');
                                    }
                                  });
                                },
                                icon: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                                tooltip: 'Mark Completed',
                              ),
                              IconButton(
                                onPressed: () {
                                  context.read<VendorHomeBloc>().add(
                                        VendorUpdateEnquiryStatus(enquiry.enquiryId, 'Pending'),
                                      );
                                  setState(() {
                                    final idx = _allHistoricalOrders.indexWhere((e) => e.enquiryId == enquiry.enquiryId);
                                    if (idx != -1) {
                                      _allHistoricalOrders[idx] = enquiry.copyWith(status: 'Pending');
                                    }
                                  });
                                },
                                icon: const Icon(Icons.history_toggle_off, color: Colors.orange, size: 24),
                                tooltip: 'Mark Pending',
                              ),
                              IconButton(
                                onPressed: () {
                                  context.read<VendorHomeBloc>().add(
                                        VendorUpdateEnquiryStatus(enquiry.enquiryId, 'Missed'),
                                      );
                                  setState(() {
                                    final idx = _allHistoricalOrders.indexWhere((e) => e.enquiryId == enquiry.enquiryId);
                                    if (idx != -1) {
                                      _allHistoricalOrders[idx] = enquiry.copyWith(status: 'Missed');
                                    }
                                  });
                                },
                                icon: const Icon(Icons.cancel_rounded, color: Color(0xFFE11D48), size: 24),
                                tooltip: 'Mark Missed',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Transparent Big Tick Watermark Layer for Completed Orders
                    if (isCompleted)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 36, bottom: 20),
                              child: Opacity(
                                opacity: 0.15,
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 110,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Transparent Big Cross Watermark Layer for Missed Orders
                    if (isMissed)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 36, bottom: 20),
                              child: Opacity(
                                opacity: 0.15,
                                child: const Icon(
                                  Icons.cancel_rounded,
                                  size: 110,
                                  color: Color(0xFFE11D48),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 100), // padding for bottom bar
        ],
      ),
    );
  }

  Widget _buildSeniorFriendlyQuickTimeFilters(BuildContext context) {
    final filters = [
      {'id': 'Today', 'label': 'Today', 'icon': Icons.today_rounded},
      {'id': 'Yesterday', 'label': 'Yesterday', 'icon': Icons.history_rounded},
      {'id': 'Last Week', 'label': 'Last Week', 'icon': Icons.calendar_view_week_rounded},
      {'id': 'Last Month', 'label': 'Last Month', 'icon': Icons.calendar_month_rounded},
      {'id': 'Custom', 'label': 'Custom Date', 'icon': Icons.date_range_rounded},
      {'id': 'All Time', 'label': 'All Time', 'icon': Icons.all_inclusive_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.touch_app_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'EASY DATE FILTER',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            if (_timeRange != 'All Time')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Active: $_timeRange',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: filters.map((item) {
              final id = item['id'] as String;
              final label = item['label'] as String;
              final icon = item['icon'] as IconData;
              final isSelected = _timeRange == id;

              String displayLabel = label;
              if (id == 'Custom' && _customDateRange != null) {
                displayLabel =
                    '${DateFormat('MMM d').format(_customDateRange!.start)} - ${DateFormat('MMM d').format(_customDateRange!.end)}';
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (id == 'Custom') {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2025),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _timeRange = 'Custom';
                            _customDateRange = picked;
                          });
                        }
                      } else {
                        setState(() {
                          _timeRange = id;
                          _customDateRange = null;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceContainerHigh,
                          width: isSelected ? 2 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: isSelected ? 8 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            displayLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBadge(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
