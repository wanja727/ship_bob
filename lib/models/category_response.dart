class CategoryResponse {
  List<Documents>? documents;
  Meta? meta;

  CategoryResponse({this.documents, this.meta});

  CategoryResponse.fromJson(Map<String, dynamic> json) {
    if (json['documents'] != null) {
      documents = <Documents>[];
      json['documents'].forEach((v) {
        documents!.add(new Documents.fromJson(v));
      });
    }
    meta = json['meta'] != null ? new Meta.fromJson(json['meta']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.documents != null) {
      data['documents'] = this.documents!.map((v) => v.toJson()).toList();
    }
    if (this.meta != null) {
      data['meta'] = this.meta!.toJson();
    }
    return data;
  }
}

class Documents {
  String? addressName;
  String? categoryGroupCode;
  String? categoryGroupName;
  String? categoryName;
  String? distance;
  String? id;
  String? phone;
  String? placeName;
  String? placeUrl;
  String? roadAddressName;
  String? x;
  String? y;

  Documents(
      {this.addressName,
        this.categoryGroupCode,
        this.categoryGroupName,
        this.categoryName,
        this.distance,
        this.id,
        this.phone,
        this.placeName,
        this.placeUrl,
        this.roadAddressName,
        this.x,
        this.y});

  Documents.fromJson(Map<String, dynamic> json) {
    addressName = json['address_name'];
    categoryGroupCode = json['category_group_code'];
    categoryGroupName = json['category_group_name'];
    categoryName = json['category_name'];
    distance = json['distance'];
    id = json['id'];
    phone = json['phone'];
    placeName = json['place_name'];
    placeUrl = json['place_url'];
    roadAddressName = json['road_address_name'];
    x = json['x'];
    y = json['y'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['address_name'] = this.addressName;
    data['category_group_code'] = this.categoryGroupCode;
    data['category_group_name'] = this.categoryGroupName;
    data['category_name'] = this.categoryName;
    data['distance'] = this.distance;
    data['id'] = this.id;
    data['phone'] = this.phone;
    data['place_name'] = this.placeName;
    data['place_url'] = this.placeUrl;
    data['road_address_name'] = this.roadAddressName;
    data['x'] = this.x;
    data['y'] = this.y;
    return data;
  }
}

class Meta {
  bool? isEnd;
  int? pageableCount;
  Null? sameName;
  int? totalCount;

  Meta({this.isEnd, this.pageableCount, this.sameName, this.totalCount});

  Meta.fromJson(Map<String, dynamic> json) {
    isEnd = json['is_end'];
    pageableCount = json['pageable_count'];
    sameName = json['same_name'];
    totalCount = json['total_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_end'] = this.isEnd;
    data['pageable_count'] = this.pageableCount;
    data['same_name'] = this.sameName;
    data['total_count'] = this.totalCount;
    return data;
  }
}
