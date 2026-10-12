extends Node
## Autoload "Sfx": áudio 100% procedural (sem arquivos externos).
## Efeitos sonoros curtos + música de fundo em loop + som ambiente do mar.
## A música e o mar são gerados numa thread para não travar a abertura do jogo.

const RATE := 22050
const LOOP_RATE := 16000

signal mute_changed(muted: bool)

var muted := false

var _sounds := {}
var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _ocean: AudioStreamPlayer
var _thread: Thread
var _buf := PackedFloat32Array()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	muted = Game.start_muted
	AudioServer.set_bus_mute(0, muted)
	_sounds["click"] = _make(_tones([880.0], 0.045, 0.2), RATE)
	_sounds["jump"] = _make(_sweep(260.0, 640.0, 0.15, 0.22), RATE)
	_sounds["pass"] = _make(_tones([1046.5, 1318.5], 0.055, 0.17), RATE)
	_sounds["tube"] = _make(_add(_noise(0.9, 0.32, 0.08, true), _tones([523.25, 659.25, 783.99, 1046.5], 0.09, 0.14)), RATE)
	_sounds["aerial"] = _make(_add(_sweep(400.0, 1200.0, 0.3, 0.12), _tones([783.99, 987.77, 1174.66, 1567.98], 0.07, 0.2)), RATE)
	_sounds["crash"] = _make(_add(_noise(0.8, 0.55, 0.25, false), _sweep(220.0, 55.0, 0.35, 0.35)), RATE)
	_sounds["win"] = _make(_tones([523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5, 1318.5], 0.12, 0.24), RATE)
	_sounds["lose"] = _make(_tones([440.0, 369.99, 311.13, 261.63], 0.17, 0.22), RATE)
	_sounds["level"] = _make(_tones([587.33, 880.0, 1174.66], 0.09, 0.2), RATE)
	_sounds["shark"] = _make(_tones([164.81, 174.61, 164.81, 174.61], 0.2, 0.32), RATE)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -11.0
	add_child(_music)
	_ocean = AudioStreamPlayer.new()
	_ocean.volume_db = -15.0
	add_child(_ocean)
	_thread = Thread.new()
	_thread.start(_generate_loops)


func play(sound: String, volume_db: float = 0.0) -> void:
	if not _sounds.has(sound):
		return
	for p in _pool:
		if not p.playing:
			p.stream = _sounds[sound]
			p.volume_db = volume_db
			p.play()
			return


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		toggle_mute()


## Liga/desliga todo o som do jogo (tecla M ou botão de som). A escolha fica salva.
func toggle_mute() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	mute_changed.emit(muted)
	Game.save_settings()


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


# --- Geração dos loops (roda na thread) ---

func _generate_loops() -> void:
	call_deferred("_add_sound", "fanfare", _make(_fanfare(), RATE))
	var ocean := _ocean_loop()
	var music := _music_loop()
	call_deferred("_on_loops_ready", ocean, music)


func _add_sound(sound: String, stream: AudioStreamWAV) -> void:
	_sounds[sound] = stream


