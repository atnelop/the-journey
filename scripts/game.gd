extends Node2D
## Sessão de surfe — loop principal do GDD v1.2:
## pessoas e animais surgem na água, o jogador salta com ESPAÇO, cada obstáculo superado vale pontos e combo.
## Combo 3 ativa o TUBO (+300); combo 5 ativa o AÉREO (+500) e reinicia o combo.
## A cada 20 s sobe um nível: os obstáculos aparecem mais rápido e novos animais entram na água.
## Colidir encerra a partida (Game Over); sobreviver até o fim da onda conclui a sessão (vitória).

const WorldScript = preload("res://scripts/world/world.gd")
const SurferScript = preload("res://scripts/world/surfer.gd")
const PersonScene = preload("res://scenes/person.tscn")
const AnimalScene = preload("res://scenes/animal.tscn")
const AnimalScript = preload("res://scripts/world/animal.gd")
const HudScript = preload("res://scripts/ui/hud.gd")
const PauseMenu = preload("res://scripts/ui/pause_menu.gd")
const UiKit = preload("res://scripts/ui_kit.gd")

# Valores de balanceamento (GDD 5.3) — podem ser ajustados sem mudar a estrutura.
const SESSION_TIME := 180.0
const READY_TIME := 1.8
const POINTS_PERSON := 100
const BONUS_TUBE := 300
const BONUS_AERIAL := 500
const COMBO_TUBE := 3
const COMBO_AERIAL := 5
const SPEED_START := 320.0
const SPEED_END := 540.0
const SPAWN_X := 1400.0
const TUBE_SHOW_TIME := 2.6
const STOP_SPAWN_BEFORE_END := 3.5
# Dificuldade por nível
const LEVEL_TIME := 20.0          # sobe um nível a cada 20 s
const INTERVAL_START := 2.4       # segundos entre obstáculos no nível 1
const INTERVAL_FACTOR := 0.9      # cada nível multiplica o intervalo por este fator
const INTERVAL_MIN := 1.0
const REACTION_TIME := 0.5        # folga mínima entre pousar e precisar saltar de novo
const WIDTH_GAP := 0.4            # folga extra proporcional à largura dos obstáculos
## Novidades de cada nível: [obstáculos que entram no sorteio, mensagem]
const LEVEL_UNLOCKS := [
	[["banhista", "banhista", "crianca"], "a onda está chegando"],
	[["bodyboard", "tartaruga", "tartaruga"], "tartarugas na água!"],
	[["remando", "golfinho", "golfinho"], "golfinhos saltando!"],
	[["casal", "tubarao", "tubarao"], "TUBARÃO! ele nada mais rápido"],
	[["sup", "golfinho"], "stand-up paddles na área"],
	[["baleia", "tubarao"], "baleia à vista!"],
	[["baleia", "sup", "tubarao"], "a água está lotada"],
]

enum State { READY, PLAYING, CRASHING, FINISHING, RESULT }

var autopilot := false   # usado só pelo teste automático
var state := State.READY
var world
var hud
var pause_menu
var ui_layer: CanvasLayer
var rng := RandomNumberGenerator.new()

var elapsed := 0.0
var state_t := 0.0
var score := 0
var combo := 0
var people_passed := 0
var tubes := 0
var aerials := 0
var next_spawn := 2.4
var level := 0
var tube_timer := 0.0
var _pool: Array = []
var _pending = null          # próximo obstáculo, esperando o momento justo de entrar
var _last_arrival := -10.0   # instante em que o último obstáculo chega ao surfista
var _last_w := 0.0
var crash_name := ""
var won := false
var new_record := false


func _ready() -> void:
	rng.randomize()
	world = WorldScript.new()
	add_child(world)
	world.speed = SPEED_START
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	hud = HudScript.new()
	ui_layer.add_child(hud)
	hud.best = Game.best_score
	hud.duration = SESSION_TIME
	hud.time_left = SESSION_TIME
	pause_menu = PauseMenu.new()
	ui_layer.add_child(pause_menu)
	pause_menu.resumed.connect(func(): _set_paused(false))
	pause_menu.restart_requested.connect(func(): Game.goto("game"))
	pause_menu.menu_requested.connect(func(): Game.goto("menu"))
	_pool = LEVEL_UNLOCKS[0][0].duplicate()
	hud.banner("PREPARE-SE", "a onda está chegando", READY_TIME, UiKit.SAND)
	hud.hint("Aperte ESPAÇO para saltar sobre as pessoas e os animais", 6.5)


func state_name() -> String:
	return State.keys()[state]


