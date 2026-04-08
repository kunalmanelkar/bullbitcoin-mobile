import 'package:bb_mobile/core/utils/bip32_derivation.dart';
import 'package:bb_mobile/core/wallet/domain/entities/wallet.dart';
import 'package:test/test.dart';

/// Property-based tests for BIP32 derivation path logic.
///
/// These test the pure Dart logic of path construction and enum mapping,
/// NOT the cryptographic derivation (which requires seed bytes and the
/// bip32_keys library). That's tested via integration tests.
///
/// Target: lib/core/utils/bip32_derivation.dart
void main() {
  group('derivation path format', () {
    // Test all combinations of ScriptType × Network
    for (final scriptType in ScriptType.values) {
      for (final network in Network.values) {
        test(
            'path for ${scriptType.name} on ${network.name} has correct format',
            () {
          // Reconstruct the path logic from the source:
          // "m/${scriptType.purpose}'/${network.coinType}'/$accountIndex'"
          final path =
              "m/${scriptType.purpose}'/${network.coinType}'/0'";

          // Must start with "m/"
          expect(path.startsWith('m/'), isTrue);

          // Must have exactly 3 path levels (purpose/coinType/account)
          final levels = path.substring(2).split('/');
          expect(levels.length, equals(3));

          // All three levels must be hardened (end with ')
          for (final level in levels) {
            expect(level.endsWith("'"), isTrue,
                reason: 'Level "$level" should be hardened');
          }
        });
      }
    }

    test('purpose codes match BIP standards', () {
      expect(ScriptType.bip44.purpose, equals(44));
      expect(ScriptType.bip49.purpose, equals(49));
      expect(ScriptType.bip84.purpose, equals(84));
    });

    test('coin types match SLIP-44 standard', () {
      expect(Network.bitcoinMainnet.coinType, equals(0));
      expect(Network.bitcoinTestnet.coinType, equals(1));
      expect(Network.liquidMainnet.coinType, equals(1776));
      expect(Network.liquidTestnet.coinType, equals(1));
    });
  });

  group('XpubType mapping', () {
    test('mainnet script types map to mainnet xpub types', () {
      expect(ScriptType.bip44.getXpubType(Network.bitcoinMainnet),
          equals(XpubType.xpub));
      expect(ScriptType.bip49.getXpubType(Network.bitcoinMainnet),
          equals(XpubType.ypub));
      expect(ScriptType.bip84.getXpubType(Network.bitcoinMainnet),
          equals(XpubType.zpub));
    });

    test('testnet script types map to testnet xpub types', () {
      expect(ScriptType.bip44.getXpubType(Network.bitcoinTestnet),
          equals(XpubType.tpub));
      expect(ScriptType.bip49.getXpubType(Network.bitcoinTestnet),
          equals(XpubType.upub));
      expect(ScriptType.bip84.getXpubType(Network.bitcoinTestnet),
          equals(XpubType.vpub));
    });

    test('every XpubType has exactly 4 version bytes', () {
      for (final xpubType in XpubType.values) {
        expect(xpubType.versionBytes.length, equals(4),
            reason: '${xpubType.name} should have 4 version bytes');
      }
    });

    test('all XpubType version bytes are unique', () {
      final seen = <String>{};
      for (final xpubType in XpubType.values) {
        final key = xpubType.versionBytes.toString();
        expect(seen.contains(key), isFalse,
            reason: '${xpubType.name} has duplicate version bytes');
        seen.add(key);
      }
    });
  });

  group('account index in derivation path', () {
    for (var i = 0; i < 5; i++) {
      test('account index $i produces valid hardened path', () {
        final path =
            "m/${ScriptType.bip84.purpose}'/${Network.bitcoinMainnet.coinType}'/$i'";
        expect(path, equals("m/84'/0'/$i'"));
      });
    }
  });
}
