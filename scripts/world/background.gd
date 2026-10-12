extends Node2D
## Camadas de fundo com parallax: céu, sol, nuvens, gaivotas, costa no horizonte e mar aberto.
## A câmera está na areia olhando para o mar; a faixa de praia em primeiro plano fica em water.gd.

const Palette = preload("res://scripts/world/palette.gd")
const DrawUtil = preload("res://scripts/draw_util.gd")

const W := 1280.0
const H := 720.0
const HORIZON := 250.0
const COAST := 3000.0       # período do padrão da costa (repete sem emenda)
const COAST_PARALLAX := 0.035
const PROP_COLORS := [Color(0.95, 0.3, 0.3), Color(0.2, 0.6, 0.95), Color(1.0, 0.75, 0.2), Color(0.3, 0.8, 0.5), Color(0.9, 0.4, 0.75)]

var scroll := 0.0
var progress := 0.0
var t := 0.0

var _props: Array = []
var _clouds: Array = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var x := 0.0
	while x < COAST:
		var hgt := _land(x)
		if hgt > 4.0:
			var kind := "house"
			var r := rng.randf()
			if r < 0.3:
				kind = "palm"
			elif r < 0.36 and hgt > 30.0:
				kind = "lighthouse"
			elif hgt < 14.0:
				kind = "umbrella"
			_props.append({"x": x, "kind": kind, "c": rng.randi_range(0, PROP_COLORS.size() - 1)})
		x += rng.randf_range(14.0, 34.0)
	for i in 6:
		_clouds.append({"x": rng.randf_range(0.0, W + 400.0), "y": rng.randf_range(40.0, 180.0), "s": rng.randf_range(0.7, 1.4)})


func step(delta: float) -> void:
	t += delta
	queue_redraw()


## Altura da terra no horizonte (função periódica, então a costa repete sem emenda).
func _land(wx: float) -> float:
	var a := TAU * wx / COAST
	return maxf(0.0, 52.0 * sin(a * 2.0) + 22.0 * sin(a * 5.0 + 1.0) + 12.0 * sin(a * 9.0 + 2.0) - 6.0)


func _draw() -> void:
	var pal := Palette.at(progress)
	_draw_sky(pal)
	_draw_sun(pal)
	_draw_clouds(pal)
	_draw_birds()
	_draw_sea(pal)
	_draw_coast(pal)


func _sun_pos() -> Vector2:
	return Vector2(760.0, 105.0).lerp(Vector2(700.0, 238.0), progress)


func _draw_sky(pal: Dictionary) -> void:
	var top: Color = pal["sky_top"]
	var bot: Color = pal["sky_bot"]
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, HORIZON), Vector2(0, HORIZON)]),
		PackedColorArray([top, top, bot, bot]))


func _draw_sun(pal: Dictionary) -> void:
	var sun: Color = pal["sun"]
	var pos := _sun_pos()
	for i in 5:
		draw_circle(pos, 40.0 + i * 22.0, Color(sun, 0.07))
	draw_circle(pos, 34.0, sun)


func _draw_clouds(pal: Dictionary) -> void:
	var col: Color = pal["cloud"]
	col.a = 0.85
	for c in _clouds:
		var s: float = c["s"]
		var cx := fposmod(float(c["x"]) - scroll * 0.015 - t * 6.0, W + 400.0) - 200.0
		var base := Vector2(cx, float(c["y"]))
		draw_circle(base, 24.0 * s, col)
		draw_circle(base + Vector2(28, -12) * s, 30.0 * s, col)
		draw_circle(base + Vector2(60, -2) * s, 22.0 * s, col)
		draw_circle(base + Vector2(86, 6) * s, 15.0 * s, col)
		draw_rect(Rect2(base.x, base.y, 86.0 * s, 21.0 * s), col)


func _draw_birds() -> void:
	var col := Color(0.15, 0.18, 0.25, 0.7)
	for i in 3:
		var bx := fposmod(i * 470.0 + t * 38.0 - scroll * 0.05, W + 200.0) - 100.0
		var by := 120.0 + i * 30.0 + sin(t * 0.8 + i) * 10.0
		var flap := sin(t * 7.0 + i * 2.0) * 5.0
		draw_polyline(PackedVector2Array([Vector2(bx - 9, by - flap), Vector2(bx, by), Vector2(bx + 9, by - flap)]), col, 2.0, true)


