import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/model/categories_model.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ads/ads_utils.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/ui/auth/authentication_bloc.dart';
import 'package:instaflutter/listings/ui/listings/addListing/add_listing_screen.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_api_manager.dart';
import 'package:instaflutter/listings/ui/listings/categoryListings/category_listings_screen.dart';
import 'package:instaflutter/listings/ui/listings/home/home_bloc.dart';
import 'package:instaflutter/listings/ui/listings/listingDetails/listing_details_screen.dart';
import 'package:instaflutter/core/ui/loading/loading_cubit.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_api_manager.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomeWrapperWidget extends StatelessWidget {
  final ListingsUser currentUser;
  final GlobalKey<HomeScreenState> homeKey;

  const HomeWrapperWidget(
      {Key? key, required this.currentUser, required this.homeKey})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
          currentUser: currentUser,
          profileRepository: profileApiManager,
          listingsRepository: listingApiManager),
      child: HomeScreen(
        currentUser: currentUser,
        key: homeKey,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final ListingsUser currentUser;

  const HomeScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<ListingModel> listings = [];
  List<ListingModel?> listingsWithAds = [];
  List<CategoriesModel> _categories = [];
  bool _showAll = false, loadingCategories = true, loadingListings = true;
  late ListingsUser currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser;
    context.read<HomeBloc>().add(GetCategoriesEvent());
    context.read<HomeBloc>().add(GetListingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<HomeBloc>().add(LoadingEvent());
          context.read<HomeBloc>().add(GetCategoriesEvent());
          context.read<HomeBloc>().add(GetListingsEvent());
        },
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) {
            if (state is CategoriesListState) {
              loadingCategories = false;
              _categories = state.categories;
            } else if (state is ListingsListState) {
              context.read<LoadingCubit>().hideLoading();
              loadingListings = false;
              listingsWithAds = state.listingsWithAds;
              var tempList = [...listingsWithAds]
                ..removeWhere((element) => element == null);
              listings = [...tempList.cast<ListingModel>()];
            } else if (state is LoadingCategoriesState) {
              loadingCategories = true;
            } else if (state is LoadingListingsState) {
              loadingListings = true;
            } else if (state is ToggleShowAllState) {
              _showAll = !_showAll;
            } else if (state is ListingFavToggleState) {
              currentUser = state.updatedUser;
              context.read<AuthenticationBloc>().user = state.updatedUser;
              listings
                  .firstWhere((element) => element.id == state.listing.id)
                  .isFav = state.listing.isFav;
              listingsWithAds
                  .firstWhere((element) => element?.id == state.listing.id)
                  ?.isFav = state.listing.isFav;
            } else if (state is LoadingState) {
              _showAll = false;
              loadingListings = true;
              loadingCategories = true;
            }
          },
          builder: (context, state) {
            if (loadingCategories && loadingListings) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Text(
                      'Categories'.tr(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 8,
                    ),
                  ),
                  if (loadingCategories)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child:
                            Center(child: CircularProgressIndicator.adaptive()),
                      ),
                    ),
                  if (_categories.isEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: showEmptyState(
                          'No Categories'.tr(),
                          'All Categories will be shown here once added by the admin.'
                              .tr(),
                        ),
                      ),
                    ),
                  if (_categories.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 100,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) =>
                                CategoryHomeCardWidget(
                                    currentUser: currentUser,
                                    category: _categories[index])),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 16,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Text(
                      'Listings'.tr(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 16,
                    ),
                  ),
                  if (loadingListings)
                    const SliverToBoxAdapter(
                      child:
                          Center(child: CircularProgressIndicator.adaptive()),
                    ),
                  if (listingsWithAds.isEmpty && !loadingListings)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: showEmptyState(
                            'No Listings'.tr(),
                            'Add a new listing to show up here once the admin approves it.'
                                .tr(),
                            buttonTitle: 'Add Listing'.tr(),
                            isDarkMode: isDarkMode(context),
                            action: () => push(
                                context,
                                AddListingWrappingWidget(
                                    currentUser: currentUser)),
                            colorPrimary: Color(colorPrimary),
                          ),
                        ),
                      ),
                    ),
                  SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => listingsWithAds[index] == null
                          ? AdsUtils.adsContainer()
                          : ListingHomeCardWidget(
                              currentUser: currentUser,
                              listing: listingsWithAds[index]),
                      childCount: listingsWithAds.length > 4
                          ? _showAll
                              ? listingsWithAds.length
                              : 4
                          : listingsWithAds.length,
                    ),
                    gridDelegate: SliverQuiltedGridDelegate(
                      pattern: [
                        const QuiltedGridTile(1, 1),
                        const QuiltedGridTile(1, 1),
                        const QuiltedGridTile(1, 1),
                        const QuiltedGridTile(1, 1),
                        const QuiltedGridTile(2, 2),
                      ],
                      crossAxisCount: 2,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 16,
                      repeatPattern: QuiltedGridRepeatPattern.same,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 32),
                      child: Visibility(
                        visible: !_showAll && listingsWithAds.length > 4,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: BorderSide(
                                color: Color(colorPrimary),
                              ),
                            ),
                          ),
                          child: Text(
                            'Show All (${listings.length - 4})'.tr(),
                            style: TextStyle(color: Color(colorPrimary)),
                          ),
                          onPressed: () => context
                              .read<HomeBloc>()
                              .add(ToggleShowAllEvent()),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class CategoryHomeCardWidget extends StatelessWidget {
  final ListingsUser currentUser;
  final CategoriesModel category;

  const CategoryHomeCardWidget(
      {Key? key, required this.currentUser, required this.category})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2.0, right: 2),
      child: GestureDetector(
        onTap: () => push(
            context,
            CategoryListingsWrapperWidget(
              categoryID: category.id,
              categoryName: category.title,
              currentUser: currentUser,
            )),
        child: SizedBox(
          width: 120,
          height: 120,
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), side: BorderSide.none),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 120),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      child: displayImage(category.photo),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
                  child: Center(
                    child: Text(
                      category.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ListingHomeCardWidget extends StatefulWidget {
  final ListingModel? listing;
  final ListingsUser currentUser;

  const ListingHomeCardWidget(
      {Key? key, required this.listing, required this.currentUser})
      : super(key: key);

  @override
  State<ListingHomeCardWidget> createState() => _ListingHomeCardWidgetState();
}

class _ListingHomeCardWidgetState extends State<ListingHomeCardWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.listing == null) {
      return AdsUtils.adsContainer();
    }
    return SizedBox(
      height: 150,
      child: GestureDetector(
        onLongPress: widget.currentUser.isAdmin
            ? () => _showAdminOptions(widget.listing!, context)
            : () {},
        onTap: () async {
          bool? isListingDeleted = await push(
              context,
              ListingDetailsWrappingWidget(
                  listing: widget.listing!, currentUser: widget.currentUser));
          if (isListingDeleted != null && isListingDeleted) {
            if (!mounted) return;
            context
                .read<HomeBloc>()
                .add(ListingDeletedByUserEvent(listing: widget.listing!));
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  displayImage(widget.listing!.photo),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(
                        Icons.favorite,
                        color: widget.listing!.isFav
                            ? Color(colorPrimary)
                            : Colors.white,
                      ),
                      tooltip: widget.listing!.isFav
                          ? 'Remove From Favorites'.tr()
                          : 'Add To Favorites'.tr(),
                      onPressed: () => context
                          .read<HomeBloc>()
                          .add(ListingFavUpdated(listing: widget.listing!)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.listing!.title,
              maxLines: 1,
              style: TextStyle(
                  fontSize: 16,
                  color:
                      isDarkMode(context) ? Colors.grey[400] : Colors.grey[800],
                  fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(widget.listing!.place, maxLines: 1),
            ),
            RatingBar.builder(
              ignoreGestures: true,
              minRating: .5,
              initialRating: widget.listing!.reviewsSum != 0
                  ? widget.listing!.reviewsSum / widget.listing!.reviewsCount
                  : 0,
              allowHalfRating: true,
              itemSize: 22,
              glow: false,
              unratedColor: Color(colorPrimary).withOpacity(0.5),
              itemBuilder: (context, index) =>
                  Icon(Icons.star, color: Color(colorPrimary)),
              itemCount: 5,
              onRatingUpdate: (newValue) {},
            )
          ],
        ),
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
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Edit Listing'.tr()),
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
                                  blocContext.read<HomeBloc>().add(
                                      ListingDeleteByAdminEvent(
                                          listing: listing));
                                },
                              ),
                              TextButton(
                                child: Text('No'.tr()),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ));
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
                            blocContext.read<HomeBloc>().add(
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
              child: Text('Delete Listing'.tr()),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text('Cancel'.tr()),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
}
