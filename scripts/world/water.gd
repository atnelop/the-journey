extends Node2D
## Primeiro plano: a água rasa na frente da onda (cobre a parte submersa das pessoas e da prancha)
## e a faixa de areia onde a câmera "está". Os riscos de espuma correm para a esquerda e mostram o avanço.

const Palette = preload("res://scripts/world/palette.gd")
const DrawUtil = preload("res://scripts/draw_util.gd")
const WATER_Y := 560.0
const SAND_Y := 688.0

var scroll := 0.0
var progress := 0.0
var t := 0.0
var curl_x := 165.0


func step(delta: float) -> void:
	t += delta
	queue_redraw()


func surface_y(x: float) -> float:
	return WATER_Y + 2.5 * sin((x + scroll) * 0.03 + t * 1.5)


func _draw() -> void:
	var pal := Palette.at(progress)
	var sea: Color = pal["sea_near"]
	var deep: Color = pal["deep"]
	var foam: Color = pal["foam"]
	var light: Color = pal["face_light"]
	var sand: Color = pal["sand"]

	var tops := PackedVector2Array()
	var bots := PackedVector2Array()
	var x := -20.0
	while x <= 1300.0:
		tops.append(Vector2(x, surface_y(x)))
		bots.append(Vector2(x, SAND_Y + 6.0))
		x += 20.0
	DrawUtil.strip(self, tops, bots, PackedColorArray([Color(sea.lerp(light, 0.2), 0.66)]), PackedColorArray([Color(deep.lerp(light, 0.3), 0.97)]))
	draw_polyline(tops, Color(1, 1, 1, 0.5), 2.5, true)

	# riscos de espuma (movem na velocidade do mundo)
	for i in 16:
		var row := i % 5
		var y := WATER_Y + 18.0 + row * 23.0
		var speed_f := 1.0 + row * 0.12
		var sx := fposmod(i * 151.0 - scroll * speed_f, 1500.0) - 110.0
		var length := 30.0 + (i % 4) * 22.0
		draw_line(Vector2(sx, y), Vector2(sx + length, y), Color(foam, 0.16 + 0.03 * row), 3.0, true)

	# espuma da quebra espalhando na água rasa (fica para trás e vai sumindo à esquerda)
	var edge := curl_x - 70.0
	var band_top := PackedVector2Array()
	var band_bot := PackedVector2Array()
	x = -40.0
	while x <= edge:
		var k := smoothstep(-40.0, edge, x)
		band_top.append(Vector2(x, WATER_Y - 2.0))
		band_bot.append(Vector2(x, WATER_Y + 10.0 + 26.0 * (1.0 - k) + 6.0 * sin(x * 0.07 + t * 2.0)))
		x += 14.0
	DrawUtil.strip(self, band_top, band_bot, PackedColorArray([Color(foam, 0.95)]), PackedColorArray([Color(foam, 0.55)]))
	for i in 18:
		var px := -30.0 + i * (edge + 30.0) / 17.0
		var r := 10.0 + 5.0 * sin(t * 3.0 + i * 1.3)
		draw_circle(Vector2(px, WATER_Y + 1.0 + 3.0 * sin(t * 2.2 + i)), r, foam)
	for i in 22:
		var row := i % 4
		var px := fposmod(i * 97.0 - scroll * (1.0 + row * 0.1), edge + 260.0) - 120.0
		if px > edge:
			continue
		var fade := clampf((px + 120.0) / (edge + 120.0), 0.0, 1.0)
		var py := WATER_Y + 16.0 + row * 22.0
		var e := DrawUtil.ellipse(Vector2(px, py), 22.0 + row * 8.0, 3.5 + row, 16)
		draw_colored_polygon(e, Color(foam, 0.45 * fade))

	# areia em primeiro plano com a espuma que vai e volta
	var wash := 6.0 * sin(t * 0.9)
	var sand_tops := PackedVector2Array()
	var sand_bots := PackedVector2Array()
	var foam_line := PackedVector2Array()
	x = -20.0
	while x <= 1300.0:
		var wx := x + scroll * 1.25
		var y := SAND_Y + wash + 3.0 * sin(wx * 0.013) + 2.0 * sin(wx * 0.041)
		sand_tops.append(Vector2(x, y))
		sand_bots.append(Vector2(x, 720.0))
		foam_line.append(Vector2(x, y - 1.0))
		x += 20.0
	DrawUtil.strip(self, sand_tops, sand_bots, PackedColorArray([sand.darkened(0.22)]), PackedColorArray([sand]))
	draw_polyline(foam_line, Color(foam, 0.9), 4.0, true)
	for i in 12:
		var bx := fposmod(i * 113.0 - scroll * 1.25, 1400.0) - 60.0
		draw_circle(Vector2(bx, SAND_Y + wash + 1.0), 3.0 + (i % 3), Color(foam, 0.8))
