class_name WorldDB
extends RefCounted
## The realms the Wanderer passes through, one per stage. Each world sets the look
## (palette, scenery, weather), tints its enemies, names its guardian boss and
## carries three journal pages of lore. After the last world, the cycle repeats
## as harder "Ascensions".
##
## The story: the Hollow King swallowed the sun. The Wanderer escaped with its last
## ember and must carry it to the top of the Hollow Spire to set the morning free.

const WORLDS := [
	{
		"id": "ashen_woods",
		"icon": "local_fire_department",
		"name": "The Ashen Woods",
		"tagline": "Where the first fires fell.",
		"color": Color("ff8a3d"),
		"floor": Color(0.22, 0.19, 0.18), "mortar": Color(0.1, 0.085, 0.08),
		"wall": Color("2a2420"), "trim": Color("3d332c"),
		"obstacle": "stump", "obstacle_color": Color("2b2622"), "accent": Color("ff7a1a"),
		"ambient": Color("4b4a62"), "bg": Color("0c0a0a"), "sun": Color("ffd2a8"),
		"light": Color("ff9a4d"), "weather": "embers",
		"tint": {},
		"boss": {"name": "CINDER GOLEM", "color": Color("ff5a1f"), "hp": 1.0},
	},
	{
		"id": "frostfell",
		"icon": "ac_unit",
		"name": "Frostfell Hollow",
		"tagline": "A cave where breath turns to ice.",
		"color": Color("7dd3fc"),
		"floor": Color(0.2, 0.25, 0.32), "mortar": Color(0.1, 0.13, 0.18),
		"wall": Color("1c2433"), "trim": Color("2e3b52"),
		"obstacle": "crystal", "obstacle_color": Color("3b5b7a"), "accent": Color("7dd3fc"),
		"ambient": Color("5a7099"), "bg": Color("070b12"), "sun": Color("cfe8ff"),
		"light": Color("8ad8ff"), "weather": "snow",
		"tint": {"grunt": Color("60a5fa"), "spitter": Color("c4b5fd"), "charger": Color("94a3b8")},
		"boss": {"name": "RIME COLOSSUS", "color": Color("7dd3fc"), "hp": 1.0},
	},
	{
		"id": "mire",
		"icon": "water_drop",
		"name": "The Drowned Mire",
		"tagline": "Gardens that remember the sun, and rot without it.",
		"color": Color("a3e635"),
		"floor": Color(0.17, 0.22, 0.17), "mortar": Color(0.08, 0.11, 0.08),
		"wall": Color("1f2a1f"), "trim": Color("33422f"),
		"obstacle": "ruin", "obstacle_color": Color("3f4a3a"), "accent": Color("84cc16"),
		"ambient": Color("4f6b4f"), "bg": Color("070c08"), "sun": Color("e3f5c8"),
		"light": Color("b5f55a"), "weather": "spores",
		"tint": {"grunt": Color("65a30d"), "spitter": Color("14b8a6"), "charger": Color("a16207")},
		"boss": {"name": "BOG WARDEN", "color": Color("84cc16"), "hp": 1.1},
	},
	{
		"id": "hollow_spire",
		"icon": "castle",
		"name": "The Hollow Spire",
		"tagline": "The throne of the one who ate the sun.",
		"color": Color("c084fc"),
		"floor": Color(0.14, 0.12, 0.2), "mortar": Color(0.06, 0.05, 0.1),
		"wall": Color("17132a"), "trim": Color("2a2340"),
		"obstacle": "obsidian", "obstacle_color": Color("1e1b2e"), "accent": Color("a855f7"),
		"ambient": Color("4c3f78"), "bg": Color("06040c"), "sun": Color("d8c8ff"),
		"light": Color("c084fc"), "weather": "motes",
		"tint": {"grunt": Color("a855f7"), "spitter": Color("f0abfc"), "charger": Color("6d28d9")},
		"boss": {"name": "THE HOLLOW KING", "color": Color("c084fc"), "hp": 1.25},
	},
]

## Journal pages. Page 0 unlocks on arrival, page 1 is a hidden find in that world,
## page 2 unlocks when its guardian falls.
const LORE := {
	"ashen_woods": [
		["The Last Ember", "The sun did not set. It was eaten. I watched the Hollow King swallow it whole from the Hearth Tower, and I ran with the only light he missed: a single ember, cupped in my hands like a wounded bird. It lives in my staff now. It is all that is left of the day."],
		["Ash Walkers", "The woods I grew up in are cinders. Things walk here now, shaped from whatever burned. They are drawn to the ember. Everything is."],
		["The Golem's Grief", "The Cinder Golem was once the forest's warden, a gentle thing of moss and stone. The Hollow filled it with ash. When it fell, I swear it looked relieved."],
	],
	"frostfell": [
		["Breath Turned to Ice", "Without the sun, the cold came down from the peaks like a tide. Frostfell was a mining town. The miners are still here, in a way."],
		["Why I Don't Stop", "Every time I make camp, the ember dims a little. If it goes out there will be no morning, ever again. So I walk."],
		["Rime Colossus", "It wore a crown of icicles and wept frost. Before the dark, they say it guarded the hot springs where children swam all winter."],
	],
	"mire": [
		["Gardens of Memory", "The Drowned Mire was the King's garden once, before he was the Hollow King, when he was only a man afraid of the night."],
		["A Familiar Hand", "The ruins here bear my old sigil. I helped build this place. I helped him. I did not know what he would become."],
		["The Bog Warden", "The Warden spoke as it died: 'He waits at the top of the Spire. He wants the ember back.' I had hoped he did not know I had it."],
	],
	"hollow_spire": [
		["The Spire", "The Spire is made of night, stacked like stones. At its peak the stolen sun hangs in a cage, dim and starving."],
		["Brother", "I will not write his name. We were apprentices together, two boys who feared the dark. Only one of us decided to devour it."],
		["Rekindling", "If you are reading this, the ember made it farther than I ever did. Open the cage. Let the morning back in. And if the dark returns, and it will, light it again."],
	],
}


static func count() -> int:
	return WORLDS.size()


## World index for a stage (1-based). Worlds cycle after the last one.
static func index_for_stage(stage: int) -> int:
	return (stage - 1) % WORLDS.size()


## 0 for the first pass through the worlds, 1+ for each Ascension after.
static func ascension_for_stage(stage: int) -> int:
	return (stage - 1) / WORLDS.size()


static func for_stage(stage: int) -> Dictionary:
	return WORLDS[index_for_stage(stage)]


static func page_id(world_id: String, page: int) -> String:
	return "%s:%d" % [world_id, page]


static func page(world_id: String, page_index: int) -> Array:
	return LORE[world_id][page_index]
