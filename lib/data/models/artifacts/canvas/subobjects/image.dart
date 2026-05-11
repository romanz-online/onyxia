class ImageProperties {
  String imageUrl;

  ImageProperties({this.imageUrl = ''});

  factory ImageProperties.initial() => ImageProperties(imageUrl: '');

  @override
  String toString() {
    return 'ImageProperties('
        'imageUrl: $imageUrl, '
        ')';
  }

  Map<String, dynamic> toMap() {
    return {'image_url': imageUrl};
  }

  factory ImageProperties.fromMap(Map<String, dynamic> map) {
    try {
      return ImageProperties(imageUrl: map['image_url'] ?? '');
    } catch (e) {
      // Return a completely default ImageProperties if parsing fails entirely
      return ImageProperties();
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ImageProperties && other.imageUrl == imageUrl;
  }

  @override
  int get hashCode => imageUrl.hashCode;
}
