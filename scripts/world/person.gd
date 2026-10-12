extends Node2D
## Pessoa na água: obstáculo reutilizável (scenes/person.tscn).
## O tipo define o tamanho da hitbox; cores, cabelo e acessórios são sorteados (variações visuais).
## A origem do nó fica na linha d'água; a água da frente cobre a parte submersa.

const DrawUtil = preload("res://scripts/draw_util.gd")
const WATER_Y := 560.0

## largura x altura (acima da água) de cada tipo
const TYPES := {
	"banhista": Vector2(40, 80),
	"crianca": Vector2(56, 52),
	"casal": Vector2(80, 82),
	"bodyboard": Vector2(96, 30),
	"remando": Vector2(114, 30),
	"sup": Vector2(72, 118),
}
const NAMES := {
	"banhista": "um banhista",
	"crianca": "uma criança de boia",
	"casal": "um casal na água",
	"bodyboard": "um bodyboarder",
	"remando": "um surfista remando",
	"sup": "um stand-up paddle",
}
## Tons de pele dos banhistas: claros e morenos.
const SKINS := [Color(0.99, 0.84, 0.72), Color(0.96, 0.78, 0.64), Color(0.9, 0.69, 0.52), Color(0.83, 0.6, 0.42), Color(0.74, 0.52, 0.35)]
const HAIRS := [Color(0.1, 0.07, 0.05), Color(0.35, 0.2, 0.1), Color(0.88, 0.7, 0.36), Color(0.62, 0.26, 0.12), Color(0.86, 0.86, 0.86)]
const SUITS := [Color(0.95, 0.25, 0.35), Color(0.2, 0.55, 0.95), Color(0.15, 0.75, 0.45), Color(0.98, 0.6, 0.15), Color(0.6, 0.3, 0.85), Color(0.12, 0.12, 0.18)]
const BOARDS := [Color(0.98, 0.9, 0.3), Color(0.3, 0.85, 0.85), Color(1.0, 0.5, 0.6), Color(0.95, 0.95, 0.95), Color(0.5, 0.8, 0.35)]
const DARK := Color(0.08, 0.06, 0.06)

var kind := "banhista"
var w := 40.0
var h := 80.0
var extra_speed := 0.0   # pessoas paradas na água: só a velocidade do mundo
var passed := false
var t := 0.0
var look := {}
var look2 := {}


func setup(k: String, rng: RandomNumberGenerator) -> void:
	kind = k
	var size: Vector2 = TYPES[k]
	w = size.x
	h = size.y
	t = rng.randf() * 10.0
	look = _random_look(rng)
	look2 = _random_look(rng)


func _random_look(rng: RandomNumberGenerator) -> Dictionary:
	return {
		"skin": SKINS[rng.randi() % SKINS.size()],
		"hair": HAIRS[rng.randi() % HAIRS.size()],
		"suit": SUITS[rng.randi() % SUITS.size()],
		"board": BOARDS[rng.randi() % BOARDS.size()],
		"long_hair": rng.randf() < 0.45,
		"hat": rng.randf() < 0.25,
		"glasses": rng.randf() < 0.3,
		"waving": rng.randf() < 0.5,
	}


func hitbox() -> Rect2:
	return Rect2(position.x - w * 0.4, WATER_Y - h * 0.9, w * 0.8, h * 0.9)


func display_name() -> String:
	return NAMES[kind]


func step(delta: float, speed: float) -> void:
	t += delta
	position.x -= speed * delta
	queue_redraw()


func _draw() -> void:
	var bob := 2.0 * sin(t * 2.6)
	match kind:
		"banhista":
			_bather(Vector2(0, bob), look, 1.0)
		"casal":
			_bather(Vector2(-18, bob), look, 1.0)
			_bather(Vector2(18, bob + 6.0), look2, 0.92)
		"crianca":
			_child(Vector2(0, bob))
		"bodyboard":
			_bodyboarder(Vector2(0, bob * 0.5))
		"remando":
			_paddler(Vector2(0, bob * 0.5))
		"sup":
			_sup(Vector2(0, bob * 0.6))
	# ondulação em volta da pessoa
	var ring := DrawUtil.ellipse(Vector2(0, 1), w * 0.62 + 3.0 * sin(t * 3.0), 4.5, 24)
	ring.append(ring[0])
	draw_polyline(ring, Color(1, 1, 1, 0.55), 2.0, true)


