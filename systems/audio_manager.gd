extends Node
## Bus layout, layered music, SFX pools, ducking and reverb buses.
##
## Bus graph:  Master <- Music, Voice, SFX <- (Ambience, RevSmall, RevLarge, RevOutdoor), UI
## Music layers are AudioStreamSynchronized stems so accident chains can add
## rhythmic elements while staying sample-locked.

const SFX_DIR := "res://audio/sfx/"
const MUSIC_DIR := "res://audio/music/"
const POOL_3D := 28
const POOL_2D := 12

var _sfx_paths: Dictionary = {}   # base name -> Array[String]
var _sfx_cache: Dictionary = {}   # path -> AudioStream
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _pool_2d: Array[AudioStreamPlayer] = []
var _pool_index_3d := 0
var _pool_index_2d := 0

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_active: AudioStreamPlayer
var _music_id: StringName = &""
var _layer_count := 0
var _layer_tween: Tween
var _duck_fx_idx := -1
var _music_lp_idx := -1
var _sfx_lp_idx := -1
var _duck_tween: Tween
var _duck_requests := 0
var _stinger_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _ambience_id: StringName = &""
var _rng := RandomNumberGenerator.new()

var last_played: Array[String] = []  # debug: recent sfx names


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_build_buses()
	_scan_sfx()
	for i in POOL_3D:
		var p := AudioStreamPlayer3D.new()
		p.bus = &"SFX"
		p.max_distance = 60.0
		p.unit_size = 6.0
		p.attenuation_filter_cutoff_hz = 12000.0
		add_child(p)
		_pool_3d.append(p)
	for i in POOL_2D:
		var p2 := AudioStreamPlayer.new()
		p2.bus = &"SFX"
		add_child(p2)
		_pool_2d.append(p2)
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	for m in [_music_a, _music_b]:
		m.bus = &"Music"
		add_child(m)
	_music_active = _music_a
	_stinger_player = AudioStreamPlayer.new()
	_stinger_player.bus = &"Music"
	add_child(_stinger_player)
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = &"Ambience"
	add_child(_ambience_player)


# --------------------------------------------------------------------------
# buses
# --------------------------------------------------------------------------
func _build_buses() -> void:
	while AudioServer.bus_count > 1:
		AudioServer.remove_bus(AudioServer.bus_count - 1)
	_add_bus(&"Music", &"Master")
	_add_bus(&"Voice", &"Master")
	_add_bus(&"SFX", &"Master")
	_add_bus(&"Ambience", &"SFX")
	_add_bus(&"UI", &"Master")
	for rb in [[&"RevSmall", 0.35, 0.6, 0.25], [&"RevLarge", 0.85, 0.85, 0.35], [&"RevOutdoor", 0.6, 0.4, 0.18]]:
		var idx := _add_bus(rb[0], &"SFX")
		var rv := AudioEffectReverb.new()
		rv.room_size = rb[1]
		rv.damping = rb[2]
		rv.wet = rb[3]
		rv.dry = 0.0
		rv.spread = 1.0
		AudioServer.add_bus_effect(idx, rv)
	# Music: amplify (used for ducking) + lowpass (used for muffling).
	var mi := AudioServer.get_bus_index(&"Music")
	AudioServer.add_bus_effect(mi, AudioEffectAmplify.new())
	_duck_fx_idx = 0
	var mlp := AudioEffectLowPassFilter.new()
	mlp.cutoff_hz = 20500.0
	AudioServer.add_bus_effect(mi, mlp)
	_music_lp_idx = 1
	var si := AudioServer.get_bus_index(&"SFX")
	var slp := AudioEffectLowPassFilter.new()
	slp.cutoff_hz = 20500.0
	AudioServer.add_bus_effect(si, slp)
	_sfx_lp_idx = 0
	var lim := AudioEffectLimiter.new()
	lim.ceiling_db = -1.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index(&"Master"), lim)


func _add_bus(bus_name: StringName, send: StringName) -> int:
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, send)
	return idx


func set_bus_linear(bus_name: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)) if linear > 0.001 else -80.0)
	AudioServer.set_bus_mute(idx, linear <= 0.001)


