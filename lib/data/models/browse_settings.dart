import 'package:equatable/equatable.dart';

class BrowseSettings extends Equatable {
  final String id;
  final String liveNowLabel;
  final String liveNowSort;
  final bool liveNowEnabled;
  final String dealsLabel;
  final double dealsPrice;
  final bool dealsEnabled;
  final String saleComingLabel;
  final String saleComingSort;
  final bool saleComingEnabled;

  const BrowseSettings({
    required this.id,
    this.liveNowLabel = 'Live now',
    this.liveNowSort = 'popular',
    this.liveNowEnabled = true,
    this.dealsLabel = 'Deals at 99',
    this.dealsPrice = 99.0,
    this.dealsEnabled = true,
    this.saleComingLabel = 'Sale coming!',
    this.saleComingSort = 'new',
    this.saleComingEnabled = true,
  });

  factory BrowseSettings.fromJson(Map<String, dynamic> json) {
    return BrowseSettings(
      id: json['id'] as String? ?? 'popular_store_settings',
      liveNowLabel: json['live_now_label'] as String? ?? 'Live now',
      liveNowSort: json['live_now_sort'] as String? ?? 'popular',
      liveNowEnabled: json['live_now_enabled'] as bool? ?? true,
      dealsLabel: json['deals_label'] as String? ?? 'Deals at 99',
      dealsPrice: (json['deals_price'] as num?)?.toDouble() ?? 99.0,
      dealsEnabled: json['deals_enabled'] as bool? ?? true,
      saleComingLabel: json['sale_coming_label'] as String? ?? 'Sale coming!',
      saleComingSort: json['sale_coming_sort'] as String? ?? 'new',
      saleComingEnabled: json['sale_coming_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'live_now_label': liveNowLabel,
        'live_now_sort': liveNowSort,
        'live_now_enabled': liveNowEnabled,
        'deals_label': dealsLabel,
        'deals_price': dealsPrice,
        'deals_enabled': dealsEnabled,
        'sale_coming_label': saleComingLabel,
        'sale_coming_sort': saleComingSort,
        'sale_coming_enabled': saleComingEnabled,
      };

  @override
  List<Object?> get props => [
        id,
        liveNowLabel,
        liveNowSort,
        liveNowEnabled,
        dealsLabel,
        dealsPrice,
        dealsEnabled,
        saleComingLabel,
        saleComingSort,
        saleComingEnabled,
      ];
}