# --- Tipos de pessoa ---

func _bather(o: Vector2, l: Dictionary, s: float) -> void:
	var skin: Color = l["skin"]
	var suit: Color = l["suit"]
	var female: bool = l["long_hair"]
	var hip := o + Vector2(0, 14) * s
	var shoulder := o + Vector2(0, -46) * s
	var head := o + Vector2(0, -59) * s
	if female:
		_long_hair_back(head, l, s)
	DrawUtil.limb(self, hip, shoulder, skin, 18.0 * s)
	if female:
		draw_line(o + Vector2(-9, -36) * s, o + Vector2(9, -36) * s, suit, 6.0 * s, true)
	else:
		draw_line(o + Vector2(-10, 6) * s, o + Vector2(10, 6) * s, suit, 7.0 * s, true)
	# braços: um acenando, outro na água
	var hand_a := shoulder + Vector2(-14, 18) * s
	var hand_b := shoulder + Vector2(15, 22) * s
	if l["waving"]:
		hand_b = shoulder + Vector2(16, -24 + 5.0 * sin(t * 7.0)) * s
	DrawUtil.limb(self, shoulder + Vector2(-6, 2) * s, hand_a, skin, 6.0 * s)
	DrawUtil.limb(self, shoulder + Vector2(6, 2) * s, hand_b, skin, 6.0 * s)
	_head(head, l, s, 10.0)


func _child(o: Vector2) -> void:
	var skin: Color = look["skin"]
	var suit: Color = look["suit"]
	var ring_c := Vector2(0, -6) + o
	_float_ring(ring_c, suit, false)
	DrawUtil.limb(self, o + Vector2(0, 6), o + Vector2(0, -24), skin, 15.0)
	DrawUtil.limb(self, o + Vector2(-5, -20), o + Vector2(-20, -9), skin, 5.0)
	DrawUtil.limb(self, o + Vector2(5, -20), o + Vector2(20, -9), skin, 5.0)
	_float_ring(ring_c, suit, true)
	_head(o + Vector2(0, -34), look, 1.0, 8.5)


func _float_ring(c: Vector2, col: Color, front: bool) -> void:
	# metade de trás antes do corpo, metade da frente depois (dá profundidade)
	var segs := 12
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var is_front := sin((a0 + a1) * 0.5) > 0.0
		if is_front != front:
			continue
		var p0 := c + Vector2(cos(a0) * 26.0, sin(a0) * 8.0)
		var p1 := c + Vector2(cos(a1) * 26.0, sin(a1) * 8.0)
		draw_line(p0, p1, col if i % 2 == 0 else Color(1, 1, 1), 10.0, true)


func _bodyboarder(o: Vector2) -> void:
	var skin: Color = look["skin"]
	var suit: Color = look["suit"]
	var board: Color = look["board"]
	var b := DrawUtil.ellipse(o + Vector2(6, -4), 36.0, 5.5, 20)
	draw_colored_polygon(b, board)
	var kick := 4.0 * sin(t * 12.0)
	DrawUtil.limb(self, o + Vector2(-6, -12), o + Vector2(-32, -9 + kick), skin, 6.0)
	DrawUtil.limb(self, o + Vector2(-6, -12), o + Vector2(-30, -11 - kick), skin, 6.0)
	draw_circle(o + Vector2(-36, -4), 5.0 + 2.0 * absf(sin(t * 12.0)), Color(1, 1, 1, 0.8))
	DrawUtil.limb(self, o + Vector2(-6, -12), o + Vector2(22, -14), suit, 13.0)
	var hand := o + Vector2(38.0 + 8.0 * sin(t * 6.0), -4.0 + 3.0 * cos(t * 6.0))
	DrawUtil.limb(self, o + Vector2(20, -15), hand, skin, 5.0)
	_head(o + Vector2(33, -20), look, 1.0, 8.5)


