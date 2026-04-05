extends Node
## Manages music and SFX playback. Supports crossfading between music tracks.

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var crossfade_player: AudioStreamPlayer

var _crossfade_tween: Tween
var music_volume_db: float = 0.0
var sfx_volume_db: float = 0.0


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Master"
	add_child(music_player)

	crossfade_player = AudioStreamPlayer.new()
	crossfade_player.bus = &"Master"
	add_child(crossfade_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = &"Master"
	add_child(sfx_player)


func play_music(stream: AudioStream, crossfade_duration: float = 1.0) -> void:
	if music_player.stream == stream and music_player.playing:
		return

	if music_player.playing and crossfade_duration > 0.0:
		# Crossfade: move current track to crossfade_player, fade it out
		crossfade_player.stream = music_player.stream
		crossfade_player.play(music_player.get_playback_position())
		crossfade_player.volume_db = music_volume_db

		music_player.stream = stream
		music_player.volume_db = -40.0
		music_player.play()

		if _crossfade_tween:
			_crossfade_tween.kill()
		_crossfade_tween = create_tween().set_parallel(true)
		_crossfade_tween.tween_property(music_player, "volume_db", music_volume_db, crossfade_duration)
		_crossfade_tween.tween_property(crossfade_player, "volume_db", -40.0, crossfade_duration)
		_crossfade_tween.chain().tween_callback(crossfade_player.stop)
	else:
		music_player.stream = stream
		music_player.volume_db = music_volume_db
		music_player.play()


func stop_music(fade_duration: float = 0.5) -> void:
	if fade_duration > 0.0 and music_player.playing:
		var tween := create_tween()
		tween.tween_property(music_player, "volume_db", -40.0, fade_duration)
		tween.tween_callback(music_player.stop)
	else:
		music_player.stop()


func play_sfx(stream: AudioStream) -> void:
	sfx_player.stream = stream
	sfx_player.volume_db = sfx_volume_db
	sfx_player.play()


## Play a one-shot SFX without interrupting the current SFX.
func play_sfx_oneshot(stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	player.bus = &"Master"
	player.stream = stream
	player.volume_db = sfx_volume_db
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func set_music_volume(volume_linear: float) -> void:
	music_volume_db = linear_to_db(clampf(volume_linear, 0.0, 1.0))
	music_player.volume_db = music_volume_db


func set_sfx_volume(volume_linear: float) -> void:
	sfx_volume_db = linear_to_db(clampf(volume_linear, 0.0, 1.0))
	sfx_player.volume_db = sfx_volume_db
