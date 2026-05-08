import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/offers/bloc/all_offers.cubit.dart';
import 'package:temple_adventures_admin/features/offers/models/offer.model.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/widgets/empty_state_message.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_image.dart';
import '../../../../widgets/key_value_pair.dart';
import '../screens/add_edit_offer.screen.dart';
import 'share_offer.modal.dart';

class OfferListView extends StatelessWidget {
  final List<Offer> offers;
  final bool showOnlyValidOffers;

  const OfferListView({
    super.key,
    required this.offers,
    required this.showOnlyValidOffers,
  });

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return EmptyStateMessage(
        message: showOnlyValidOffers ? 'No valid offers found' : 'No offers found',
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AllOffersCubit>().fetchOffers(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          return OfferCard(
            offer: offer,
            onTap: () => ShareOfferModal.show(context, offer: offer),
            onEdit: () async {
              await Navigator.push(
                context,
                AddEditOfferScreen.route(offer: offer),
              );
            },
          ).paddingOnly(bottom: 20);
        },
      ),
    );
  }
}

class OfferCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const OfferCard({
    super.key,
    required this.offer,
    required this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey.shade50,
                child: AppImage(offer.photo, fit: BoxFit.cover),
              ),
            ),
            Spacing.h10,
            Text(offer.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Spacing.h10,
            KeyValuePair(
              title: 'Valid Until',
              value: '${offer.startDate.formatDDMMYYYY} - ${offer.endDate.formatDDMMYYYY}',
            ),
            if (offer.description?.isNotEmpty ?? false) ...[
              Spacing.h10,
              Text(
                offer.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Created by : ${offer.createdBy.fullName}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEdit ?? () {},
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit Offer',
                ),
              ],
            ),
          ],
        ).paddingAll(16),
      ),
    );
  }
}