func _draw_sea(pal: Dictionary) -> void:
	var far: Color = pal["sea_far"]
	var near: Color = pal["sea_near"]
	var sun: Color = pal["sun"]
	draw_polygon(PackedVector2Array([Vector2(0, HORIZON), Vector2(W, HORIZON), Vector2(W, H), Vector2(0, H)]),
		PackedColorArray([far.lightened(0.08), far.lightened(0.08), near, near]))
	# reflexo do sol
	var sx := _sun_pos().x
	for r in 8:
		var y := HORIZON + 5.0 + r * 11.0
		var half := 40.0 - r * 3.0 + sin(t * 2.0 + r) * 6.0
		draw_line(Vector2(sx - half, y), Vector2(sx + half, y), Color(sun, 0.25 - r * 0.025), 2.5)
	# ondulações do mar aberto (perspectiva: mais juntas perto do horizonte)
	for r in 9:
		var y := HORIZON + 6.0 + pow(r / 8.0, 1.6) * 150.0
		var f := 0.05 + 0.4 * (r / 8.0)
		for j in 6:
			var x := fposmod(j * 241.0 + r * 83.0 - scroll * f, W + 160.0) - 80.0
			draw_line(Vector2(x, y), Vector2(x + 18.0 + r * 4.0, y), Color(1, 1, 1, 0.08 + 0.012 * r), 1.5 + r * 0.15)
	# veleiro distante
	var bx := fposmod(560.0 - scroll * 0.03, W + 300.0) - 150.0
	var by := HORIZON + 10.0
	draw_colored_polygon(PackedVector2Array([Vector2(bx - 12, by - 3), Vector2(bx + 12, by - 3), Vector2(bx + 8, by + 1), Vector2(bx - 8, by + 1)]), Color(0.25, 0.22, 0.3, 0.75))
	draw_colored_polygon(PackedVector2Array([Vector2(bx - 1, by - 5), Vector2(bx - 1, by - 26), Vector2(bx + 10, by - 5)]), Color(1, 1, 1, 0.8))


func _draw_coast(pal: Dictionary) -> void:
	var hill: Color = pal["hill"]
	var sand: Color = pal["sand"]
	var green := hill.lerp(Color(0.2, 0.42, 0.32), 0.35)
	var offset := scroll * COAST_PARALLAX
	var tops := PackedVector2Array()
	var bots := PackedVector2Array()
	var x := -10.0
	while x <= W + 12.0:
		tops.append(Vector2(x, HORIZON - _land(x + offset)))
		bots.append(Vector2(x, HORIZON + 1.0))
		x += 8.0
	DrawUtil.strip(self, tops, bots, PackedColorArray([green.lightened(0.15)]), PackedColorArray([green.darkened(0.05)]))
	# areia na base da costa
	for i in tops.size() - 1:
		if tops[i].y < HORIZON - 1.0 or tops[i + 1].y < HORIZON - 1.0:
			draw_line(Vector2(tops[i].x, HORIZON - 1.0), Vector2(tops[i + 1].x, HORIZON - 1.0), sand, 3.0)
	# construções e vegetação
	for p in _props:
		# +100/-100 mantém sx + offset ≡ x do objeto, para ele ficar em cima do morro certo
		var sx := fposmod(float(p["x"]) - offset + 100.0, COAST) - 100.0
		if sx < -30.0 or sx > W + 30.0:
			continue
		var base_y := HORIZON - _land(float(p["x"])) + 1.0
		var col: Color = PROP_COLORS[p["c"]]
		match p["kind"]:
			"house":
				_house(sx, base_y, col.lerp(hill, 0.45), hill)
			"palm":
				_palm(sx, base_y, hill)
			"lighthouse":
				_lighthouse(sx, base_y, hill)
			"umbrella":
				_umbrella(sx, HORIZON - 1.0, col.lerp(hill, 0.3))


func _house(x: float, y: float, roof: Color, haze: Color) -> void:
	var wall := Color(0.96, 0.94, 0.88).lerp(haze, 0.35)
	draw_rect(Rect2(x - 4.0, y - 6.0, 8.0, 6.0), wall)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 5.0, y - 6.0), Vector2(x, y - 9.5), Vector2(x + 5.0, y - 6.0)]), roof)


func _palm(x: float, y: float, haze: Color) -> void:
	var trunk := Color(0.45, 0.32, 0.22).lerp(haze, 0.4)
	var leaf := Color(0.16, 0.4, 0.24).lerp(haze, 0.4)
	var top := Vector2(x + 2.0, y - 15.0)
	draw_line(Vector2(x, y), top, trunk, 1.5, true)
	for j in 5:
		var a := lerpf(-PI * 0.95, -PI * 0.05, j / 4.0)
		draw_line(top, top + Vector2(cos(a) * 7.0, sin(a) * 7.0 + 3.0), leaf, 1.5, true)


func _lighthouse(x: float, y: float, haze: Color) -> void:
	var white := Color(0.97, 0.97, 0.95).lerp(haze, 0.3)
	var red := Color(0.85, 0.2, 0.2).lerp(haze, 0.3)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 4, y), Vector2(x + 4, y), Vector2(x + 2.5, y - 24), Vector2(x - 2.5, y - 24)]), white)
	draw_rect(Rect2(x - 3.5, y - 16.0, 7.0, 4.0), red)
	draw_rect(Rect2(x - 3.0, y - 29.0, 6.0, 5.0), red)
	var blink := 0.5 + 0.5 * sin(t * 2.0)
	draw_circle(Vector2(x, y - 27.0), 2.0 + blink, Color(1.0, 0.95, 0.6, 0.5 + 0.5 * blink))


func _umbrella(x: float, y: float, col: Color) -> void:
	draw_line(Vector2(x, y), Vector2(x, y - 5.0), Color(0.3, 0.28, 0.26), 1.0)
	var pts := PackedVector2Array()
	for i in 7:
		var a := PI + PI * i / 6.0
		pts.append(Vector2(x, y - 5.0) + Vector2(cos(a) * 4.0, sin(a) * 2.5))
	draw_colored_polygon(pts, col)
