extends Node2D
## Surfista: estados (surfando, saltando, caindo, comemorando), animação procedural e hitbox.
## Fica em posição horizontal quase fixa (GDD 5); o cenário é que se move.
## O salto tem altura e duração pré-definidas (GDD 5.2).

signal jumped
signal landed

enum State { RIDE, JUMP, CRASH, VICTORY }

const BASE_X := 380.0
const WATER_Y := 560.0
const JUMP_HEIGHT := 165.0
const JUMP_TIME := 0.8
const GRAVITY := 8.0 * JUMP_HEIGHT / (JUMP_TIME * JUMP_TIME)
const JUMP_SPEED := 4.0 * JUMP_HEIGHT / JUMP_TIME
const BUFFER_TIME := 0.14
const HOP_TIME := 0.6
const ART_SCALE := 1.25
const PIVOT := 36.0

const SurferLook = preload("res://scripts/surfer_look.gd")
const STRIPE := Color(1.0, 0.96, 0.88)
const OUTLINE := Color(0.03, 0.08, 0.15, 0.55)

## Visual personalizado (tela "Personalizar surfista").
var skin_col := Color(0.86, 0.62, 0.44)
var top_col := Color(1.0, 0.8, 0.18)
var shorts_col := Color(0.1, 0.24, 0.58)
var hair_col := Color(0.24, 0.15, 0.08)
var board_col := Color(1.0, 0.45, 0.32)
var hair_style := 0
var beard := 0
## Na tela de personalização o surfista fica parado, só animando a pose.
var preview := false

var state := State.RIDE
var height := 0.0
var vy := 0.0
var t := 0.0
var tube_on := false
var tube := 0.0
var fx = null

var _buffer := 0.0
var _spin := 0.0
var _spin_left := 0.0
var _spin_rate := 0.0
var _hop_t := 0.0
var _victory_t := 0.0
var _spray_acc := 0.0
var _crash_pos := Vector2.ZERO
var _crash_vel := Vector2.ZERO
var _crash_rot := 0.0
var _board_pos := Vector2.ZERO
var _board_vel := Vector2.ZERO
var _board_rot := 0.0
var _board_floating := false
var _sunk := false


func _ready() -> void:
	apply_look(Game.look)
	_update_transform()


func apply_look(look: Dictionary) -> void:
	var l := SurferLook.sanitize(look)
	skin_col = SurferLook.SKINS[l["skin"]]
	hair_col = SurferLook.HAIR_COLORS[l["hair_color"]]
	top_col = SurferLook.CLOTHES[l["top"]]
	shorts_col = SurferLook.CLOTHES[l["shorts"]]
	board_col = SurferLook.BOARDS[l["board"]]
	hair_style = l["hair_style"]
	beard = l["beard"]
	queue_redraw()


func feet() -> Vector2:
	return Vector2(BASE_X + 6.0 * sin(t * 0.7), WATER_Y - height)


## Retângulo de colisão (prancha + corpo), um pouco menor que o desenho para ser justo.
func hitbox() -> Rect2:
	var f := feet()
	return Rect2(f.x - 28.0, f.y - 74.0, 56.0, 74.0)


func request_jump() -> bool:
	if state == State.RIDE:
		_jump()
		return true
	if state == State.JUMP:
		_buffer = BUFFER_TIME
	return false


## Aéreo (combo 5): giro de 360° com "grab". É só visual, não altera a hitbox.
func play_aerial() -> void:
	var remaining := HOP_TIME
	if state == State.JUMP:
		var disc := vy * vy + 2.0 * GRAVITY * height
		remaining = (vy + sqrt(disc)) / GRAVITY
	if remaining < 0.45:
		_hop_t = HOP_TIME
		remaining = HOP_TIME
	_spin_left = TAU
	_spin_rate = TAU / remaining


func crash() -> void:
	var f := feet()
	state = State.CRASH
	_crash_pos = f + Vector2(0, -40)
	_crash_vel = Vector2(-140, -380)
	_crash_rot = 0.0
	_board_pos = f
	_board_vel = Vector2(170, -520)
	_board_rot = 0.0
	_spin_left = 0.0
	_hop_t = 0.0
	tube_on = false
	if fx:
		fx.splash(f, 26, 1.5)