## Fanfarra de cornetas para a abertura: "ta-ta-ta-TAAA ... ta-TAAAA" em Dó maior.
## Cada nota é [frequência, início, duração, volume]; o timbre de metal vem dos harmônicos.
func _fanfare() -> PackedFloat32Array:
	var notes := [
		# corneta 1 (melodia)
		[392.0, 0.00, 0.12, 0.30], [392.0, 0.14, 0.12, 0.30], [392.0, 0.28, 0.12, 0.30],
		[523.25, 0.42, 0.50, 0.32], [392.0, 0.96, 0.14, 0.30], [523.25, 1.12, 0.95, 0.34],
		# corneta 2 (terça abaixo)
		[329.63, 0.00, 0.12, 0.22], [329.63, 0.14, 0.12, 0.22], [329.63, 0.28, 0.12, 0.22],
		[392.0, 0.42, 0.50, 0.24], [329.63, 0.96, 0.14, 0.22], [392.0, 1.12, 0.95, 0.26],
		# brilho no acorde final e trombone no grave
		[659.25, 1.12, 0.95, 0.16],
		[130.81, 0.42, 0.50, 0.26], [98.0, 0.96, 0.14, 0.24], [130.81, 1.12, 0.95, 0.28],
	]
	var total := 0.0
	for nt in notes:
		total = maxf(total, float(nt[1]) + float(nt[2]) + 0.05)
	var out := PackedFloat32Array()
	out.resize(int(total * RATE))
	for nt in notes:
		var f: float = nt[0]
		var start := int(float(nt[1]) * RATE)
		var n := int(float(nt[2]) * RATE)
		var vol: float = nt[3]
		var phase := 0.0
		for i in n:
			var tt := float(i) / RATE
			var att := minf(1.0, tt / 0.035)
			var rel := minf(1.0, float(n - i) / (0.06 * RATE))
			var vib := 1.0 + 0.005 * sin(TAU * 5.5 * tt) * minf(1.0, tt / 0.25)
			phase += TAU * f * vib / RATE
			var bright := 0.5 + 0.4 * att
			var v := sin(phase) + bright * sin(phase * 2.0) / 2.0 + bright * bright * sin(phase * 3.0) / 3.0 + pow(bright, 3.0) * sin(phase * 4.0) / 4.0
			out[start + i] += v * att * rel * vol
	var peak := 0.0001
	for v in out:
		peak = maxf(peak, absf(v))
	for i in out.size():
		out[i] *= 0.75 / peak
	return out


func _on_loops_ready(ocean: AudioStreamWAV, music: AudioStreamWAV) -> void:
	_thread.wait_to_finish()
	_ocean.stream = ocean
	_ocean.play()
	_music.stream = music
	_music.play()


## Surf-pop simples em Lá maior: A - F#m - D - E (2 compassos cada), baixo, arpejo, melodia e bateria.
func _music_loop() -> AudioStreamWAV:
	var beat := 60.0 / 116.0
	var bars := 8
	_buf = PackedFloat32Array()
	_buf.resize(int(bars * 4 * beat * LOOP_RATE))
	var roots := [110.0, 92.5, 73.42, 82.41]
	var chords := [[0, 4, 7], [0, 3, 7], [0, 4, 7], [0, 4, 7]]
	var arp := [0, 1, 2, 1, 0, 1, 2, 3]
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for bar in bars:
		var ci := int(bar / 2.0)
		var root: float = roots[ci]
		var chord: Array = chords[ci]
		for e in 8:
			var t0 := (bar * 4 + e * 0.5) * beat
			var bass_f := root * (2.0 if e % 4 == 2 else 1.0)
			_bass(t0, beat * 0.45, bass_f, 0.2)
			var step_i: int = arp[e]
			var semis: int = 12 if step_i == 3 else int(chord[step_i])
			_pluck(t0, beat * 0.45, root * 4.0 * pow(2.0, semis / 12.0), 0.06)
		for b in 4:
			var tb := (bar * 4 + b) * beat
			if b % 2 == 0:
				_kick(tb, 0.55)
			else:
				_snare(tb, 0.2, rng)
			_hat(tb, 0.03, rng)
			_hat(tb + beat * 0.5, 0.05, rng)
	# melodia nos compassos 5 a 8 (MIDI)
	var melody := [76, 78, 81, 78, 76, 73, 71, 73, 74, 73, 71, 69, 71, 73, 76, 76]
	for i in melody.size():
		var m: int = melody[i]
		_pluck((16 + i) * beat, beat * 0.9, 440.0 * pow(2.0, (m - 69) / 12.0), 0.07)
	_normalize(0.8)
	return _make(_buf, LOOP_RATE, true)


func _bass(t0: float, dur: float, freq: float, vol: float) -> void:
	var n := int(dur * LOOP_RATE)
	var start := int(t0 * LOOP_RATE)
	var total := _buf.size()
	for i in n:
		var tt := float(i) / LOOP_RATE
		var env := minf(1.0, i / 80.0) * (1.0 - float(i) / n)
		var tri := 2.0 * absf(2.0 * fposmod(freq * tt, 1.0) - 1.0) - 1.0
		_buf[(start + i) % total] += tri * env * vol


func _pluck(t0: float, dur: float, freq: float, vol: float) -> void:
	var n := int(dur * LOOP_RATE)
	var start := int(t0 * LOOP_RATE)
	var total := _buf.size()
	for i in n:
		var tt := float(i) / LOOP_RATE
		var env := minf(1.0, i / 40.0) * exp(-tt * 7.0)
		var v := sin(TAU * freq * tt) + 0.3 * sin(TAU * freq * 2.0 * tt)
		_buf[(start + i) % total] += v * env * vol


