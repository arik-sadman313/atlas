import '../../domain/models/search_result_item.dart';
import '../services/search_service.dart';

class SearchRepository {
  final SearchService searchService;

  SearchRepository({required this.searchService});

  Future<List<SearchResultItem>> search(
    String workspaceId,
    String query, {
    SearchFilter filter = SearchFilter.all,
    int limit = 50,
  }) {
    return searchService.search(
      workspaceId,
      query,
      filter: filter,
      limit: limit,
    );
  }
}
