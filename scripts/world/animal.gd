extends Node2D
## Animal marinho: obstáculo reutilizável (scenes/animal.tscn), com a mesma interface de person.gd.
## - tartaruga: baixa e lenta
## - tubarão: barbatana alta e nada mais rápido que a correnteza (chega antes do esperado)
## - golfinho: sozinho ou em dupla, saltando; a hitbox acompanha a altura do salto
## - baleia: enorme, exige salto no tempo certo
## A origem do nó fica na linha d'água; a água da frente cobre a parte submersa.

const DrawUtil = preload("res://scripts/draw_util.gd")
const WATER_Y := 560.0

const TYPES := {
	"tartaruga": {"w": 66.0, "h": 24.0, "extra": 0.0, "hit_w": 0.8},
	"tubarao": {"w": 56.0, "h": 62.0, "extra": 90.0, "hit_w": 0.8},
	"golfinho": {"w": 74.0, "h": 42.0, "extra": 40.0, "hit_w": 0.8},
	"baleia": {"w": 210.0, "h": 40.0, "extra": 0.0, "hit_w": 0.75},
}
const DOLPHIN_PERIOD := 1.4

var kind := "tartaruga"
var w := 66.0
var h := 24.0
var extra_speed := 0.0   # velocidade própria do animal, somada à do mundo
var passed := false
var t := 0.0

var _hit_w := 0.8
var _count := 1
var _phase := 0.0


func setup(k: String, rng: RandomNumberGenerator) -> void:
	kind = k
	var d: Dictionary = TYPES[k]
	w = d["w"]
	h = d["h"]
	extra_speed = d["extra"]
	_hit_w = d["hit_w"]
	t = rng.randf() * 10.0
	_phase = rng.randf() * TAU
	if k == "golfinho" and rng.randf() < 0.55:
		_count = 2
		w = 136.0


func display_name() -> String:
	match kind:
		"tartaruga":
			return "uma tartaruga marinha"
		"tubarao":
			return "um tubarão"
		"golfinho":
			return "dois golfinhos" if _count == 2 else "um golfinho"
		"baleia":
			return "uma baleia"
	return "um animal"


func hitbox() -> Rect2:
	var hgt := h
	if kind == "golfinho":
		hgt = 0.0
		for i in _count:
			hgt = maxf(hgt, _dolphin_top(i))
	return Rect2(position.x - w * _hit_w * 0.5, WATER_Y - hgt * 0.9, w * _hit_w, hgt * 0.9)


func step(delta: float, speed: float) -> void:
	t += delta
	position.x -= (speed + extra_speed) * delta
	queue_redraw()


func _draw() -> void:
	match kind:
		"tartaruga":
			_turtle()
		"tubarao":
			_shark()
		"golfinho":
			for i in _count:
				_dolphin(i)
		"baleia":
			_whale()
	var ring := DrawUtil.ellipse(Vector2(0, 1), w * 0.55 + 3.0 * sin(t * 3.0), 4.5, 24)
	ring.append(ring[0])
	draw_polyline(ring, Color(1, 1, 1, 0.5), 2.0, true)


# --- Tartaruga ---

func _turtle() -> void:
	var o := Vector2(0, 1.5 * sin(t * 2.2))
	var skin := Color(0.5, 0.6, 0.36)
	var shell := Color(0.45, 0.36, 0.18)
	var plate := Color(0.33, 0.25, 0.12)
	draw_colored_polygon(_rot_ellipse(o + Vector2(24, 2), 9.0, 3.5, 0.5 + 0.3 * sin(t * 4.0 + 1.0)), skin.darkened(0.1))
	DrawUtil.limb(self, o + Vector2(-16, -4), o + Vector2(-26, -8), skin, 8.0)
	draw_circle(o + Vector2(-29, -9), 7.0, skin)
	draw_circle(o + Vector2(-32, -11), 1.4, Color(0.05, 0.05, 0.05))
	var dome := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		dome.append(o + Vector2(3, 2) + Vector2(cos(a) * 26.0, sin(a) * 18.0))
	draw_colored_polygon(dome, shell)
	for p in [Vector2(-8, -7), Vector2(4, -11), Vector2(16, -7), Vector2(-14, -1), Vector2(4, -3), Vector2(20, -1)]:
		draw_colored_polygon(DrawUtil.ellipse(o + p, 5.5, 3.5, 10), plate)
	draw_polyline(dome, shell.lightened(0.25), 2.5, true)
	draw_colored_polygon(_rot_ellipse(o + Vector2(-12, 0), 14.0, 4.0, -0.6 + 0.7 * sin(t * 4.0)), skin)


# --- Tubarão ---