func _kick(t0: float, vol: float) -> void:
	var n := int(0.2 * LOOP_RATE)
	var start := int(t0 * LOOP_RATE)
	var total := _buf.size()
	var phase := 0.0
	for i in n:
		var tt := float(i) / LOOP_RATE
		var f := 45.0 + 85.0 * exp(-tt * 25.0)
		phase += TAU * f / LOOP_RATE
		_buf[(start + i) % total] += sin(phase) * exp(-tt * 16.0) * vol


func _snare(t0: float, vol: float, rng: RandomNumberGenerator) -> void:
	var n := int(0.16 * LOOP_RATE)
	var start := int(t0 * LOOP_RATE)
	var total := _buf.size()
	for i in n:
		var tt := float(i) / LOOP_RATE
		var v := rng.randf_range(-1.0, 1.0) * exp(-tt * 24.0) + 0.4 * sin(TAU * 190.0 * tt) * exp(-tt * 30.0)
		_buf[(start + i) % total] += v * vol


func _hat(t0: float, vol: float, rng: RandomNumberGenerator) -> void:
	var n := int(0.05 * LOOP_RATE)
	var start := int(t0 * LOOP_RATE)
	var total := _buf.size()
	var prev := 0.0
	for i in n:
		var tt := float(i) / LOOP_RATE
		var w := rng.randf_range(-1.0, 1.0)
		_buf[(start + i) % total] += (w - prev) * exp(-tt * 90.0) * vol
		prev = w


func _normalize(target: float) -> void:
	var peak := 0.0001
	for v in _buf:
		peak = maxf(peak, absf(v))
	var gain := target / peak
	for i in _buf.size():
		_buf[i] *= gain


## Mar: ruído grave filtrado com "respiração" de ondas; emenda suave para o loop não estalar.
func _ocean_loop() -> AudioStreamWAV:
	var n := 6 * LOOP_RATE
	var fade := int(LOOP_RATE * 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var raw := PackedFloat32Array()
	raw.resize(n + fade)
	var lp := 0.0
	var lp2 := 0.0
	for i in n + fade:
		var tt := float(i) / LOOP_RATE
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.06
		lp2 += (lp - lp2) * 0.15
		var swell := 0.35 + 0.65 * pow(sin(PI * tt / 3.0), 2.0)
		raw[i] = lp2 * swell * 2.2
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = raw[i]
	for i in fade:
		var k := float(i) / fade
		out[i] = raw[i] * k + raw[n + i] * (1.0 - k)
	return _make(out, LOOP_RATE, true)


# --- Síntese dos efeitos curtos ---

func _tones(freqs: Array, note_len: float, vol: float) -> PackedFloat32Array:
	var n := int(note_len * RATE)
	var out := PackedFloat32Array()
	out.resize(n * freqs.size())
	for j in freqs.size():
		var f: float = freqs[j]
		for i in n:
			var tt := float(i) / RATE
			var env := minf(1.0, i / 60.0) * pow(1.0 - float(i) / n, 1.5)
			var v := sin(TAU * f * tt) + 0.25 * sin(TAU * f * 3.0 * tt)
			out[j * n + i] = v * env * vol
	return out


func _sweep(f0: float, f1: float, dur: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var k := float(i) / n
		phase += TAU * lerpf(f0, f1, k) / RATE
		out[i] = sin(phase) * minf(1.0, i / 60.0) * (1.0 - k) * vol
	return out


func _noise(dur: float, vol: float, smooth: float, swell: bool) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = n
	for i in n:
		var k := float(i) / n
		lp += (rng.randf_range(-1.0, 1.0) - lp) * smooth
		var env := sin(PI * k) if swell else exp(-k * 5.0)
		out[i] = lp * env * vol * (3.0 if smooth < 0.15 else 1.6)
	return out


func _add(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var out := a.duplicate()
	if b.size() > out.size():
		out.resize(b.size())
	for i in b.size():
		out[i] += b[i]
	return out


func _make(samples: PackedFloat32Array, rate: int, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = false
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = samples.size()
	return s