func victory() -> void:
	if state == State.JUMP:
		height = 0.0
	state = State.VICTORY
	_victory_t = 0.0


func step(delta: float) -> void:
	t += delta
	if preview:
		_update_transform()
		queue_redraw()
		return
	tube = move_toward(tube, 1.0 if (tube_on and state != State.CRASH) else 0.0, delta * 2.5)
	match state:
		State.RIDE:
			height = 0.0
			_spray(delta, 1.0)
		State.JUMP:
			vy -= GRAVITY * delta
			height += vy * delta
			_buffer -= delta
			if height <= 0.0:
				height = 0.0
				state = State.RIDE
				landed.emit()
				if fx:
					fx.splash(feet(), 12, 0.9)
				if _buffer > 0.0:
					_jump()
		State.CRASH:
			_crash_step(delta)
		State.VICTORY:
			_victory_t += delta
			height = 0.0
			_spray(delta, 0.5)
	if _spin_left > 0.0:
		var d := minf(_spin_rate * delta, _spin_left)
		_spin_left -= d
		_spin -= d
		if _spin_left <= 0.0:
			_spin = 0.0
	if _hop_t > 0.0:
		_hop_t = maxf(_hop_t - delta, 0.0)
	_update_transform()
	queue_redraw()


func _jump() -> void:
	state = State.JUMP
	vy = JUMP_SPEED
	_buffer = 0.0
	jumped.emit()
	if fx:
		fx.emit(feet() + Vector2(-30, 0), Vector2(-120, -200), 10, 0.5, Color(1, 1, 1, 0.9), 4.0, 0.6)


func _spray(delta: float, amount: float) -> void:
	if fx == null:
		return
	_spray_acc += delta * 34.0 * amount
	while _spray_acc >= 1.0:
		_spray_acc -= 1.0
		var tail := feet() + Vector2(-34.0 * ART_SCALE, -2.0)
		fx.emit(tail, Vector2(-170, -110), 1, 0.4, Color(1, 1, 1, 0.85), 3.0, 0.45)


func _crash_step(delta: float) -> void:
	if not _sunk:
		_crash_vel.y += 1300.0 * delta
		_crash_pos += _crash_vel * delta
		_crash_rot -= 7.0 * delta
		if _crash_pos.y > WATER_Y + 12.0:
			_sunk = true
			if fx:
				fx.splash(Vector2(_crash_pos.x, WATER_Y), 30, 1.8)
	if _board_floating:
		_board_pos.x += _board_vel.x * delta
		_board_vel.x = move_toward(_board_vel.x, 0.0, 120.0 * delta)
		_board_pos.y = WATER_Y - 2.0 + 2.0 * sin(t * 3.0)
		_board_rot = lerp_angle(_board_rot, 0.0, 4.0 * delta)
	else:
		_board_vel.y += 1300.0 * delta
		_board_pos += _board_vel * delta
		_board_rot += 9.0 * delta
		if _board_pos.y > WATER_Y and _board_vel.y > 0.0:
			_board_floating = true
			_board_vel = Vector2(-90, 0)
			if fx:
				fx.splash(_board_pos, 14, 1.0)


func _update_transform() -> void:
	if preview:
		position = Vector2(0, -PIVOT * ART_SCALE + 2.0 * sin(t * 3.1))
		rotation = 0.0
		return
	if state == State.CRASH:
		position = Vector2.ZERO
		rotation = 0.0
		return
	var f := feet()
	var hop := 0.0
	if _hop_t > 0.0:
		hop = 46.0 * sin(PI * (1.0 - _hop_t / HOP_TIME))
	var bob := 0.0
	if state == State.RIDE:
		bob = 2.0 * sin(t * 3.1)
	if state == State.VICTORY:
		bob = -6.0 * absf(sin(_victory_t * 4.0))
	position = f + Vector2(0, -PIVOT * ART_SCALE - hop + bob)
	var ang := 0.0
	if state == State.JUMP:
		ang = clampf(-vy / JUMP_SPEED * 0.35, -0.35, 0.35)
	rotation = ang + _spin


