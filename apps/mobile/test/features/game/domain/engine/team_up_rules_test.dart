import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/engine/team_up_rules.dart';

void main() {
  group('TeamUpRules teams and stacking', () {
    test('assigns the agreed teammates without relying on pawn colour logic', () {
      expect(TeamUpRules.teammateFor('orange'), 'magenta');
      expect(TeamUpRules.teammateFor('magenta'), 'orange');
      expect(TeamUpRules.teammateFor('green'), 'blue');
      expect(TeamUpRules.teammateFor('blue'), 'green');
      expect(TeamUpRules.teamFor('orange'), TeamUpTeam.a);
      expect(TeamUpRules.teamFor('magenta'), TeamUpTeam.a);
      expect(TeamUpRules.teamFor('green'), TeamUpTeam.b);
      expect(TeamUpRules.teamFor('blue'), TeamUpTeam.b);
    });

    test('friendly teammates can stack and never count as opposing teams', () {
      expect(
        TeamUpRules.classifyCell(
          arrivingPlayerId: 'green',
          occupyingPlayerId: 'blue',
          isSafeCell: false,
        ),
        TeamUpCellOutcome.friendlyStack,
      );
      expect(
        TeamUpRules.classifyCell(
          arrivingPlayerId: 'orange',
          occupyingPlayerId: 'magenta',
          isSafeCell: false,
        ),
        TeamUpCellOutcome.friendlyStack,
      );
    });

    test('opposing teams are classified for stack capture on unsafe cells', () {
      expect(
        TeamUpRules.classifyCell(
          arrivingPlayerId: 'orange',
          occupyingPlayerId: 'blue',
          isSafeCell: false,
        ),
        TeamUpCellOutcome.opposingStack,
      );
    });

    test('last-arrival capture priority is deterministic', () {
      expect(
        TeamUpRules.selectLastArrivalPawnId(<String, int>{
          'green_pawn_1': 3,
          'blue_pawn_2': 8,
          'blue_pawn_3': 5,
        }),
        'blue_pawn_2',
      );
      expect(
        TeamUpRules.selectLastArrivalPawnId(<String, int>{
          'blue_pawn_2': 5,
          'green_pawn_1': 5,
        }),
        'blue_pawn_2',
        reason: 'Equal move versions use a stable pawn-ID tie-break.',
      );
      expect(TeamUpRules.selectLastArrivalPawnId(<String, int>{}), isNull);
    });

    test('safe cells protect all teams, including opposing colours', () {
      expect(
        TeamUpRules.classifyCell(
          arrivingPlayerId: 'orange',
          occupyingPlayerId: 'blue',
          isSafeCell: true,
        ),
        TeamUpCellOutcome.safeCell,
      );
    });
  });

  group('TeamUpRules dice transfer', () {
    test('preserves fixed Orange, Green, Magenta, Blue seat order', () {
      expect(TeamUpRules.turnOrder, <String>[
        'orange',
        'green',
        'magenta',
        'blue',
      ]);
    });

    test('finished Orange transfers scheduled roll to Magenta', () {
      expect(
        TeamUpRules.recipientForScheduledRoll(
          scheduledPlayerId: 'orange',
          playersWithAllPawnsFinished: <String>{'orange'},
        ),
        'magenta',
      );
    });

    test('finished Green transfers scheduled roll to Blue', () {
      expect(
        TeamUpRules.recipientForScheduledRoll(
          scheduledPlayerId: 'green',
          playersWithAllPawnsFinished: <String>{'green'},
        ),
        'blue',
      );
    });

    test('unfinished player rolls for themselves', () {
      expect(
        TeamUpRules.recipientForScheduledRoll(
          scheduledPlayerId: 'orange',
          playersWithAllPawnsFinished: <String>{},
        ),
        'orange',
      );
    });

    test('skips a scheduled turn if both teammates finished', () {
      expect(
        TeamUpRules.recipientForScheduledRoll(
          scheduledPlayerId: 'orange',
          playersWithAllPawnsFinished: <String>{'orange', 'magenta'},
        ),
        isNull,
      );
    });

    test('bonus roll stays with recipient and transfers again if needed', () {
      expect(
        TeamUpRules.recipientForBonusRoll(
          rollRecipientPlayerId: 'magenta',
          playersWithAllPawnsFinished: <String>{'orange'},
        ),
        'magenta',
      );
      expect(
        TeamUpRules.recipientForBonusRoll(
          rollRecipientPlayerId: 'magenta',
          playersWithAllPawnsFinished: <String>{'orange', 'magenta'},
        ),
        isNull,
      );
    });

    test('team wins only when both teammates have all four pawns finished', () {
      expect(
        TeamUpRules.hasTeamWon(
          team: TeamUpTeam.a,
          playersWithAllPawnsFinished: <String>{'orange'},
        ),
        isFalse,
      );
      expect(
        TeamUpRules.hasTeamWon(
          team: TeamUpTeam.a,
          playersWithAllPawnsFinished: <String>{'orange', 'magenta'},
        ),
        isTrue,
      );
      expect(
        TeamUpRules.hasTeamWon(
          team: TeamUpTeam.b,
          playersWithAllPawnsFinished: <String>{'green', 'blue'},
        ),
        isTrue,
      );
    });
  });
}
