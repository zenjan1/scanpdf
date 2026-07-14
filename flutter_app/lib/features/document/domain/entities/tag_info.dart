/// 标签信息
class TagInfo {
  final String name;
  final int count;

  const TagInfo({required this.name, required this.count});

  factory TagInfo.fromMap(Map<String, dynamic> map) {
    return TagInfo(
      name: map['name'] as String,
      count: map['count'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'count': count,
      };
}
