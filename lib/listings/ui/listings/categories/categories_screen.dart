import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instaflutter/listings/model/categories_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_api_manager.dart';
import 'package:instaflutter/listings/ui/listings/categories/categories_bloc.dart';
import 'package:instaflutter/listings/ui/listings/categoryListings/category_listings_screen.dart';

class CategoriesWrapperWidget extends StatelessWidget {
  final ListingsUser currentUser;

  const CategoriesWrapperWidget({Key? key, required this.currentUser})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CategoriesBloc(listingsRepository: listingApiManager),
      child: CategoriesScreen(currentUser: currentUser),
    );
  }
}

class CategoriesScreen extends StatefulWidget {
  final ListingsUser currentUser;

  const CategoriesScreen({Key? key, required this.currentUser})
      : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late ListingsUser currentUser;
  bool isLoading = true;
  List<CategoriesModel> categories = [];

  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser;
    context.read<CategoriesBloc>().add(FetchCategoriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<CategoriesBloc>().add(LoadingEvent());
          context.read<CategoriesBloc>().add(FetchCategoriesEvent());
        },
        child: BlocConsumer<CategoriesBloc, CategoriesState>(
          listener: (context, state) {
            if (state is CategoriesFetchedState) {
              isLoading = false;
              categories = state.categoriesList;
            } else if (state is LoadingState) {
              isLoading = true;
            }
          },
          builder: (context, state) {
            if (isLoading) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              );
            }
            if (categories.isEmpty) {
              return Stack(
                children: [
                  ListView(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: showEmptyState(
                      'No Categories'.tr(),
                      'All Categories will show up here once added by the admin.'
                          .tr(),
                    ),
                  ),
                ],
              );
            } else {
              return ListView.builder(
                itemCount: categories.length,
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                itemBuilder: (context, index) => CategoryTile(
                    currentUser: currentUser, category: categories[index]),
              );
            }
          },
        ),
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  final CategoriesModel category;
  final ListingsUser currentUser;

  const CategoryTile(
      {Key? key, required this.category, required this.currentUser})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: GestureDetector(
        onTap: () => push(
          context,
          CategoryListingsWrapperWidget(
            categoryID: category.id,
            categoryName: category.title,
            currentUser: currentUser,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            image: DecorationImage(
              image: NetworkImage(category.photo),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5), BlendMode.darken),
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text(
                category.title,
                style: const TextStyle(color: Colors.white70, fontSize: 17),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