# --- Desenho ---

func _draw() -> void:
	if state == State.CRASH:
		_draw_crash()
		return
	draw_set_transform(Vector2(0, PIVOT * ART_SCALE), 0.0, Vector2(ART_SCALE, ART_SCALE))
	_draw_board()
	_draw_body(_pose())


func _pose() -> Dictionary:
	var crouch := 0.22 + 0.07 * sin(t * 2.4)
	var arms := 0.0
	var reach := 0.0
	var grab := false
	if state == State.JUMP:
		var k := clampf(height / JUMP_HEIGHT, 0.0, 1.0)
		crouch = lerpf(0.3, 0.75, k)
		arms = 0.55
	if _spin_left > 0.0 or _hop_t > 0.0:
		crouch = 0.9
		grab = true
	if tube > 0.0:
		crouch = lerpf(crouch, 1.0, tube)
		reach = tube
	if state == State.VICTORY:
		crouch = 0.05
		arms = 1.0
	return {"crouch": crouch, "arms": arms, "reach": reach, "grab": grab, "wave": state == State.VICTORY}


func _draw_board() -> void:
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	var n := 22
	for i in n + 1:
		var u := -1.0 + 2.0 * float(i) / n
		var half := 4.6 * sqrt(maxf(0.0, 1.0 - u * u))
		if u > 0.0:
			half *= 1.0 - 0.35 * u
		var lift := -7.0 * pow(maxf(u, 0.0), 3.0)
		if u < 0.0:
			lift -= 1.5 * u * u
		top.append(Vector2(u * 37.0, lift - half))
		if i > 0 and i < n:
			bot.append(Vector2(u * 37.0, lift + half))
	bot.reverse()
	var poly := top.duplicate()
	poly.append_array(bot)
	draw_colored_polygon(poly, board_col)
	poly.append(poly[0])
	draw_polyline(poly, OUTLINE, 1.2, true)
	var stripe := PackedVector2Array()
	for i in range(3, n - 2):
		stripe.append(top[i] + Vector2(0, 2.2))
	draw_polyline(stripe, STRIPE, 1.6, true)


func _draw_body(p: Dictionary) -> void:
	var crouch: float = p["crouch"]
	var arms: float = p["arms"]
	var reach: float = p["reach"]
	var grab: bool = p["grab"]
	var hip := Vector2(-2.0, -31.0 + crouch * 12.0)
	var phi := 0.18 + 0.5 * crouch
	var up := Vector2(sin(phi), -cos(phi))
	var shoulder := hip + up * 21.0
	var head := shoulder + up * 9.5 + Vector2(1.5, 0)
	var foot_b := Vector2(-13.0, -5.0)
	var foot_f := Vector2(13.0, -5.0)
	var knee_b := _knee(foot_b, hip, 16.5)
	var knee_f := _knee(foot_f, hip, 16.5)
	var hand_b := shoulder + Vector2(-16.0, 6.0 - 16.0 * arms)
	var hand_f := shoulder + Vector2(16.0, 5.0 - 16.0 * arms)
	if p["wave"]:
		hand_b += Vector2(0, -4.0 * sin(t * 10.0))
		hand_f += Vector2(0, 4.0 * sin(t * 10.0))
	if reach > 0.0:
		hand_b = hand_b.lerp(shoulder + Vector2(-20.0, -14.0), reach)
	if grab:
		hand_f = Vector2(8.0, -6.0)
	_limb(foot_b, knee_b, skin_col, 5.5)
	_limb(knee_b, hip, shorts_col, 7.5)
	_limb(shoulder, _elbow(shoulder, hand_b), skin_col, 4.5)
	_limb(_elbow(shoulder, hand_b), hand_b, skin_col, 4.0)
	_limb(hip, shoulder, top_col, 11.0)
	_draw_head(head)
	_limb(foot_f, knee_f, skin_col, 5.5)
	_limb(knee_f, hip, shorts_col, 7.5)
	_limb(shoulder, _elbow(shoulder, hand_f), top_col.darkened(0.08), 5.0)
	_limb(_elbow(shoulder, hand_f), hand_f, skin_col, 4.0)


