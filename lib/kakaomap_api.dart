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
  Future<List<category.Documents>> getNearRestaurants (double lat, double lng, int radius) async {
    // String address = "";

    List<category.Documents> nearRestaurants = [];

    Uri uri = Uri.parse("https://dapi.kakao.com/v2/local/search/category.json?category\_group\_code=FD6&y=$lat&x=$lng&radius=$radius");

    final response = await http.get(uri, headers: {"Authorization": "KakaoAK 90a5b736903df69338d565b1f3fa99a0"});

    if (response.statusCode == 200) {
      // print('JSON 받아온거');
      // print(response.body);

      category.CategoryResponse categoryResponse = category.CategoryResponse.fromJson(jsonDecode(response.body));

      nearRestaurants = categoryResponse.documents!.map<category.Documents>( (element) {
        return element;
      }).toList();

      return nearRestaurants;

    } else {
      throw Exception('API 호출결과 오류 (statusCode != 200)');
    }
  }

}