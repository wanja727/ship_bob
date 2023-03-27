import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_map/models/category_response.dart' as category;
import 'package:kakao_map/models/coord2address_response.dart';
import 'package:kakao_map/screens/main.dart';

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
    Future<category.CategoryResponse> getNearRestaurants (WidgetRef ref, double lat, double lng, int radius) async {

    // API 결과저장
    category.CategoryResponse categoryResponse;

    // 최종 리턴값
    category.CategoryResponse resultCategoryResponse = category.CategoryResponse();
    List<category.Documents> resultDocuments = [];
    category.Meta resultMeta;

    int page = 1;
    Uri uri;
    http.Response response;

    // 동일 조건일 경우 API호출 안하고 이전 데이터 리턴하도록
    category.CategoryResponse categoryRes = ref.read(categoryResponseProvider);
    if(categoryRes.meta?.lat == lat && categoryRes.meta?.lng == lng && categoryRes.meta?.radius == radius){
      print('API호출 안하고 기존 데이터 사용함 (동일한 조건으로 API호출시)');
      return categoryRes;
    }

    while(true) {
      // print("$page번째 API호출 : https://dapi.kakao.com/v2/local/search/category.json?category\_group\_code=FD6&y=$lat&x=$lng&radius=$radius&page=$page");
      uri = Uri.parse("https://dapi.kakao.com/v2/local/search/category.json?category\_group\_code=FD6&y=$lat&x=$lng&radius=$radius&page=$page");
      response = await http.get(uri, headers: {"Authorization": "KakaoAK 90a5b736903df69338d565b1f3fa99a0"});

      if (response.statusCode == 200) {
        // print('$page번째 JSON 받아온거');
        // print(response.body);

        // json->객체 매핑
        categoryResponse = category.CategoryResponse.fromJson(jsonDecode(response.body));

        resultMeta = categoryResponse.meta!;
        resultDocuments.addAll(categoryResponse.documents as Iterable<category.Documents>);

        resultCategoryResponse.meta = resultMeta; // shallow copy 일 것 같은데 상관없어 보임
        resultCategoryResponse.documents = resultDocuments;

        // 리스트 append 하고 리턴
        if (categoryResponse.meta?.isEnd == true) {

          resultCategoryResponse.meta?.lat = lat;
          resultCategoryResponse.meta?.lng = lng;
          resultCategoryResponse.meta?.radius = radius;

          // for (var element in resultDocuments) {
          //   element.placeName = '${resultDocuments.indexOf(element)+1}.element.placeName';
          // }

          resultDocuments.asMap().forEach((index, value) {
            value.placeName = '${index+1}.${value.placeName}';
          });

          categoryRes.setCategoryResponse(resultDocuments, resultMeta);

          return resultCategoryResponse;

          // 검색 결과가 더 있으면 추가적으로 요청함
        } else if (categoryResponse.meta?.isEnd == false) {
          page++;

          // API 스펙 자체가 최대 45건 까지만 받을수 있음
          // if (categoryResponse.meta!.totalCount! > 100) {
          //   throw Exception('검색 결과가 100건을 넘습니다. 검색 반경을 줄여주세요.');
          // }
        }

      } else {
        throw Exception('API 호출결과 오류 page: $page');
      }
    }

  }

}