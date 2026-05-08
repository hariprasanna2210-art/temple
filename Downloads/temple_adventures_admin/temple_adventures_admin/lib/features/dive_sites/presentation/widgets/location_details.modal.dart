import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../bloc/add_edit_dive_site.cubit.dart';
import '../../bloc/dive_sites.cubit.dart';
import '../../model/dive_site.model.dart';

class LocationDetailsModal extends StatefulWidget {
  const LocationDetailsModal({super.key});

  static Future<void> show(BuildContext context) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const LocationDetailsModal();
      },
    );
  }

  @override
  State<LocationDetailsModal> createState() => _LocationDetailsModalState();
}

class _LocationDetailsModalState extends State<LocationDetailsModal> {
  late final DiveSiteCubit cubit;
  late TextEditingController _locationName;
  late FocusNode _locationFocusNode;

  @override
  void initState() {
    super.initState();
    cubit = context.read<DiveSiteCubit>();
    _locationName = TextEditingController(text: 'Untitled site');
    _locationFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _locationName.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<DiveSiteCubit>();
    double distance = cubit.calculateDistanceInKm(
      cubit.state.currentUserLocation!.latitude,
      cubit.state.currentUserLocation!.longitude,
      cubit.state.currentCenterPosition!.latitude,
      cubit.state.currentCenterPosition!.longitude,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleAndClose(),
                Spacing.h20,
                _buildTextFieldAndEditButton(),
                Spacing.h20,
                _buildLocationDetails(cubit.state, distance),
                Spacing.h40,
                buildActionButton().center,
              ],
            ).paddingAll(20).scrollable,
      ),
    );
  }

  Widget _buildTitleAndClose() {
    return Row(
      children: [
        const Text(
          'New dive site',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildLocationDetails(DiveSiteState state, double distance) {
    return Container(
      width: Screen.width,
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My current location', style: TextStyle(color: Colors.black, fontSize: 12)),
          Text(
            '${state.currentUserLocation?.latitude.toStringAsFixed(6)} , ${state.currentUserLocation?.longitude.toStringAsFixed(6)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14),
          ),
          Spacing.h10,
          const Text('Pointed location', style: TextStyle(color: Colors.black, fontSize: 12)),
          Text(
            '${state.currentCenterPosition?.latitude.toStringAsFixed(6)} , ${state.currentCenterPosition?.longitude.toStringAsFixed(6)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14),
          ),
          Spacing.h10,
          const Text('Distance from my location', style: TextStyle(color: Colors.black, fontSize: 12)),
          Text(
            '${distance.toStringAsFixed(2)} km',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14),
          ),
        ],
      ).paddingAll(15),
    );
  }

  Widget _buildTextFieldAndEditButton() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _locationName,
            focusNode: _locationFocusNode,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
        if (!_locationFocusNode.hasFocus)
          InkWell(
            onTap: () {
              _locationFocusNode.requestFocus();
              setState(() {});
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black12,
              ),
              child: const Icon(Icons.edit, color: Colors.black, size: 20).paddingAll(5),
            ),
          ),
      ],
    );
  }

  Widget buildActionButton() {
    return BlocSelector<AddEditDiveSiteCubit, AddEditDiveSiteState, bool>(
      selector: (state) => state.status is DiveSiteLoading,
      builder:
          (context, isLoading) => AppButton.flat(
            text: 'Save',
            showLoading: isLoading,
            onTap: () async {
              final newSite = DiveSite(
                siteName: _locationName.text,
                latitude: cubit.state.currentCenterPosition!.latitude,
                longitude: cubit.state.currentCenterPosition!.longitude,
              );
              await context.read<AddEditDiveSiteCubit>().onDiveSiteSubmit(context, newSite);
              await cubit.fetchDiveSites();
              cubit.hideOverlay();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
    );
  }
}
