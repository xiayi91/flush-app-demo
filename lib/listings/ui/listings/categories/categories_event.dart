part of 'categories_bloc.dart';

abstract class CategoriesEvent {}

class FetchCategoriesEvent extends CategoriesEvent {}

class LoadingEvent extends CategoriesEvent {}
