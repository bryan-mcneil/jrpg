import 'balance.dart';
import 'elements.dart';

/// Usable battle items (DESIGN.md §3.8): consumables that heal a resource,
/// empower the party, or land a status on an enemy. The ITEM command on both
/// battle menus spends one of these. Items are *physical*, not 言霊 — so 封印
/// (the word-seal) never locks them.
enum ItemEffectKind {
  /// Restore the player's HP.
  healHp,

  /// Restore MP.
  healMp,

  /// Restore SP.
  healSp,

  /// Temporary +ATK, identical to the 力 boon buff.
  empower,

  /// Inflict a status on a target enemy (respects themed immunity).
  ailment,
}

class ItemSpec {
  const ItemSpec({
    required this.id,
    required this.name,
    required this.glyph,
    required this.kind,
    this.amount = 0,
    this.status,
  });

  final String id;
  final String name;

  /// A single kanji shown on the item button.
  final String glyph;
  final ItemEffectKind kind;

  /// HP/MP/SP restored, or buff rounds for [ItemEffectKind.empower].
  final int amount;

  /// The status [ItemEffectKind.ailment] inflicts.
  final StatusType? status;

  /// Ailment items pick an enemy; everything else affects the party.
  bool get targetsEnemy => kind == ItemEffectKind.ailment;
}

/// The v1 item catalogue, keyed by id. Magnitudes live in balance.dart.
const itemCatalog = <String, ItemSpec>{
  'potion': ItemSpec(
    id: 'potion',
    name: '回復薬',
    glyph: '薬',
    kind: ItemEffectKind.healHp,
    amount: itemHealHp,
  ),
  'ether': ItemSpec(
    id: 'ether',
    name: '魔力の雫',
    glyph: '魔',
    kind: ItemEffectKind.healMp,
    amount: itemHealMp,
  ),
  'restorative': ItemSpec(
    id: 'restorative',
    name: '気付け薬',
    glyph: '気',
    kind: ItemEffectKind.healSp,
    amount: itemHealSp,
  ),
  'tonic': ItemSpec(
    id: 'tonic',
    name: '力の薬',
    glyph: '力',
    kind: ItemEffectKind.empower,
    amount: boonRounds,
  ),
  'firecharm': ItemSpec(
    id: 'firecharm',
    name: '火炎の札',
    glyph: '火',
    kind: ItemEffectKind.ailment,
    status: StatusType.burn,
  ),
};

/// Placeholder battle loadout until the M4 KP/coin economy fills the bag.
const defaultItemLoadout = <String, int>{
  'potion': 3,
  'ether': 2,
  'restorative': 2,
  'tonic': 1,
  'firecharm': 2,
};
