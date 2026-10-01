class_name Icons
extends RefCounted
## Material Icons (Apache 2.0) glyph lookup. Use with UiKit.icon().

const CODES := {
	"favorite": 0xe87d, "shield": 0xe9e0, "bolt": 0xea0b, "local_fire_department": 0xef55, "ac_unit": 0xeb3b,
	"flash_on": 0xe3e7, "whatshot": 0xe80e, "water_drop": 0xe798, "speed": 0xe9e4, "directions_run": 0xe566,
	"military_tech": 0xea3f, "diamond": 0xead5, "paid": 0xf041, "pause": 0xe034, "gps_fixed": 0xe1b3,
	"call_split": 0xe0b6, "trending_up": 0xe8e5, "healing": 0xe3f3, "spa": 0xeb4c, "self_improvement": 0xea78,
	"auto_awesome": 0xe65f, "star": 0xe838, "lock": 0xe897, "close": 0xe5cd, "play_arrow": 0xe037,
	"inventory_2": 0xe1a1, "person": 0xe7fd, "sell": 0xf05b, "back_hand": 0xe764, "radio_button_checked": 0xe837,
	"circle": 0xef4a, "bloodtype": 0xefe4, "my_location": 0xe55c, "double_arrow": 0xea50, "explore": 0xe87a,
	"emoji_events": 0xea23, "hiking": 0xe50a, "workspace_premium": 0xe7af, "sports_motorsports": 0xea2d,
	"dangerous": 0xe99a, "blur_on": 0xe3a5, "open_in_full": 0xf1ce, "air": 0xefd8, "arrow_forward": 0xe5c8,
	"replay": 0xe042, "home": 0xe88a, "toll": 0xe8e0, "upgrade": 0xf0fb, "timer": 0xe425, "castle": 0xeab1,
	"add": 0xe145, "check": 0xe5ca, "settings": 0xe8b8, "sports_esports": 0xea28,
}


static func glyph(name: String) -> String:
	return char(CODES.get(name, 0xef4a))
