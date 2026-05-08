/// Konstanta domain — bukan untuk theme/styling.
class AppConstants {
  /// Harga referensi TBS (Tandan Buah Segar) per ton dalam Rupiah.
  /// Update jika harga pasar berubah signifikan.
  static const double defaultHargaTbs = 2400000;

  /// Maksimum ton aktual per panen (validation upper bound).
  static const double maxTonPerPanen = 10000;
}
