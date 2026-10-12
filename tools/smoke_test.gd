extends Node
## Teste de fumaça automatizado. Executar com:
##   godot --path . -- --smoke-test            (sessão completa, ~2 min)
##   godot --path . -- --smoke-test --quick    (só capturas iniciais)
## Percorre menu -> partida com piloto automático (Tubo, Aéreo, vitória) -> queda (Game Over) -> pausa,
## e salva capturas de tela em user://smoke/.

var out := ""
var quick := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	quick = "--quick" in OS.get_cmdline_user_args()
	out = ProjectSettings.globalize_path("user://smoke")
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func _g():
	var s := get_tree().current_scene
	if s and "autopilot" in s:
		return s
	return null


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout


func _until(cond: Callable, timeout: float) -> bool:
	var t0 := Time.get_ticks_msec()
	while not cond.call():
		if Time.get_ticks_msec() - t0 > timeout * 1000.0:
			print("[smoke] TIMEOUT esperando condição")
			return false
		await get_tree().process_frame
	return true


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out.path_join(shot_name + ".png"))
	print("[smoke] captura: ", shot_name)


func _state() -> String:
	var g = _g()
	return g.state_name() if g else "NONE"


func _run() -> void:
	await _wait(1.5)
	await _shot("01_menu")

	Game.goto("customize")
	await _wait(1.0)
	await _shot("01a_customize")
	var saved_look := Game.look.duplicate()
	Game.set_look({"skin": 4, "hair_style": 3, "hair_color": 5, "beard": 2, "top": 1, "shorts": 8, "board": 4})
	get_tree().current_scene._apply()
	get_tree().current_scene._build_rows()
	await _wait(0.4)
	await _shot("01a_customize2")
	Game.set_look({"skin": 0, "hair_style": 1, "hair_color": 2, "beard": 0, "top": 6, "shorts": 2, "board": 1})
	get_tree().current_scene._apply()
	get_tree().current_scene._build_rows()
	await _wait(0.4)
	await _shot("01a_customize3")
	Game.set_look(saved_look)

	Game.goto("intro")
	await _wait(1.6)
	await _shot("01b_intro")
	await _wait(2.0)
	await _shot("01c_intro")

	Game.goto("game")
	await _wait(1.0)
	await _shot("02_ready")
	_g().autopilot = true
	await _until(func(): return _g() != null and _g().tubes >= 1 and _g().world.wave.tube_k > 0.95, 40.0)
	await _shot("03_tube")
	await _until(func(): return _g() != null and _g().aerials >= 1, 40.0)
	await _wait(0.12)
	await _shot("04_aerial")
	# vitrine dos animais
	var gs = _g()
	if gs:
		for spec in [["tartaruga", 640.0], ["tubarao", 800.0], ["golfinho", 960.0], ["baleia", 1160.0]]:
			var a = load("res://scenes/animal.tscn").instantiate()
			a.setup(spec[0], gs.rng)
			a.position = Vector2(spec[1], 560.0)
			a.passed = true
			gs.world.people.add_child(a)
		await _wait(0.1)
		await _shot("04b_animals")
		_g().hud.toast("NÍVEL 4", "TUBARÃO! ele nada mais rápido")
		await _wait(0.5)
		await _shot("04c_toast")
	if quick:
		_g()._set_paused(true)
		await _wait(0.4)
		await _shot("10_pause")
		_g()._set_paused(false)
		Sfx.toggle_mute()
		await _wait(0.3)
		await _shot("11_muted")
		Sfx.toggle_mute()
		get_tree().quit()
		return

	Engine.time_scale = 4.0
	await _until(func(): return _g() == null or _g().elapsed > 95.0 or _state() != "PLAYING", 60.0)
	await _shot("05_mid")
	await _until(func(): return _g() == null or _g().elapsed > 168.0 or _state() != "PLAYING", 60.0)
	Engine.time_scale = 1.0
	await _shot("06_late")
	await _until(func(): return _state() == "RESULT", 30.0)
	await _wait(1.0)
	await _shot("07_result")
	var g = _g()
	if g:
		print("[smoke] sessão 1: won=%s score=%d pessoas=%d tubos=%d aereos=%d t=%.1f" % [g.won, g.score, g.people_passed, g.tubes, g.aerials, g.elapsed])

	Game.goto("game")
	await _wait(1.0)
	await _until(func(): return _state() == "CRASHING", 30.0)
	await _wait(0.3)
	await _shot("08_crash")
	await _until(func(): return _state() == "RESULT", 10.0)
	await _wait(1.0)
	await _shot("09_gameover")
	if _g():
		print("[smoke] sessão 2: colidiu com ", _g().crash_name)

	Game.goto("game")
	await _wait(2.6)
	if _g():
		_g()._set_paused(true)
		await _wait(0.4)
		await _shot("10_pause")
		_g()._set_paused(false)
	print("[smoke] FIM")
	get_tree().quit()
