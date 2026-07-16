import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/journey_planner_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../services/search_service.dart';
import '../../../services/nearest_stop_service.dart';
import 'journey_results_screen.dart';

class JourneyPlannerScreen extends ConsumerStatefulWidget {
  const JourneyPlannerScreen({super.key});

  @override
  ConsumerState<JourneyPlannerScreen> createState() => _JourneyPlannerScreenState();
}

class _JourneyPlannerScreenState extends ConsumerState<JourneyPlannerScreen> {
  final _originController = TextEditingController();
  final _destController = TextEditingController();
  final _destFocus = FocusNode();
  String _searchMode = 'origin';

  @override
  void initState() {
    super.initState();
    _detectLocation();

    ref.listenManual(journeyPlannerProvider, (prev, next) {
      if (prev?.isLoading == true && !next.isLoading && next.results.isNotEmpty) {
        FocusScope.of(context).unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JourneyResultsScreen()),
        );
      }
      if (next.error != null && next.error != prev?.error && next.hasSearched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!, style: const TextStyle(fontFamily: AppConstants.fontBengali)),
            backgroundColor: AppConstants.warn,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });
  }

  void _detectLocation() {
    final loc = ref.read(locationProvider);
    if (loc.currentPoint != null) {
      ref.read(journeyPlannerProvider.notifier).setOrigin(
        loc.currentPoint!.latitude,
        loc.currentPoint!.longitude,
        'আমার অবস্থান',
      );
      _originController.text = 'আমার অবস্থান';
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _destFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journeyPlannerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.backgroundDark : AppConstants.paper,
      appBar: AppBar(
        title: const Text(
          'যাত্রা পরিকল্পনা',
          style: TextStyle(fontFamily: AppConstants.fontBengali),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInputSection(state, isDark),
                    if (_searchMode != 'none') _buildSearchSuggestions(state, isDark),
                    if (_searchMode == 'none') _buildBody(state, isDark),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputSection(JourneyPlannerState state, bool isDark) {
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : AppConstants.cardLine),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppConstants.backgroundLight,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(
                          color: AppConstants.fareAmber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(width: 1.5, height: 28, color: AppConstants.cardLine),
                      Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(
                          color: AppConstants.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        _buildField(
                          controller: _originController,
                          hint: 'শুরুর স্থান',
                          isDark: isDark,
                          onChanged: _onOriginSearch,
                        ),
                        Divider(height: 1, color: isDark ? Colors.white12 : AppConstants.cardLine),
                        _buildField(
                          controller: _destController,
                          hint: 'গন্তব্য স্থান',
                          isDark: isDark,
                          focusNode: _destFocus,
                          onChanged: _onDestSearch,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: _swap,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppConstants.amberSoft,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Center(
                          child: Icon(Icons.swap_vert_rounded,
                              size: 18, color: AppConstants.fareAmber),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildGpsStatus(state),
            if (state.error != null && state.hasSearched) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.warn.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppConstants.warn),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: AppConstants.fontBengali,
                          color: AppConstants.warn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildSearchButton(state),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required ValueChanged<String> onChanged,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 14,
        fontFamily: AppConstants.fontBengali,
        color: isDark ? Colors.white : AppConstants.ink,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 14,
          fontFamily: AppConstants.fontBengali,
          color: AppConstants.inkSoft,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        isDense: true,
      ),
    );
  }

  Widget _buildGpsStatus(JourneyPlannerState state) {
    final hasOrigin = state.originLat != null;
    return Row(
      children: [
        Icon(
          hasOrigin ? Icons.location_on_rounded : Icons.location_off_rounded,
          size: 14,
          color: hasOrigin ? AppConstants.successGreen : AppConstants.warn,
        ),
        const SizedBox(width: 6),
        Text(
          hasOrigin
              ? 'GPS সক্রিয় · ${state.originName}'
              : 'GPS অনুমতি প্রয়োজন',
          style: TextStyle(
            fontSize: 11,
            fontFamily: AppConstants.fontBengali,
            color: hasOrigin ? AppConstants.successGreen : AppConstants.warn,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchButton(JourneyPlannerState state) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: state.isLoading ? null : _planJourney,
        icon: state.isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.directions_bus_rounded),
        label: Text(
          state.isLoading ? 'পরিকল্পনা তৈরি হচ্ছে...' : 'যাত্রা পরিকল্পনা করুন',
          style: const TextStyle(fontSize: 15, fontFamily: AppConstants.fontBengali),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions(JourneyPlannerState state, bool isDark) {
    if (state.searchResults.isEmpty) return const SizedBox.shrink();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.searchResults.length,
      itemBuilder: (_, i) => _buildSuggestionTile(state.searchResults[i], isDark),
    );
  }

  Widget _buildSuggestionTile(SearchSuggestion s, bool isDark) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppConstants.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.location_on_rounded,
            size: 18, color: AppConstants.primaryGreen),
      ),
      title: Text(
        s.displayNameBn,
        style: const TextStyle(
          fontFamily: AppConstants.fontBengali,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        s.displayName,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
        ),
      ),
      onTap: () => _selectSuggestion(s),
    );
  }

  Widget _buildBody(JourneyPlannerState state, bool isDark) {
    if (state.nearbyStops.isNotEmpty) {
      return _buildNearbyStops(state, isDark);
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              state.error!,
              style: TextStyle(
                fontSize: 16,
                fontFamily: AppConstants.fontBengali,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_bus_rounded, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'গন্তব্য স্থান লিখুন',
            style: TextStyle(
              fontSize: 16,
              fontFamily: AppConstants.fontBengali,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'যাত্রা শুরু ও গন্তব্য নির্বাচন করুন',
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

  Widget _buildNearbyStops(JourneyPlannerState state, bool isDark) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'কাছের বাস স্টপ (${state.nearbyStops.length}টি)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: AppConstants.fontBengali,
            color: isDark ? Colors.white70 : AppConstants.ink,
          ),
        ),
        const SizedBox(height: 8),
        ...state.nearbyStops.take(8).map((stop) => _buildNearbyStopTile(stop, isDark)),
      ],
    );
  }

  Widget _buildNearbyStopTile(NearbyStop stop, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900]! : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : AppConstants.cardLine),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppConstants.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_walk_rounded,
                size: 18, color: AppConstants.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.coordinate.nameBn,
                  style: const TextStyle(
                    fontFamily: AppConstants.fontBengali,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${stop.coordinate.name} · ${stop.direction}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stop.distanceMeters.toStringAsFixed(0)}মি',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.primaryGreen,
                ),
              ),
              Text(
                '${stop.walkingTimeMinutes.toStringAsFixed(0)} মিনিট হাঁটা',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05);
  }

  void _onOriginSearch(String query) {
    setState(() => _searchMode = 'origin');
    ref.read(journeyPlannerProvider.notifier).searchDestination(query);
  }

  void _onDestSearch(String query) {
    setState(() => _searchMode = 'dest');
    ref.read(journeyPlannerProvider.notifier).searchDestination(query);
  }

  void _selectSuggestion(SearchSuggestion s) {
    if (_searchMode == 'origin') {
      _originController.text = s.displayNameBn;
      final state = ref.read(journeyPlannerProvider);
      ref.read(journeyPlannerProvider.notifier).setOrigin(
        s.coordinate?.lat ?? state.originLat ?? 23.8103,
        s.coordinate?.lng ?? state.originLng ?? 90.4125,
        s.displayNameBn,
      );
    } else {
      _destController.text = s.displayNameBn;
      ref.read(journeyPlannerProvider.notifier).selectDestination(
        s.displayNameBn,
        lat: s.coordinate?.lat,
        lng: s.coordinate?.lng,
      );
    }
    ref.read(journeyPlannerProvider.notifier).clearSearch();
    setState(() => _searchMode = 'none');
  }

  void _swap() {
    final state = ref.read(journeyPlannerProvider);
    final tempText = _originController.text;
    final tempOriginLat = state.originLat;
    final tempOriginLng = state.originLng;
    final tempOriginName = state.originName;
    final tempDestLat = state.destLat;
    final tempDestLng = state.destLng;
    final tempDestName = state.destName;

    setState(() {
      _originController.text = _destController.text;
      _destController.text = tempText;
    });

    final notifier = ref.read(journeyPlannerProvider.notifier);
    if (tempDestLat != null && tempDestLng != null) {
      notifier.setOrigin(tempDestLat, tempDestLng, tempDestName);
    }
    if (tempOriginLat != null && tempOriginLng != null) {
      notifier.selectDestination(
        tempOriginName,
        lat: tempOriginLat,
        lng: tempOriginLng,
      );
    }
  }

  void _planJourney() {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    ref.read(journeyPlannerProvider.notifier).planJourney();
  }
}
