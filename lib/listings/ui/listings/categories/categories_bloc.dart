import 'package:bloc/bloc.dart';
import 'package:instaflutter/listings/model/categories_model.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_repository.dart';

part 'categories_event.dart';
part 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final ListingsRepository listingsRepository;

  CategoriesBloc({required this.listingsRepository})
      : super(CategoriesInitial()) {
    on<FetchCategoriesEvent>((event, emit) async {
      List<CategoriesModel> categories =
          await listingsRepository.getCategories();
      emit(CategoriesFetchedState(categoriesList: categories));
    });
    on<LoadingEvent>((event, emit) => emit(LoadingState()));
  }
}
