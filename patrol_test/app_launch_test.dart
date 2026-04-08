import 'package:bb_mobile/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/test_constants.dart';
import 'helpers/test_helpers.dart';

/// ============================================================
/// Bull Bitcoin Mobile — Smoke Tests
/// ============================================================
///
/// These 5 tests verify the app's basic health:
///   1. Fresh install → onboarding screen
///   2. Create wallet → home screen
///   3. Receive button → navigates to receive screen
///   4. Send button → navigates to send screen
///   5. Wallet cards → shows Bitcoin and Liquid wallets
///
/// KEY PATTERNS (see helpers/test_helpers.dart):
///   - Never pumpAndSettle() — use waitForText() polling loop
///   - Use $.tester.tap() to bypass Patrol hit-test for obscured widgets
///   - All assertion text from helpers/test_constants.dart (sourced from app_en.arb)
///
/// ============================================================

void main() {
  // ----------------------------------------------------------
  // TEST 1: App Launch → Onboarding Screen
  // ----------------------------------------------------------
  patrolTest(
    'app launches and shows onboarding for fresh install',
    ($) async {
      app.main();
      final found = await waitForText($, TestStrings.createNewWallet);
      expect(found, isTrue, reason: 'Onboarding did not appear within 30s');
      expect(find.text(TestStrings.recoverWallet), findsOneWidget);
      expect(find.text(TestStrings.advancedOptions), findsOneWidget);
    },
  );

  // ----------------------------------------------------------
  // TEST 2: Create Wallet → Wallet Home
  // ----------------------------------------------------------
  patrolTest(
    'create wallet and land on home screen',
    ($) async {
      await launchAndCreateWallet($);
      expect(find.text(TestStrings.send), findsWidgets);
    },
  );

  // ----------------------------------------------------------
  // TEST 3: Tap Receive → Navigate to Receive Screen
  // ----------------------------------------------------------
  patrolTest(
    'receive button navigates to receive screen',
    ($) async {
      await launchAndCreateWallet($);

      await $.tester.tap(find.text(TestStrings.receive));
      await $.pump(const Duration(seconds: 5));

      // Look for receive screen content
      final receiveScreen = await waitForText(
        $,
        TestStrings.receiveAddress,
        timeout: TestTimeouts.standard,
      );

      if (!receiveScreen) {
        // Fallback: check for QR-related Image widgets
        final hasQr = $.tester.any(find.byType(Image));
        expect(hasQr, isTrue,
            reason: 'Receive screen did not appear after tapping Receive');
      }
    },
  );

  // ----------------------------------------------------------
  // TEST 4: Tap Send → Navigate to Send Screen
  // ----------------------------------------------------------
  patrolTest(
    'send button navigates to send screen',
    ($) async {
      await launchAndCreateWallet($);

      await $.tester.tap(find.text(TestStrings.send));
      await $.pump(const Duration(seconds: 5));
      await $.pump(const Duration(seconds: 3));

      // Verify we left home — Receive button should be gone
      final stillOnHome = $.tester.any(find.text(TestStrings.receive));
      expect(stillOnHome, isFalse,
          reason: 'Still on home screen — Send tap did not navigate');
    },
  );

  // ----------------------------------------------------------
  // TEST 5: Wallet Home Shows Wallet Cards
  // ----------------------------------------------------------
  // After wallet creation, the home should show wallet cards with
  // localized labels: "Secure Bitcoin" and "Instant payments".
  // This tests that BDK and LWK initialized correctly and
  // CreateDefaultWalletsUsecase created both default wallets.
  //
  patrolTest(
    'wallet home shows bitcoin and liquid wallet cards',
    ($) async {
      await launchAndCreateWallet($);

      // Wallet cards show localized labels, not literal network names.
      // Source: wallet.displayLabel(context) → app_en.arb defaults
      final hasBitcoin = await waitForText(
        $,
        TestStrings.bitcoinWalletLabel,
        timeout: TestTimeouts.standard,
      );
      final hasLiquid = await waitForText(
        $,
        TestStrings.liquidWalletLabel,
        timeout: TestTimeouts.standard,
      );

      expect(hasBitcoin, isTrue,
          reason: 'Bitcoin wallet card not found on home screen');
      expect(hasLiquid, isTrue,
          reason: 'Liquid wallet card not found on home screen');
    },
  );
}
