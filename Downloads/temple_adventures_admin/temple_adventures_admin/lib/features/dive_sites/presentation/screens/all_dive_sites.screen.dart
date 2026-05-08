import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';

import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/empty_state_message.dart';
import '../../../../widgets/key_value_pair.dart';
import '../../../../widgets/loading_overlay.dart';
import '../../bloc/dive_sites.cubit.dart';
import '../../model/dive_site.model.dart';
import 'add_edit_dive_site.screen.dart';

class AllDiveSitesView extends StatefulWidget {
  const AllDiveSitesView({super.key});

  static Route<DiveSite?> route() {
    return MaterialPageRoute(
      builder: (BuildContext context) {
        return const AllDiveSitesView();
      },
    );
  }

  @override
  State<AllDiveSitesView> createState() => _AllDiveSitesViewState();
}

class _AllDiveSitesViewState extends State<AllDiveSitesView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBlueColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          Navigator.push(context, AddEditDiveSiteScreen.route(null));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: const CustomAppBar(title: 'Dive Sites', description: ''),
      body: SafeArea(
        child: BlocConsumer<DiveSiteCubit, DiveSiteState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state.status is DiveSiteInitial || state.status is DiveSiteLoading) {
              return LoadingOverlay();
            }
            if (state.status is DiveSiteError) {
              final message = (state.status as DiveSiteError).message;
              return EmptyStateMessage(
                message: 'Failed to load equipment\n$message',
                onRetry: () {
                  final cubit = context.read<DiveSiteCubit>();
                  cubit.fetchDiveSites();
                },
              );
            }
            if (state.diveSites.isEmpty) {
              return const EmptyStateMessage(
                message: 'No dive sites found',
              ).center;
            }
            if (state.status is DiveSiteLoaded || state.status is DiveSiteSuccess) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.diveSites.length,
                      itemBuilder: (context, index) {
                        final diveSite = state.diveSites[index];
                        return _DiveSiteCard(diveSite: diveSite).paddingSymmetric(vertical: 10);
                      },
                    ),
                  ),
                ],
              ).paddingSymmetric(horizontal: 20);
            }
            return EmptyStateMessage(message: 'something went wrong');
          },
        ),
      ),
    );
  }
}

class _DiveSiteCard extends StatelessWidget {
  const _DiveSiteCard({
    required this.diveSite,
  });

  final DiveSite diveSite;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context, diveSite);
      },
      child: Container(
        width: Screen.width,
        height: 141,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height: 141,
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child:
                  Icon(
                    Icons.navigation_rounded,
                    color: skyBlueColor,
                    size: 70,
                  ).center,
            ),
            Spacing.w10,
            const Spacer(),
            SizedBox(
              width: Screen.width - 173,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          diveSite.siteName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            height: 1.42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(context, AddEditDiveSiteScreen.route(diveSite));
                        },
                        icon: const Icon(
                          Icons.edit,
                          size: 15,
                        ),
                      ),
                    ],
                  ),
                  Spacing.h5,
                  const Spacer(),
                  KeyValuePair(
                    title: 'Latitude',
                    value: diveSite.latitude.toStringAsFixed(5),
                  ),
                  KeyValuePair(
                    title: 'Longitude',
                    value: diveSite.longitude.toStringAsFixed(5),
                  ),
                  const Spacer(),
                  Spacing.h4,
                ],
              ),
            ).paddingOnly(top: 20),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