## Tubarão inteiro saindo da água (a metade de baixo aparece através da água da frente):
## corpo torpedo, barriga clara, barbatana dorsal alta, cauda com lobo de cima maior,
## guelras, olho e a boca que abre mostrando os dentes de tempos em tempos.
func _shark() -> void:
	var o := Vector2(0, -10.0 + 1.5 * sin(t * 3.0))
	var grey := Color(0.4, 0.48, 0.57)
	var dark := grey.darkened(0.3)
	var belly := Color(0.9, 0.92, 0.94)

	# cauda (balança em torno da base)
	var sway := sin(t * 7.0) * 0.18
	var pivot := o + Vector2(46, 0)
	var tail := PackedVector2Array()
	for p in [Vector2(44, -5), Vector2(60, -18), Vector2(76, -34), Vector2(71, -14), Vector2(66, -1),
			Vector2(73, 14), Vector2(60, 7), Vector2(44, 5)]:
		tail.append(pivot + (o + p - pivot).rotated(sway))
	draw_colored_polygon(tail, grey.darkened(0.08))

	# nadadeira peitoral (embaixo d'água)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-26, 10), o + Vector2(-10, 30), o + Vector2(-6, 12)]), grey.darkened(0.12))

	# corpo e barriga
	var top := DrawUtil.bezier(o + Vector2(-68, 5), o + Vector2(-52, -12), o + Vector2(18, -21), o + Vector2(50, -3), 18)
	var bottom := DrawUtil.bezier(o + Vector2(50, 4), o + Vector2(24, 22), o + Vector2(-40, 22), o + Vector2(-64, 8), 18)
	var body := top.duplicate()
	body.append_array(bottom)
	draw_colored_polygon(body, grey)
	var mid := DrawUtil.bezier(o + Vector2(-63, 7), o + Vector2(-36, 6), o + Vector2(20, 8), o + Vector2(49, 1), 18)
	var belly_poly := mid.duplicate()
	belly_poly.append_array(bottom)
	draw_colored_polygon(belly_poly, belly)
	# dorso mais escuro (sombreamento)
	var shade := PackedVector2Array()
	for p in top:
		shade.append(p + Vector2(0, 7))
	DrawUtil.strip(self, top, shade, PackedColorArray([Color(dark, 0.7)]), PackedColorArray([Color(dark, 0.0)]))

	# barbatanas dorsais
	var fin := PackedVector2Array([o + Vector2(-12, -14), o + Vector2(-6, -30), o + Vector2(0, -44), o + Vector2(5, -50),
		o + Vector2(7, -38), o + Vector2(10, -24), o + Vector2(17, -14)])
	draw_colored_polygon(fin, grey.darkened(0.06))
	draw_polyline(PackedVector2Array([o + Vector2(-11, -15), o + Vector2(-5, -30), o + Vector2(1, -44), o + Vector2(5, -49)]), grey.lightened(0.3), 2.0, true)
	draw_colored_polygon(PackedVector2Array([o + Vector2(31, -9), o + Vector2(36, -18), o + Vector2(40, -8)]), grey.darkened(0.06))

	# guelras, olho
	for i in 3:
		var gx := -33.0 + i * 4.5
		draw_line(o + Vector2(gx, -8), o + Vector2(gx + 2.0, 5), Color(dark, 0.8), 1.6, true)
	draw_circle(o + Vector2(-45, -4), 2.4, Color(0.04, 0.04, 0.06))
	draw_circle(o + Vector2(-45.7, -4.8), 0.8, Color(1, 1, 1, 0.9))

	# boca: abre por um instante a cada ~1,8 s
	var cyc := fposmod(t + _phase, 1.8)
	var m := sin(PI * cyc / 0.7) if cyc < 0.7 else 0.0
	var corner := o + Vector2(-40, 8)
	var upper := o + Vector2(-63, 6)
	var lower := o + Vector2(-58, 8.0 + 10.0 * m)
	if m > 0.05:
		draw_colored_polygon(PackedVector2Array([upper, corner, lower]), Color(0.42, 0.07, 0.1))
		for i in 4:
			var a := upper.lerp(corner, 0.15 + i * 0.22)
			draw_colored_polygon(PackedVector2Array([a + Vector2(-2, 0), a + Vector2(2, 0), a + Vector2(0, 3.5)]), Color.WHITE)
		for i in 3:
			var b := lower.lerp(corner, 0.2 + i * 0.26)
			draw_colored_polygon(PackedVector2Array([b + Vector2(-2, 0), b + Vector2(2, 0), b + Vector2(0, -3.0 * m)]), Color.WHITE)
	draw_line(upper, corner, Color(dark, 0.9), 1.6, true)

	# espuma: onda no focinho e linha d'água ao longo do corpo, esteira atrás
	for i in 5:
		draw_circle(Vector2(o.x - 68.0 - i * 4.0, -1.0 + sin(t * 12.0 + i) * 1.5), 4.5 - i * 0.7, Color(1, 1, 1, 0.9))
	for i in 7:
		var fx := o.x - 50.0 + i * 15.0
		draw_colored_polygon(DrawUtil.ellipse(Vector2(fx, 0), 7.0, 2.0, 10), Color(1, 1, 1, 0.55))
	for i in 6:
		var k := i / 5.0
		draw_line(Vector2(o.x + 56.0 + i * 10.0, -1.0), Vector2(o.x + 64.0 + i * 10.0, -1.0 - 3.0 * (1.0 - k)), Color(1, 1, 1, 0.6 * (1.0 - k)), 2.0, true)


