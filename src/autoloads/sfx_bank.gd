extends Node
## Preloads all sound effects for quick access.

var sounds: Dictionary = {}

const SFX_FILES := {
	"keypress": "res://assets/audio/sfx/keypress.wav",
	"enter": "res://assets/audio/sfx/enter.wav",
	"notification": "res://assets/audio/sfx/notification.wav",
	"error": "res://assets/audio/sfx/error.wav",
	"case_received": "res://assets/audio/sfx/case_received.wav",
	"case_complete": "res://assets/audio/sfx/case_complete.wav",
	"coffee": "res://assets/audio/sfx/coffee.wav",
	"cat_purr": "res://assets/audio/sfx/cat_purr.wav",
	"cat_meow": "res://assets/audio/sfx/cat_meow.wav",
	"sleep": "res://assets/audio/sfx/sleep.wav",
	"interact": "res://assets/audio/sfx/interact.wav",
	"menu_move": "res://assets/audio/sfx/menu_move.wav",
	"menu_select": "res://assets/audio/sfx/menu_select.wav",
	"promotion": "res://assets/audio/sfx/promotion.wav",
}


func _ready() -> void:
	for key: String in SFX_FILES:
		var path: String = SFX_FILES[key]
		if ResourceLoader.exists(path):
			sounds[key] = load(path)


func play(sound_name: String) -> void:
	if sounds.has(sound_name):
		AudioManager.play_sfx_oneshot(sounds[sound_name])


func play_music(track_name: String) -> void:
	var paths := {
		"ambient": "res://assets/audio/music/ambient_office.wav",
		"chill": "res://assets/audio/music/chill_investigation.wav",
		"tense": "res://assets/audio/music/tense_deadline.wav",
		"menu": "res://assets/audio/music/menu_theme.wav",
	}
	var path: String = paths.get(track_name, "")
	if path != "" and ResourceLoader.exists(path):
		AudioManager.play_music(load(path))


func play_music_ambient() -> void:
	play_music("chill")