func _process(delta: float) -> void:
	state_t += delta
	if (state == State.READY or state == State.PLAYING) and Input.is_action_just_pressed("pause"):
		_set_paused(true)
		return
	match state:
		State.READY:
			if Input.is_action_just_pressed("jump"):
				world.surfer.request_jump()
			world.advance(delta)
			if state_t >= READY_TIME:
				_change(State.PLAYING)
				hud.banner("SURFE!", "", 0.8, UiKit.SUN)
		State.PLAYING:
			_play(delta)
		State.CRASHING:
			world.speed = move_toward(world.speed, 0.0, 600.0 * delta)
			world.advance(delta)
			if state_t >= 1.5:
				_show_result()
		State.FINISHING:
			world.speed = move_toward(world.speed, 160.0, 220.0 * delta)
			world.advance(delta)
			if state_t >= 2.2:
				_show_result()
		State.RESULT:
			world.advance(delta)
	hud.score = score
	hud.combo = combo
	hud.time_left = maxf(SESSION_TIME - elapsed, 0.0)


func _play(delta: float) -> void:
	elapsed += delta
	var k := clampf(elapsed / SESSION_TIME, 0.0, 1.0)
	world.speed = lerpf(SPEED_START, SPEED_END, k)   # aumento gradual de velocidade
	world.progress = k                                # o dia vira pôr do sol ao longo da onda
	if autopilot:
		_autopilot()
	elif Input.is_action_just_pressed("jump"):
		world.surfer.request_jump()
	world.advance(delta)
	var lvl := mini(int(elapsed / LEVEL_TIME), int(SESSION_TIME / LEVEL_TIME) - 1)
	if lvl > level:
		_level_up(lvl)
	if elapsed < SESSION_TIME - STOP_SPAWN_BEFORE_END:
		next_spawn -= delta
		# se não for justo soltar agora, tenta de novo no próximo quadro
		if next_spawn <= 0.0 and _try_spawn():
			next_spawn = _interval()
	if tube_timer > 0.0:
		tube_timer -= delta
		if tube_timer <= 0.0:
			world.set_tube(false)
	_check_people()
	if state == State.PLAYING and elapsed >= SESSION_TIME:
		_finish()


# --- Geração de obstáculos ---

## Solta o próximo obstáculo só se ele chegar ao surfista com tempo de pousar do salto anterior
## e saltar de novo. Como o tubarão e os golfinhos nadam mais rápido, a conta usa o instante de chegada.
func _try_spawn() -> bool:
	if _pending == null:
		var kind: String = _pool[rng.randi_range(0, _pool.size() - 1)]
		_pending = (AnimalScene if AnimalScript.TYPES.has(kind) else PersonScene).instantiate()
		_pending.setup(kind, rng)
	var spd: float = world.speed
	var obs_speed: float = spd + _pending.extra_speed
	var arrival := elapsed + (SPAWN_X - SurferScript.BASE_X) / obs_speed
	var w: float = _pending.w
	var need := SurferScript.JUMP_TIME + REACTION_TIME + (_last_w + w) * WIDTH_GAP / spd
	if arrival < _last_arrival + need:
		return false
	_pending.position = Vector2(SPAWN_X, WorldScript.WATER_Y)
	world.people.add_child(_pending)
	if _pending.kind == "tubarao":
		Sfx.play("shark")
	_last_arrival = arrival
	_last_w = w
	_pending = null
	return true


## Intervalo até o próximo obstáculo: encurta a cada nível (a cada 20 s).
func _interval() -> float:
	var base := maxf(INTERVAL_START * pow(INTERVAL_FACTOR, level), INTERVAL_MIN)
	return base * rng.randf_range(0.8, 1.25)


func _level_up(lvl: int) -> void:
	var msg := "mais movimento na água"
	for l in range(level + 1, lvl + 1):
		if l < LEVEL_UNLOCKS.size():
			_pool.append_array(LEVEL_UNLOCKS[l][0])
			msg = LEVEL_UNLOCKS[l][1]
	level = lvl
	hud.level = level
	hud.toast("NÍVEL %d" % (level + 1), msg)
	Sfx.play("level")
	if Game.debug_log:
		print("[jogo] nível %d em t=%.1f (intervalo base %.2fs)" % [level + 1, elapsed, maxf(INTERVAL_START * pow(INTERVAL_FACTOR, level), INTERVAL_MIN)])


# --- Colisão, pontuação e combo ---

func _check_people() -> void:
	var hb: Rect2 = world.surfer.hitbox()
	for p in world.people.get_children():
		if p.passed:
			continue
		var pb: Rect2 = p.hitbox()
		if hb.intersects(pb):
			_crash(p)
			return
		if pb.end.x < hb.position.x:
			p.passed = true
			_on_passed(p)


