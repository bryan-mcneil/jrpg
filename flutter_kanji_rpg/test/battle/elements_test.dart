import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kanji_rpg/battle/elements.dart';

void main() {
  group('overcoming cycle (§3.5)', () {
    test('water douses fire', () {
      expect(matchup(BattleElement.water, BattleElement.fire), 2.0);
      expect(matchup(BattleElement.fire, BattleElement.water), 0.5);
    });

    test('fire melts metal', () {
      expect(matchup(BattleElement.fire, BattleElement.metal), 2.0);
      expect(matchup(BattleElement.metal, BattleElement.fire), 0.5);
    });

    test('metal chops wood, wood breaks earth, earth dams water', () {
      expect(matchup(BattleElement.metal, BattleElement.wood), 2.0);
      expect(matchup(BattleElement.wood, BattleElement.earth), 2.0);
      expect(matchup(BattleElement.earth, BattleElement.water), 2.0);
    });

    test('non-adjacent pairs are neutral', () {
      expect(matchup(BattleElement.fire, BattleElement.wood), 1.0);
      expect(matchup(BattleElement.water, BattleElement.metal), 1.0);
      expect(matchup(BattleElement.fire, BattleElement.fire), 1.0);
    });

    test('light and dark counter each other, neutral elsewhere', () {
      expect(matchup(BattleElement.light, BattleElement.dark), 2.0);
      expect(matchup(BattleElement.dark, BattleElement.light), 2.0);
      expect(matchup(BattleElement.light, BattleElement.fire), 1.0);
      expect(matchup(BattleElement.fire, BattleElement.dark), 1.0);
      expect(matchup(BattleElement.light, BattleElement.light), 1.0);
    });
  });

  test('generating cycle 水→木→火→土→金→水', () {
    expect(generates[BattleElement.water], BattleElement.wood);
    expect(generates[BattleElement.wood], BattleElement.fire);
    expect(generates[BattleElement.fire], BattleElement.earth);
    expect(generates[BattleElement.earth], BattleElement.metal);
    expect(generates[BattleElement.metal], BattleElement.water);
  });

  test('orb statuses: 火→burn, 水→freeze, 金→seal, 闇→confusion', () {
    expect(orbStatus[BattleElement.fire], StatusType.burn);
    expect(orbStatus[BattleElement.water], StatusType.freeze);
    expect(orbStatus[BattleElement.metal], StatusType.seal);
    expect(orbStatus[BattleElement.dark], StatusType.confusion);
    expect(orbStatus[BattleElement.wood], isNull);
  });

  test('every dictionary tag string parses as element or modifier', () {
    const tags = [
      'wood', 'fire', 'earth', 'metal', 'water', 'light', 'dark', //
      'storm', 'blade', 'ward', 'amp', 'orb', 'mend', 'boon',
    ];
    for (final t in tags) {
      expect(elementFromTag(t) != null || modifierFromTag(t) != null, isTrue,
          reason: 'tag $t must parse');
      expect(elementFromTag(t) != null && modifierFromTag(t) != null, isFalse,
          reason: 'tag $t must be unambiguous');
    }
  });
}