## Cabeça com o estilo de cabelo e a barba escolhidos. O rosto olha para a frente (+x).
func _draw_head(head: Vector2) -> void:
	# cabelo comprido fica atrás da cabeça, balançando com o vento
	if hair_style == 1:
		var sway := sin(t * 5.0) * 1.5
		draw_colored_polygon(PackedVector2Array([head + Vector2(-2, -6), head + Vector2(-9, -3),
			head + Vector2(-13, 6 + sway), head + Vector2(-10, 12 + sway), head + Vector2(-4, 7)]), hair_col)
	draw_circle(head, 7.5, skin_col)
	match hair_style:
		0, 1:
			draw_colored_polygon(_hair_cap(head), hair_col)
		2:
			draw_colored_polygon(_hair_cap(head), hair_col)
			draw_circle(head + Vector2(-5.5, -7.5), 3.6, hair_col)
		3:
			# moicano: crista de espetos do meio da testa até a nuca
			var spikes := PackedVector2Array([head + Vector2(4, -6.5)])
			for i in 5:
				var a := lerpf(-PI * 0.38, -PI * 0.9, i / 4.0)
				spikes.append(head + Vector2(cos(a), sin(a)) * 12.5)
				var b := lerpf(-PI * 0.38, -PI * 0.9, (i + 0.5) / 4.0)
				spikes.append(head + Vector2(cos(b), sin(b)) * 7.2)
			spikes.append(head + Vector2(-6, -3))
			draw_colored_polygon(spikes, hair_col)
		4:
			draw_circle(head + Vector2(-2.0, -3.5), 2.2, Color(1, 1, 1, 0.25))   # careca com brilho
	match beard:
		1:
			draw_line(head + Vector2(3.0, 2.6), head + Vector2(7.2, 2.4), hair_col, 1.8, true)
		2:
			var b := PackedVector2Array()
			for i in 9:
				var a := lerpf(-PI * 0.02, PI * 0.72, i / 8.0)
				b.append(head + Vector2(cos(a), sin(a)) * 8.0)
			for i in 9:
				var a := lerpf(PI * 0.72, -PI * 0.02, i / 8.0)
				b.append(head + Vector2(1.5, -0.5) + Vector2(cos(a), sin(a)) * 5.2)
			draw_colored_polygon(b, hair_col)
	draw_circle(head + Vector2(3.6, -0.5), 1.1, Color(0.1, 0.06, 0.04))


func _hair_cap(head: Vector2) -> PackedVector2Array:
	var hair := PackedVector2Array()
	for i in 11:
		var a := lerpf(PI * 0.88, PI * 2.04, i / 10.0)
		hair.append(head + Vector2(cos(a), sin(a)) * 8.3)
	hair.append(head + Vector2(-1.0, 0.5))
	return hair


func _draw_crash() -> void:
	draw_set_transform(_board_pos, _board_rot, Vector2(ART_SCALE, ART_SCALE))
	_draw_board()
	if _sunk:
		return
	draw_set_transform(_crash_pos, _crash_rot, Vector2(ART_SCALE, ART_SCALE))
	var flail := sin(t * 14.0)
	_draw_body({"crouch": 0.45, "arms": 0.6 + 0.5 * flail, "reach": 0.0, "grab": false, "wave": false})


func _knee(foot: Vector2, hip: Vector2, seg: float) -> Vector2:
	var mid := (foot + hip) * 0.5
	var d := foot.distance_to(hip)
	if d >= seg * 2.0:
		return mid
	var perp := (hip - foot).normalized().orthogonal()
	if perp.x < 0.0:
		perp = -perp
	return mid + perp * sqrt(seg * seg - d * d * 0.25)


func _elbow(shoulder: Vector2, hand: Vector2) -> Vector2:
	return shoulder.lerp(hand, 0.5) + Vector2(0, 3)


func _limb(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	draw_line(a, b, col, w, true)
	draw_circle(a, w * 0.5, col)
	draw_circle(b, w * 0.5, col)