func _on_passed(p) -> void:
	people_passed += 1
	combo += 1
	score += POINTS_PERSON
	hud.popup("+%d" % POINTS_PERSON, Vector2(world.surfer.feet().x, 440.0))
	hud.bump_combo()
	Sfx.play("pass")
	if combo == COMBO_TUBE:
		tubes += 1
		score += BONUS_TUBE
		hud.banner("TUBO!", "+%d" % BONUS_TUBE, 1.5, UiKit.TEAL)
		world.set_tube(true)
		tube_timer = TUBE_SHOW_TIME
		Sfx.play("tube")
	elif combo >= COMBO_AERIAL:
		aerials += 1
		score += BONUS_AERIAL
		hud.banner("AÉREO!", "+%d" % BONUS_AERIAL, 1.5, UiKit.SUN)
		world.set_tube(false)
		tube_timer = 0.0
		world.surfer.play_aerial()
		Sfx.play("aerial")
		combo = 0
	if Game.debug_log:
		print("[jogo] t=%.1f superou %s | pontos=%d combo=%d" % [elapsed, p.kind, score, combo])


func _crash(p) -> void:
	crash_name = p.display_name()
	combo = 0
	tube_timer = 0.0
	world.set_tube(false)
	world.surfer.crash()
	hud.banner("WIPEOUT!", "", 1.4, UiKit.CORAL)
	Sfx.play("crash")
	_change(State.CRASHING)
	if Game.debug_log:
		print("[jogo] colisão com %s em t=%.1f | surfista %s altura=%.0f | obstáculo %s" % [p.kind, elapsed, world.surfer.hitbox(), world.surfer.height, p.hitbox()])


func _finish() -> void:
	won = true
	tube_timer = 0.0
	world.set_tube(false)
	world.surfer.victory()
	hud.banner("FIM DA ONDA!", "você sobreviveu à sessão", 2.0, UiKit.SUN)
	Sfx.play("win")
	_change(State.FINISHING)


func _change(s: State) -> void:
	state = s
	state_t = 0.0


func _autopilot() -> void:
	var s = world.surfer
	if s.state != SurferScript.State.RIDE:
		return
	var fx: float = s.feet().x
	for p in world.people.get_children():
		if p.passed:
			continue
		var lead: float = (p.position.x - fx) / (world.speed + p.extra_speed)
		if lead > 0.0 and lead <= SurferScript.JUMP_TIME * 0.5:
			s.request_jump()
		break


# --- Pausa ---

func _set_paused(on: bool) -> void:
	get_tree().paused = on
	if on:
		pause_menu.open()
	else:
		pause_menu.hide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.PLAYING and not get_tree().paused and not Game.debug_log:
		_set_paused(true)


# --- Tela de Game Over / Conclusão ---

func _show_result() -> void:
	_change(State.RESULT)
	hud.hide()
	new_record = Game.submit_score(score)
	if not won:
		Sfx.play("lose")
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = Game.get_theme()
	ui_layer.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.04, 0.09, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 0)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	if won:
		col.add_child(UiKit.label("Sessão concluída!", 56, UiKit.SUN, Game.font_display, 10))
		col.add_child(UiKit.label("Você surfou a onda até o fim.", 22, UiKit.MUTED))
	else:
		col.add_child(UiKit.label("Fim de partida", 56, UiKit.CORAL, Game.font_display, 10))
		col.add_child(UiKit.label("Você colidiu com %s." % crash_name, 22, UiKit.MUTED))
	col.add_child(_spacer(8))
	col.add_child(UiKit.label("PONTUAÇÃO FINAL", 18, UiKit.MUTED))
	col.add_child(UiKit.label(UiKit.fmt(score), 68, UiKit.SAND, Game.font_title, 10))
	if new_record:
		col.add_child(UiKit.label("Novo recorde!", 32, UiKit.TEAL, Game.font_display, 6))
	else:
		col.add_child(UiKit.label("Recorde: %s" % UiKit.fmt(Game.best_score), 20, UiKit.MUTED))
	col.add_child(UiKit.label("Obstáculos superados: %d   ·   Tubos: %d   ·   Aéreos: %d" % [people_passed, tubes, aerials], 18, UiKit.TEXT))
	col.add_child(UiKit.label("Nível alcançado: %d" % (level + 1), 18, UiKit.SUN))
	col.add_child(_spacer(12))
	var again := UiKit.button("Jogar novamente", func(): Game.goto("game"))
	var menu := UiKit.button("Menu principal", func(): Game.goto("menu"))
	col.add_child(again)
	col.add_child(menu)
	# evita reiniciar sem querer quem ainda está apertando ESPAÇO
	again.disabled = true
	menu.disabled = true
	root.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(root, "modulate:a", 1.0, 0.3)
	tw.tween_interval(0.35)
	tw.tween_callback(func():
		again.disabled = false
		menu.disabled = false
		again.grab_focus())


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
