class Offer {
  final int offerId;
  final int userId;
  final String offerName;
  final String offerDesc;
  final double offerPrice;
  final int offerQuantity;
  final String offerStartDate;
  final String offerEndDate;
  final String? offerImage; // Nullable for cases where image is null
  final String offerDateCreated;

  Offer({
    required this.offerId,
    required this.userId,
    required this.offerName,
    required this.offerDesc,
    required this.offerPrice,
    required this.offerQuantity,
    required this.offerStartDate,
    required this.offerEndDate,
    this.offerImage,
    required this.offerDateCreated,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      offerId: json['offerId'],
      userId: json['userId'],
      offerName: json['offerName'],
      offerDesc: json['offerDesc'],
      offerPrice: (json['offerPrice'] as num).toDouble(),
      offerQuantity: json['offerQuantity'],
      offerStartDate: json['offerStartDate'],
      offerEndDate: json['offerEndDate'],
      offerImage: json['offerImage'],
      offerDateCreated: json['offerDateCreated'],
    );
  }
}
