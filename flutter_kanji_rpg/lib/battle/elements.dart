import 'balance.dart';

/// The seven elements (wuxing five + the rare light/dark pair) and the six
/// modifier classes — together they cover every `tag` value in the
/// kanji_entries table (DESIGN.md §3.5, §3.7).
enum BattleElement { wood, fire, earth, metal, water, light, dark }

enum ModifierClass { storm, blade, ward, amp, orb, mend, boon }

/// The four v1 statuses (DESIGN.md §3.6).
enum StatusType { confusion, burn, freeze, seal }

BattleElement? elementFromTag(String tag) => switch (tag) {
      'wood' => BattleElement.wood,
      'fire' => BattleElement.fire,
      'earth' => BattleElement.earth,
      'metal' => BattleElement.metal,
      'water' => BattleElement.water,
      'light' => BattleElement.light,
      'dark' => BattleElement.dark,
      _ => null,
    };

ModifierClass? modifierFromTag(String tag) => switch (tag) {
      'storm' => ModifierClass.storm,
      'blade' => ModifierClass.blade,
      'ward' => ModifierClass.ward,
      'amp' => ModifierClass.amp,
      'orb' => ModifierClass.orb,
      'mend' => ModifierClass.mend,
      'boon' => ModifierClass.boon,
      _ => null,
    };

const elementGlyphs = {
  BattleElement.wood: '木',
  BattleElement.fire: '火',
  BattleElement.earth: '土',
  BattleElement.metal: '金',
  BattleElement.water: '水',
  BattleElement.light: '光',
  BattleElement.dark: '闇',
};

const statusGlyphs = {
  StatusType.confusion: '混乱',
  StatusType.burn: '火傷',
  StatusType.freeze: '凍結',
  StatusType.seal: '封印',
};

/// Overcoming cycle 水→火→金→木→土→水: attacker overcomes value.
const Map<BattleElement, BattleElement> overcomes = {
  BattleElement.water: BattleElement.fire,
  BattleElement.fire: BattleElement.metal,
  BattleElement.metal: BattleElement.wood,
  BattleElement.wood: BattleElement.earth,
  BattleElement.earth: BattleElement.water,
};

/// Generating cycle 水→木→火→土→金→水: key generates value.
const Map<BattleElement, BattleElement> generates = {
  BattleElement.water: BattleElement.wood,
  BattleElement.wood: BattleElement.fire,
  BattleElement.fire: BattleElement.earth,
  BattleElement.earth: BattleElement.metal,
  BattleElement.metal: BattleElement.water,
};

/// Damage multiplier for [attacker] hitting [defender]: 2× along the
/// overcoming cycle, 0.5× against the reverse direction, light↔dark 2×,
/// otherwise neutral.
double matchup(BattleElement attacker, BattleElement defender) {
  if (overcomes[attacker] == defender) return overcomeMult;
  if (overcomes[defender] == attacker) return resistMult;
  final lightDark = {BattleElement.light, BattleElement.dark};
  if (attacker != defender &&
      lightDark.contains(attacker) &&
      lightDark.contains(defender)) {
    return overcomeMult;
  }
  return 1.0;
}

/// Status an orb (珠) spell inflicts, by spell element. Elements without a
/// v1 status deal orb damage with no rider.
const Map<BattleElement, StatusType> orbStatus = {
  BattleElement.fire: StatusType.burn,
  BattleElement.water: StatusType.freeze,
  BattleElement.metal: StatusType.seal,
  BattleElement.dark: StatusType.confusion,
};
