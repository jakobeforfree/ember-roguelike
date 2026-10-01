extends Node
## Global signal bus so systems (UI, achievements, daily challenges, analytics)
## can react to gameplay without hard references.

signal player_damaged(amount: float)
signal player_dodged(perfect: bool)
signal enemy_killed(enemy_id: String, position: Vector3)
signal room_cleared(room_index: int)
signal loot_found(item: GearItem)
signal gold_changed(total: int)