## Muffle everything except voices (premonitions, explosions nearby).
func set_muffled(amount: float, seconds: float = 0.15) -> void:
	var cutoff := lerpf(20500.0, 700.0, clampf(amount, 0.0, 1.0))
	var t := create_tween().set_parallel(true)
	var mi := AudioServer.get_bus_index(&"Music")
	var si := AudioServer.get_bus_index(&"SFX")
	var mfx := AudioServer.get_bus_effect(mi, _music_lp_idx) as AudioEffectLowPassFilter
	var sfx := AudioServer.get_bus_effect(si, _sfx_lp_idx) as AudioEffectLowPassFilter
	t.tween_property(mfx, "cutoff_hz", cutoff, seconds)
	t.tween_property(sfx, "cutoff_hz", cutoff, seconds)


# --------------------------------------------------------------------------
# sfx
# --------------------------------------------------------------------------
func _scan_sfx() -> void:
	_sfx_paths.clear()
	var da := DirAccess.open(SFX_DIR)
	if da == null:
		return
	for f in da.get_files():
		var fn := f.trim_suffix(".import")
		if not (fn.ends_with(".ogg") or fn.ends_with(".wav")):
			continue
		var base := fn.get_basename()
		var rx := RegEx.create_from_string("_\\d\\d$")
		var m := rx.search(base)
		if m:
			base = base.substr(0, m.get_start())
		var arr: Array = _sfx_paths.get(base, [])
		var path := SFX_DIR + fn
		if not arr.has(path):
			arr.append(path)
		_sfx_paths[base] = arr


func has_sfx(sfx_name: StringName) -> bool:
	return _sfx_paths.has(String(sfx_name))


func get_sfx_stream(sfx_name: StringName) -> AudioStream:
	var arr: Array = _sfx_paths.get(String(sfx_name), [])
	if arr.is_empty():
		return null
	var path: String = arr[_rng.randi() % arr.size()]
	if not _sfx_cache.has(path):
		_sfx_cache[path] = load(path)
	return _sfx_cache[path]


func preload_sfx(names: Array) -> void:
	for n in names:
		for p in _sfx_paths.get(String(n), []):
			if not _sfx_cache.has(p):
				_sfx_cache[p] = load(p)


func play_sfx(sfx_name: StringName, pos: Variant = null, volume_db: float = 0.0, pitch: float = 1.0, bus: StringName = &"SFX") -> AudioStreamPlayer3D:
	var stream := get_sfx_stream(sfx_name)
	if stream == null:
		return null
	last_played.append(String(sfx_name))
	if last_played.size() > 12:
		last_played.pop_front()
	if pos == null:
		play_ui(sfx_name, volume_db, pitch)
		return null
	var p := _pool_3d[_pool_index_3d]
	_pool_index_3d = (_pool_index_3d + 1) % POOL_3D
	p.stop()
	p.stream = stream
	p.bus = bus
	p.volume_db = volume_db
	p.pitch_scale = pitch * _rng.randf_range(0.97, 1.03)
	p.global_position = pos
	p.play()
	return p