func _paddler(o: Vector2) -> void:
	var skin: Color = look["skin"]
	var suit: Color = look["suit"]
	var board: Color = look["board"]
	draw_colored_polygon(DrawUtil.ellipse(o + Vector2(4, -3), 57.0, 5.0, 24), board)
	draw_line(o + Vector2(-48, -4), o + Vector2(54, -4), Color(1, 1, 1, 0.7), 1.5, true)
	DrawUtil.limb(self, o + Vector2(-20, -11), o + Vector2(-48, -9), skin, 6.0)
	DrawUtil.limb(self, o + Vector2(-20, -11), o + Vector2(18, -15), suit, 12.0)
	var sh := o + Vector2(16, -16)
	var hand := sh + Vector2(cos(t * 5.0) * 16.0, sin(t * 5.0) * 12.0 + 6.0)
	DrawUtil.limb(self, sh, hand, skin, 5.0)
	_head(o + Vector2(30, -22), look, 1.0, 8.5)


func _sup(o: Vector2) -> void:
	var skin: Color = look["skin"]
	var suit: Color = look["suit"]
	var board: Color = look["board"]
	draw_colored_polygon(DrawUtil.ellipse(o + Vector2(0, -3), 46.0, 5.0, 24), board)
	var hip := o + Vector2(0, -50)
	var shoulder := o + Vector2(0, -82)
	DrawUtil.limb(self, o + Vector2(-9, -7), hip, skin, 7.0)
	DrawUtil.limb(self, o + Vector2(9, -7), hip, skin, 7.0)
	DrawUtil.limb(self, hip + Vector2(0, 4), hip + Vector2(0, -4), suit, 15.0)
	DrawUtil.limb(self, hip, shoulder, suit, 14.0)
	# remo
	var swing := sin(t * 2.2) * 0.25
	var top := o + Vector2(16, -110).rotated(swing)
	var blade := o + Vector2(-30, 8).rotated(swing)
	draw_line(top, blade, Color(0.25, 0.2, 0.18), 3.0, true)
	draw_colored_polygon(DrawUtil.ellipse(blade, 4.0, 9.0, 12), Color(0.25, 0.2, 0.18))
	var hand1 := top.lerp(blade, 0.12)
	var hand2 := top.lerp(blade, 0.42)
	DrawUtil.limb(self, shoulder + Vector2(4, 2), hand1, skin, 5.0)
	DrawUtil.limb(self, shoulder + Vector2(-4, 2), hand2, skin, 5.0)
	_head(o + Vector2(0, -95), look, 1.0, 9.5)


# --- Cabeça e acessórios ---

func _long_hair_back(head: Vector2, l: Dictionary, s: float) -> void:
	var hair: Color = l["hair"]
	draw_colored_polygon(DrawUtil.ellipse(head + Vector2(0, 8) * s, 11.0 * s, 15.0 * s, 18), hair)


func _head(c: Vector2, l: Dictionary, s: float, r: float) -> void:
	var skin: Color = l["skin"]
	var hair: Color = l["hair"]
	draw_circle(c, r * s, skin)
	var cap := PackedVector2Array()
	for i in 11:
		var a := lerpf(PI, TAU, i / 10.0)
		cap.append(c + Vector2(cos(a), sin(a)) * (r + 0.8) * s)
	cap.append(c + Vector2(r * 0.9, -r * 0.1) * s)
	cap.append(c + Vector2(-r * 0.9, -r * 0.1) * s)
	draw_colored_polygon(cap, hair)
	if l["glasses"]:
		draw_line(c + Vector2(-r * 0.75, r * 0.05) * s, c + Vector2(r * 0.75, r * 0.05) * s, DARK, 2.0)
		draw_circle(c + Vector2(-r * 0.38, r * 0.15) * s, r * 0.28 * s, DARK)
		draw_circle(c + Vector2(r * 0.38, r * 0.15) * s, r * 0.28 * s, DARK)
	else:
		draw_circle(c + Vector2(-r * 0.35, r * 0.1) * s, 1.2 * s, DARK)
		draw_circle(c + Vector2(r * 0.35, r * 0.1) * s, 1.2 * s, DARK)
	if l["hat"]:
		var brim := DrawUtil.ellipse(c + Vector2(0, -r * 0.55) * s, r * 1.7 * s, r * 0.35 * s, 18)
		var straw := Color(0.93, 0.8, 0.5)
		draw_colored_polygon(brim, straw)
		draw_circle(c + Vector2(0, -r * 0.85) * s, r * 0.75 * s, straw)
		draw_line(c + Vector2(-r * 0.7, -r * 0.6) * s, c + Vector2(r * 0.7, -r * 0.6) * s, Color(0.85, 0.3, 0.25), 2.0)
