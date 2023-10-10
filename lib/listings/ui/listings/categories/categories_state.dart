part of 'categories_bloc.dart';

abstract class CategoriesState {}

class CategoriesInitial extends CategoriesState {}

class LoadingState extends CategoriesState {}

class CategoriesFetchedState extends CategoriesState {
  List<CategoriesModel> categoriesList;

  CategoriesFetchedState({required this.categoriesList});
}