func play_ui(sfx_name: StringName, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream := get_sfx_stream(sfx_name)
	if stream == null:
		return
	var p := _pool_2d[_pool_index_2d]
	_pool_index_2d = (_pool_index_2d + 1) % POOL_2D
	p.stop()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


## Attach a looping sound to a node (machinery, alarms). Returns the player so
## the caller can free it; it frees itself when its parent leaves the tree.
func attach_loop(sfx_name: StringName, parent: Node3D, volume_db: float = 0.0, max_dist: float = 30.0) -> AudioStreamPlayer3D:
	var stream := get_sfx_stream(sfx_name)
	if stream == null or parent == null:
		return null
	var p := AudioStreamPlayer3D.new()
	var s: AudioStream = stream.duplicate()
	if s is AudioStreamOggVorbis:
		s.loop = true
	elif s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = s.data.size() / 2
	p.stream = s
	p.bus = &"SFX"
	p.volume_db = volume_db
	p.max_distance = max_dist
	p.unit_size = 5.0
	parent.add_child(p)
	p.play()
	return p


func play_ambience(amb_id: StringName, volume_db: float = -6.0) -> void:
	if amb_id == _ambience_id:
		return
	_ambience_id = amb_id
	var stream := get_sfx_stream(amb_id)
	if stream == null:
		_ambience_player.stop()
		return
	var s: AudioStream = stream.duplicate()
	if s is AudioStreamOggVorbis:
		s.loop = true
	_ambience_player.stream = s
	_ambience_player.volume_db = volume_db
	_ambience_player.play()


# --------------------------------------------------------------------------
# music
# --------------------------------------------------------------------------
func _load_music(track_id: StringName) -> AudioStream:
	var p := "%s%s.ogg" % [MUSIC_DIR, track_id]
	if ResourceLoader.exists(p):
		var s: AudioStream = load(p)
		return s
	return null


func play_music(track_id: StringName, fade: float = 1.5, volume_db: float = 0.0, loop: bool = true) -> void:
	if track_id == _music_id and _music_active.playing:
		return
	_music_id = track_id
	var s := _load_music(track_id)
	var prev := _music_active
	var next := _music_b if prev == _music_a else _music_a
	if prev.playing:
		var tw := create_tween()
		tw.tween_property(prev, "volume_db", -60.0, fade)
		tw.tween_callback(prev.stop)
	if s == null:
		return
	var st: AudioStream = s.duplicate()
	if st is AudioStreamOggVorbis:
		st.loop = loop
	next.stream = st
	next.volume_db = -60.0
	next.play()
	create_tween().tween_property(next, "volume_db", volume_db, fade)
	_music_active = next


## Layered stems: track ids "<id>__<stem>" are combined into one synchronized
## stream. Layers 0..n-1 are audible by default according to `active_layers`.
func play_layered(group_id: StringName, stems: Array, active_layers: int = 1, fade: float = 1.0) -> void:
	var sync := AudioStreamSynchronized.new()
	var loaded := 0
	sync.stream_count = stems.size()
	for i in stems.size():
		var p := "%s%s__%s.ogg" % [MUSIC_DIR, group_id, stems[i]]
		if ResourceLoader.exists(p):
			var st: AudioStream = (load(p) as AudioStream).duplicate()
			if st is AudioStreamOggVorbis:
				st.loop = true
			sync.set_sync_stream(i, st)
			loaded += 1
	if loaded == 0:
		return
	_music_id = StringName("layers:" + String(group_id))
	var prev := _music_active
	var next := _music_b if prev == _music_a else _music_a
	if prev.playing:
		var tw := create_tween()
		tw.tween_property(prev, "volume_db", -60.0, fade)
		tw.tween_callback(prev.stop)
	next.stream = sync
	next.volume_db = -60.0
	for i in stems.size():
		sync.set_sync_stream_volume(i, 0.0 if i < active_layers else -60.0)
	_layer_count = stems.size()
	next.play()
	create_tween().tween_property(next, "volume_db", 0.0, fade)
	_music_active = next


func set_layers(active_layers: int, fade: float = 0.6) -> void:
	var sync := _music_active.stream as AudioStreamSynchronized
	if sync == null:
		return
	if _layer_tween and _layer_tween.is_valid():
		_layer_tween.kill()
	_layer_tween = create_tween().set_parallel(true)
	for i in sync.stream_count:
		var target := 0.0 if i < active_layers else -60.0
		var from := sync.get_sync_stream_volume(i)
		_layer_tween.tween_method(func(v: float) -> void: sync.set_sync_stream_volume(i, v), from, target, fade)


func stop_music(fade: float = 1.0) -> void:
	_music_id = &""
	for m in [_music_a, _music_b]:
		if m.playing:
			var tw := create_tween()
			tw.tween_property(m, "volume_db", -60.0, fade)
			tw.tween_callback(m.stop)


func current_music() -> StringName:
	return _music_id


## One-shot music sting layered over whatever is playing.
func stinger(track_id: StringName, volume_db: float = 0.0) -> void:
	var s := _load_music(track_id)
	if s == null:
		return
	_stinger_player.stream = s
	_stinger_player.volume_db = volume_db
	_stinger_player.play()


# --------------------------------------------------------------------------
# ducking (reference-counted so overlapping lines do not fight)
# --------------------------------------------------------------------------
func duck_begin() -> void:
	_duck_requests += 1
	_set_duck(-9.0, 0.25)


func duck_end() -> void:
	_duck_requests = maxi(_duck_requests - 1, 0)
	if _duck_requests == 0:
		_set_duck(0.0, 0.8)


func _set_duck(db: float, seconds: float) -> void:
	var mi := AudioServer.get_bus_index(&"Music")
	var fx := AudioServer.get_bus_effect(mi, _duck_fx_idx) as AudioEffectAmplify
	if fx == null:
		return
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(fx, "volume_db", db, seconds)
