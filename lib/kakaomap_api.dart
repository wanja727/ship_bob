import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kakao_map/models/category_response.dart' as category;
import 'package:kakao_map/models/coord2address_response.dart';

class KakaoMapApi{

  // 좌표->주소 변경
  Future<String> getAddress (double lat, double lng) async {
    String address = "";
    
    Uri uri = Uri.parse("https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$lng&y=$lat&input_coord=WGS84");

    final response = await http.get(uri, headers: {"Authorization": "KakaoAK 90a5b736903df69338d565b1f3fa99a0"});

    if (response.statusCode == 200) {
      // print('JSON 받아온거');
      // print(response.body);

      Coord2AddressResponse coord2addressResponse = Coord2AddressResponse.fromJson(jsonDecode(response.body));
      coord2addressResponse.documents?.forEach((element) {
        // 도로명 주소 있으면 우선적으로 세팅
        if(element.roadAddress != null){
          // print("도로명 주소 있음!");
          address = "${element.roadAddress?.addressName??""} ${element.roadAddress?.buildingName??""}";
        }else{
          // print("도로명 주소 없음!");
          address = element.address?.addressName??"";
        }
      });

      return address;

    } else {
      throw Exception('API 호출결과 오류 (statusCode != 200)');
    }
  }

  // 근처 카테고리 검색
  // Future<List<category.Documents>>
    Future<category.CategoryResponse> getNearRestaurants (double lat, double lng, int radius) async {

    // API 결과저장
    category.CategoryResponse categoryResponse;

    // 최종 리턴값
    category.CategoryResponse resultCategoryResponse = category.CategoryResponse();
    List<category.Documents> resultDocuments = [];
    category.Meta resultMeta;

    int page = 1;
    Uri uri;
    http.Response response;

    while(true) {
      uri = Uri.parse("https://dapi.kakao.com/v2/local/search/category.json?category\_group\_code=FD6&y=$lat&x=$lng&radius=$radius&page=$page");
      response = await http.get(uri, headers: {"Authorization": "KakaoAK 90a5b736903df69338d565b1f3fa99a0"});

      if (response.statusCode == 200) {
        print('$page번째 JSON 받아온거');
        print(response.body);

        // json->객체 매핑
        categoryResponse = category.CategoryResponse.fromJson(jsonDecode(response.body));

        resultMeta = categoryResponse.meta!;
        resultDocuments.addAll(categoryResponse.documents as Iterable<category.Documents>);

        resultCategoryResponse.meta = resultMeta; // shallow copy 일 것 같은데 상관없어 보임
        resultCategoryResponse.documents = resultDocuments;

        // 리스트 append 하고 리턴
        if (categoryResponse.meta?.isEnd == true) {
          return resultCategoryResponse;

          // 검색 결과가 더 있으면 추가적으로 요청함 (100건 이내일 경우)
        } else if (categoryResponse.meta?.isEnd == false) {
          if (categoryResponse.meta!.totalCount! > 100) {
            throw Exception('검색 결과가 100건을 넘습니다. 검색 반경을 줄여주세요.');
          }
          page++;
        }

      } else {
        throw Exception('API 호출결과 오류 page: $page');
      }
    }










  }

}