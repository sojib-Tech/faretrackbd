import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../services/route_finder_service.dart';

class RouteSearchScreen extends StatefulWidget {
  const RouteSearchScreen({super.key});

  @override
  State<RouteSearchScreen> createState() => _RouteSearchScreenState();
}

class _RouteSearchScreenState extends State<RouteSearchScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();
  List<RouteSuggestion> _results = [];
  bool _searched = false;
  bool _loading = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  void _swap() {
    final temp = _fromController.text;
    setState(() {
      _fromController.text = _toController.text;
      _toController.text = temp;
    });
  }

  void _search() {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    if (from.isEmpty || to.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _loading = true;
      _searched = true;
    });

    final results = RouteFinderService.findRoutes(from, to);

    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('রুট সার্চ'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                _buildLocationField(
                  controller: _fromController,
                  focusNode: _fromFocus,
                  hint: 'যাত্রা শুরুর স্থান',
                  icon: Icons.trip_origin_rounded,
                  onSubmitted: () => _toFocus.requestFocus(),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    GestureDetector(
                      onTap: _swap,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryAccent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_vert_rounded,
                          color: AppConstants.primaryAccent,
                          size: 20,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 4),
                _buildLocationField(
                  controller: _toController,
                  focusNode: _toFocus,
                  hint: 'গন্তব্য স্থান',
                  icon: Icons.flag_rounded,
                  onSubmitted: _search,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _search,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.search_rounded),
                    label: Text(
                      _loading ? 'খুঁজছে...' : 'বাস খুঁজুন',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: AppConstants.fontBengali,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildResults(isDark)),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required VoidCallback onSubmitted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: AppConstants.fontBengali,
          color: Colors.grey[500],
        ),
        prefixIcon: Icon(icon, size: 20, color: AppConstants.primaryAccent),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  controller.clear();
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => onSubmitted(),
    );
  }

  Widget _buildResults(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_searched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus_rounded,
                size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'যাত্রা শুরু ও গন্তব্য স্থান দিন',
              style: TextStyle(
                fontSize: 16,
                fontFamily: AppConstants.fontBengali,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'যেমন: মিরপুর ১০ → মতিঝিল',
              style: TextStyle(
                fontSize: 13,
                fontFamily: AppConstants.fontBengali,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'কোনো বাস পাওয়া যায়নি',
              style: TextStyle(
                fontSize: 16,
                fontFamily: AppConstants.fontBengali,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'অন্য স্টপেজ নাম try করুন',
              style: TextStyle(
                fontSize: 13,
                fontFamily: AppConstants.fontBengali,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _results.length,
      itemBuilder: (_, i) => _buildResultCard(_results[i], isDark, i),
    );
  }

  Widget _buildResultCard(RouteSuggestion result, bool isDark, int index) {
    final stops = result.travelStops;
    final from = stops.first;
    final to = stops.last;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showRouteDetail(result),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: result.isDirect
                          ? AppConstants.successGreen.withValues(alpha: 0.12)
                          : AppConstants.fareAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      result.isDirect ? 'সরাসরি' : 'সংযোগ',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: AppConstants.fontBengali,
                        color: result.isDirect
                            ? AppConstants.successGreen
                            : AppConstants.fareAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.bus.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppConstants.fontBengali,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                ],
              ),
              if (result.bus.nameBn.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  result.bus.nameBn,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontFamily: AppConstants.fontBengali,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _stopBadge(from, AppConstants.primaryAccent, isDark),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${result.stopGap} স্টপ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontFamily: AppConstants.fontBengali,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(
                            result.stopGap.clamp(0, 6),
                            (_) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppConstants.primaryAccent
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _stopBadge(to, AppConstants.errorRed, isDark),
                ],
              ),
              if (!result.isDirect && result.connectingBus != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.fareAmber.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppConstants.fareAmber.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.transfer_within_a_station_rounded,
                          size: 14, color: AppConstants.fareAmber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${result.midStop ?? ''}-এ নেমে ${result.connectingBus ?? ''}-এ উঠবেন',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: AppConstants.fontBengali,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _stopBadge(String name, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(maxWidth: 110),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
          fontFamily: AppConstants.fontBengali,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showRouteDetail(RouteSuggestion result) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final stops = result.travelStops;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scroll) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: result.isDirect
                            ? AppConstants.successGreen.withValues(alpha: 0.12)
                            : AppConstants.fareAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        result.isDirect ? 'সরাসরি বাস' : 'সংযোগ বাস',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: AppConstants.fontBengali,
                          color: result.isDirect
                              ? AppConstants.successGreen
                              : AppConstants.fareAmber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (result.bus.type.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryAccent
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          result.bus.type,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: AppConstants.fontBengali,
                            color: AppConstants.primaryAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  result.bus.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (result.bus.nameBn.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    result.bus.nameBn,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontFamily: AppConstants.fontBengali,
                    ),
                  ),
                ],
                if (result.bus.time != null && result.bus.time!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '⏰ ${result.bus.time!}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: AppConstants.fontBengali,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _routePoint(stops.first, AppConstants.primaryAccent),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${stops.length - 1} স্টপ · ${result.stopGap} গ্যাপ',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontFamily: AppConstants.fontBengali,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...List.generate(
                            (stops.length - 1).clamp(0, 8),
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppConstants.primaryAccent
                                    .withValues(alpha: 0.3 + i * 0.07),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _routePoint(stops.last, AppConstants.errorRed),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scroll,
                    itemCount: stops.length,
                    itemBuilder: (_, i) {
                      final isFrom = i == 0;
                      final isTo = i == stops.length - 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFrom
                                    ? AppConstants.primaryAccent
                                    : isTo
                                        ? AppConstants.errorRed
                                        : Colors.grey[400],
                              ),
                              child: isFrom || isTo
                                  ? const Icon(Icons.circle, size: 10, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            if (i < stops.length - 1)
                              Container(
                                width: 2,
                                height: 20,
                                color: Colors.grey[300],
                              ),
                            const SizedBox(width: 12),
                            Text(
                              stops[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isFrom || isTo ? FontWeight.w600 : FontWeight.normal,
                                color: isFrom
                                    ? AppConstants.primaryAccent
                                    : isTo
                                        ? AppConstants.errorRed
                                        : null,
                                fontFamily: AppConstants.fontBengali,
                              ),
                            ),
                            if (isFrom)
                              const Text(' ✓', style: TextStyle(
                                  fontSize: 10, color: AppConstants.successGreen)),
                            if (isTo)
                              const Text(' ✓', style: TextStyle(
                                  fontSize: 10, color: AppConstants.errorRed)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _routePoint(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(maxWidth: 130),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
          fontFamily: AppConstants.fontBengali,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
