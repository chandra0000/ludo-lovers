import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_rule_profile.dart';

void main() {
  test('profile defensively copies and freezes safe-cell indexes', () {
    final safeCells = <int>{0, 8};
    final profile = LudoRuleProfile(safeCellIndexes: safeCells);

    safeCells.add(13);

    expect(profile.safeCellIndexes, equals(<int>{0, 8}));
    expect(
      () => profile.safeCellIndexes.add(21),
      throwsUnsupportedError,
    );
  });

  test('profile rejects invalid identity, version, and rule limits', () {
    expect(() => LudoRuleProfile(id: ' '), throwsArgumentError);
    expect(() => LudoRuleProfile(version: 0), throwsArgumentError);
    expect(
      () => LudoRuleProfile(maxConsecutiveSixes: 0),
      throwsArgumentError,
    );
    expect(
      () => LudoRuleProfile(safeCellIndexes: <int>{-1}),
      throwsArgumentError,
    );
  });

  test('provisional classic profile has explicit documented defaults', () {
    final profile = LudoRuleProfile();

    expect(profile.id, 'classic-v1-provisional');
    expect(profile.version, 1);
    expect(profile.sixRequiredToEnter, isTrue);
    expect(profile.requireExactFinishRoll, isTrue);
    expect(profile.maxConsecutiveSixes, 3);
    expect(profile.thirdSixEndsTurnWithoutMove, isTrue);
    expect(profile.captureOnlySingleOpponentPawn, isTrue);
    expect(profile.finishEndsMatchImmediately, isTrue);
  });
}