# --- Golfinho ---

func _dolphin_phase(i: int) -> float:
	return t * TAU / DOLPHIN_PERIOD + _phase + i * 1.9


func _dolphin_dx(i: int) -> float:
	if _count == 1:
		return 0.0
	return -32.0 if i == 0 else 34.0


## Altura (acima da água) do ponto mais alto do golfinho neste instante.
func _dolphin_top(i: int) -> float:
	return maxf(10.0, sin(_dolphin_phase(i)) * 28.0 + 12.0)


func _dolphin(i: int) -> void:
	var ph := _dolphin_phase(i)
	var dx := _dolphin_dx(i)
	var body := Color(0.42, 0.52, 0.62)
	var belly := Color(0.84, 0.88, 0.92)
	draw_set_transform(Vector2(dx, -sin(ph) * 28.0), 0.55 * cos(ph), Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([Vector2(26, 0), Vector2(40, -9), Vector2(36, 0), Vector2(40, 9)]), body.darkened(0.1))
	draw_colored_polygon(DrawUtil.ellipse(Vector2.ZERO, 30.0, 9.0, 24), body)
	draw_colored_polygon(DrawUtil.ellipse(Vector2(-4, 4), 22.0, 4.5, 20), belly)
	draw_colored_polygon(DrawUtil.ellipse(Vector2(-31, 2), 7.0, 3.0, 12), body)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -8), Vector2(6, -19), Vector2(10, -7)]), body.darkened(0.08))
	draw_colored_polygon(PackedVector2Array([Vector2(-12, 3), Vector2(-4, 12), Vector2(-2, 4)]), body.darkened(0.15))
	draw_circle(Vector2(-22, -2), 1.6, Color(0.05, 0.05, 0.08))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if absf(sin(ph)) < 0.3:
		for j in 5:
			draw_circle(Vector2(dx - 20.0 + j * 10.0, -2.0 - absf(sin(t * 10.0 + j)) * 6.0), 4.0, Color(1, 1, 1, 0.85))


# --- Baleia ---

func _hump_y(x: float) -> float:
	var u := clampf((x + 105.0) / 210.0, 0.0, 1.0)
	return -40.0 * pow(sin(PI * u), 0.5 if u < 0.5 else 0.9)


func _whale() -> void:
	var o := Vector2(0, 2.0 * sin(t * 1.2))
	var dark := Color(0.2, 0.26, 0.34)
	var tops := PackedVector2Array()
	var bots := PackedVector2Array()
	for i in 25:
		var x := -105.0 + 210.0 * i / 24.0
		tops.append(o + Vector2(x, _hump_y(x)))
		bots.append(o + Vector2(x, 8.0))
	DrawUtil.strip(self, tops, bots, PackedColorArray([dark.lightened(0.18)]), PackedColorArray([dark.darkened(0.1)]))
	var shine := PackedVector2Array()
	for i in range(2, 20):
		shine.append(tops[i] + Vector2(0, 4))
	draw_polyline(shine, Color(1, 1, 1, 0.18), 3.0, true)
	for j in 7:
		var bx := -86.0 + j * 9.0
		draw_circle(o + Vector2(bx, _hump_y(bx) + 6.0 + (j % 2) * 5.0), 1.8 + (j % 3) * 0.6, Color(0.75, 0.78, 0.8))
	var fx := 60.0
	var fy := _hump_y(fx)
	draw_colored_polygon(PackedVector2Array([o + Vector2(fx - 10.0, fy + 2.0), o + Vector2(fx + 6.0, fy - 12.0), o + Vector2(fx + 10.0, fy + 4.0)]), dark.darkened(0.1))
	draw_circle(o + Vector2(-92, -8), 2.0, Color(0.05, 0.05, 0.05))
	draw_line(o + Vector2(-104, -1), o + Vector2(-80, 2), Color(0.1, 0.12, 0.16), 1.5, true)
	# esguicho periódico (só visual)
	var cyc := fposmod(t + _phase, 3.2)
	if cyc < 1.2:
		var k := cyc / 1.2
		var base := o + Vector2(-62.0, _hump_y(-62.0))
		for j in 12:
			var f := float(j) / 11.0
			var p := base + Vector2(sin(j * 2.3) * 14.0 * f * k, -90.0 * f * k)
			draw_circle(p, (3.0 + 7.0 * f) * (0.6 + 0.4 * k), Color(1, 1, 1, 0.85 * (1.0 - k * 0.7) * (1.0 - f * 0.4)))


func _rot_ellipse(c: Vector2, rx: float, ry: float, ang: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(ang))
	return pts
