import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/ui/auth/authentication_bloc.dart';
import 'package:instaflutter/listings/ui/listings/adminDashboard/admin_bloc.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_api_manager.dart';
import 'package:instaflutter/listings/ui/listings/listingDetails/listing_details_screen.dart';
import 'package:instaflutter/core/ui/loading/loading_cubit.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_api_manager.dart';

class AdminDashboardWrappingWidget extends StatelessWidget {
  final ListingsUser currentUser;

  const AdminDashboardWrappingWidget({Key? key, required this.currentUser})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminBloc(
        currentUser: currentUser,
        listingsRepository: listingApiManager,
        profileRepository: profileApiManager,
      ),
      child: AdminDashboardScreen(currentUser: currentUser),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  final ListingsUser currentUser;

  const AdminDashboardScreen({Key? key, required this.currentUser})
      : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<ListingModel> pendingListings = [];
  late ListingsUser currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser;
    context.read<AdminBloc>().add(GetPendingListingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'.tr()),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<AdminBloc>().add(LoadingEvent());
          context.read<AdminBloc>().add(GetPendingListingsEvent());
        },
        child: BlocConsumer<AdminBloc, AdminState>(
          listener: (context, state) {
            if (state is PendingListingsState) {
              Future.delayed(Duration.zero, () {
                context.read<LoadingCubit>().hideLoading();
              });
              isLoading = false;
              pendingListings = state.pendingListings;
            } else if (state is LoadingState) {
              isLoading = true;
            } else if (state is ListingFavToggleState) {
              currentUser = state.updatedUser;
              context.read<AuthenticationBloc>().user = state.updatedUser;
              pendingListings
                  .firstWhere((element) => element.id == state.listing.id)
                  .isFav = state.listing.isFav;
            }
          },
          builder: (context, state) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            if (pendingListings.isEmpty) {
              return Stack(
                children: [
                  ListView(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: showEmptyState(
                        'No Pending Listings'.tr(),
                        'New listings will show up before being published.'
                            .tr()),
                  ),
                ],
              );
            } else {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(right: 16, left: 16, top: 16),
                      child: Text(
                        'Awaiting Approval'.tr(),
                        style: TextStyle(
                          fontSize: 25,
                          color: isDarkMode(context)
                              ? Colors.grey.shade400
                              : Colors.grey.shade900,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => PendingListingCard(
                            listing: pendingListings[index],
                            currentUser: currentUser),
                        childCount: pendingListings.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 16,
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class PendingListingCard extends StatefulWidget {
  final ListingModel listing;
  final ListingsUser currentUser;

  const PendingListingCard({
    Key? key,
    required this.listing,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<PendingListingCard> createState() => _PendingListingCardState();
}

class _PendingListingCardState extends State<PendingListingCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        bool? isListingDeleted = await push(
            context,
            ListingDetailsWrappingWidget(
                listing: widget.listing, currentUser: widget.currentUser));
        if (isListingDeleted != null && isListingDeleted) {
          if (!mounted) return;
          context
              .read<AdminBloc>()
              .add(ListingDeletedByUserEvent(listing: widget.listing));
        }
      },
      onLongPress: () => _showAdminOptions(widget.listing, context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                displayImage(widget.listing.photo),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    tooltip: widget.listing.isFav
                        ? 'Remove From Favorites'.tr()
                        : 'Add To Favorites'.tr(),
                    icon: Icon(
                      Icons.favorite,
                      color: widget.listing.isFav
                          ? Color(colorPrimary)
                          : Colors.white,
                    ),
                    onPressed: () => context.read<AdminBloc>().add(
                          ListingFavUpdated(
                            listing: widget.listing,
                          ),
                        ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.listing.title,
            maxLines: 1,
            style: TextStyle(
                fontSize: 16,
                color: isDarkMode(context)
                    ? Colors.grey.shade400
                    : Colors.grey.shade800,
                fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(widget.listing.place, maxLines: 1),
          ),
        ],
      ),
    );
  }

  _showAdminOptions(ListingModel listing, BuildContext blocContext) =>
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          message: Text(
            listing.title,
            style: const TextStyle(fontSize: 20.0),
          ),
          actions: [
            CupertinoActionSheetAction(
              isDestructiveAction: false,
              isDefaultAction: true,
              onPressed: () async {
                Navigator.pop(context);
                await blocContext.read<LoadingCubit>().showLoading(
                      context,
                      'Approving...'.tr(),
                      false,
                      Color(colorPrimary),
                    );
                if (!mounted) return;
                blocContext
                    .read<AdminBloc>()
                    .add(ListingApprovalByAdminEvent(listing: listing));
              },
              child: Text('Approve'.tr()),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(context);
                String title = 'Delete Listing?'.tr();
                String content =
                    'Are you sure you want to remove this listing?'.tr();
                if (Platform.isIOS) {
                  await showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: Text(title),
                      content: Text(content),
                      actions: [
                        TextButton(
                          child: Text(
                            'Yes'.tr(),
                            style: const TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            blocContext.read<LoadingCubit>().showLoading(
                                  context,
                                  'Deleting...'.tr(),
                                  false,
                                  Color(colorPrimary),
                                );
                            blocContext.read<AdminBloc>().add(
                                ListingDeleteByAdminEvent(listing: listing));
                          },
                        ),
                        TextButton(
                          child: Text('No'.tr()),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                } else {
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(title),
                      content: Text(content),
                      actions: [
                        TextButton(
                          child: Text(
                            'Yes'.tr(),
                            style: const TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            blocContext.read<LoadingCubit>().showLoading(
                                  context,
                                  'Deleting...'.tr(),
                                  false,
                                  Color(colorPrimary),
                                );
                            blocContext.read<AdminBloc>().add(
                                ListingDeleteByAdminEvent(listing: listing));
                          },
                        ),
                        TextButton(
                          child: Text('No'.tr()),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text('Delete'.tr()),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text('Cancel'.tr()),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
}
