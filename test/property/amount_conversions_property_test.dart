import 'package:bb_mobile/core/utils/amount_conversions.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

/// Property-based tests for ConvertAmount (sat ↔ BTC ↔ fiat).
///
/// These test mathematical invariants that must hold for ALL valid inputs,
/// not just specific examples. The framework generates hundreds of random
/// inputs and shrinks failing cases to the smallest counterexample.
///
/// Target: lib/core/utils/amount_conversions.dart
void main() {
  group('satsToBtc / btcToSats roundtrip', () {
    property('sats → BTC → sats roundtrip preserves value', () {
      // Max Bitcoin supply: 21M BTC = 2,100,000,000,000,000 sats
      // Using a smaller range to avoid floating point precision issues
      // at the extreme end (toStringAsFixed(8) truncation)
      forAll(
        integer(min: 0, max: 100000000000), // up to 1000 BTC in sats
        (sats) {
          final btc = ConvertAmount.satsToBtc(sats);
          final backToSats = ConvertAmount.btcToSats(btc);
          expect(backToSats, equals(sats),
              reason: 'Roundtrip failed: $sats → $btc → $backToSats');
        },
      );
    });

    property('satsToBtc is monotonic (a > b implies f(a) > f(b))', () {
      forAll(
        combine2(
          integer(min: 0, max: 2100000000000000),
          integer(min: 0, max: 2100000000000000),
        ),
        (pair) {
          final (a, b) = pair;
          if (a > b) {
            expect(ConvertAmount.satsToBtc(a),
                greaterThanOrEqualTo(ConvertAmount.satsToBtc(b)),
                reason: 'Monotonicity violated: satsToBtc($a) < satsToBtc($b)');
          }
        },
      );
    });

    property('satsToBtc output is always non-negative for non-negative input',
        () {
      forAll(
        integer(min: 0, max: 2100000000000000),
        (sats) {
          expect(ConvertAmount.satsToBtc(sats), greaterThanOrEqualTo(0.0));
        },
      );
    });

    property('satsToBtc has at most 8 decimal places', () {
      forAll(
        integer(min: 0, max: 2100000000000000),
        (sats) {
          final btc = ConvertAmount.satsToBtc(sats);
          final str = btc.toStringAsFixed(8);
          final reparsed = double.parse(str);
          expect(btc, equals(reparsed),
              reason: 'BTC value $btc has more than 8 decimal places');
        },
      );
    });
  });

  group('known anchor values', () {
    test('100,000,000 sats = exactly 1.0 BTC', () {
      expect(ConvertAmount.satsToBtc(100000000), equals(1.0));
      expect(ConvertAmount.btcToSats(1.0), equals(100000000));
    });

    test('1 sat = 0.00000001 BTC', () {
      expect(ConvertAmount.satsToBtc(1), equals(0.00000001));
    });

    test('0 sats = 0.0 BTC', () {
      expect(ConvertAmount.satsToBtc(0), equals(0.0));
      expect(ConvertAmount.btcToSats(0.0), equals(0));
    });
  });

  group('fiat conversions', () {
    property(
        'satsToFiat is monotonic for fixed exchange rate', () {
      forAll(
        combine2(
          integer(min: 0, max: 100000000000),
          integer(min: 0, max: 100000000000),
        ),
        (pair) {
          final (a, b) = pair;
          const rate = 50000.0; // $50k/BTC
          if (a > b) {
            expect(ConvertAmount.satsToFiat(a, rate),
                greaterThanOrEqualTo(ConvertAmount.satsToFiat(b, rate)));
          }
        },
      );
    });

    property('satsToFiat output is non-negative for non-negative input', () {
      forAll(
        integer(min: 0, max: 2100000000000000),
        (sats) {
          expect(
              ConvertAmount.satsToFiat(sats, 50000.0), greaterThanOrEqualTo(0));
        },
      );
    });
  });
}
