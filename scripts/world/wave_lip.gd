extends Node2D
## Frente da onda (desenhada na frente do surfista):
## a espuma da seção que já quebrou e a cortina do lip que se projeta para a frente formando o tubo.
## Onde o lip cai, a água explode em espuma que ferve, sobe e é levada pelo vento.

const Palette = preload("res://scripts/world/palette.gd")
const DrawUtil = preload("res://scripts/draw_util.gd")
const WATER_Y := 560.0

var wave


func _draw() -> void:
	if wave == null:
		return
	var pal := Palette.at(wave.progress)
	var lip: Color = pal["lip"]
	var light: Color = pal["face_light"]
	var foam: Color = pal["foam"]
	var t: float = wave.t
	var cx: float = wave.curl_x()
	var hgt: float = wave.height_at(cx)
	var ly := WATER_Y - hgt
	var shade := foam.lerp(pal["deep"], 0.2)
	var shade_deep := foam.lerp(pal["deep"], 0.38)
	var end_x := cx - 95.0

	# --- massa de espuma da seção quebrada: mais alta perto da quebra ---
	var tops := PackedVector2Array()
	var bots := PackedVector2Array()
	var x := -40.0
	while x <= end_x:
		tops.append(Vector2(x, _mass_top(x, cx, hgt, t)))
		bots.append(Vector2(x, WATER_Y + 6.0))
		x += 12.0
	DrawUtil.strip(self, tops, bots, PackedColorArray([foam]), PackedColorArray([Color(shade_deep, 0.97)]))
	# textura interna: bolhas sombreadas que fervem dentro da massa
	for i in 34:
		var ph := fposmod(t * (0.3 + 0.03 * (i % 7)) + i * 0.618, 1.0)
		var bx := end_x - 10.0 - fposmod(i * 53.0, end_x + 40.0)
		var top := _mass_top(bx, cx, hgt, t)
		var by := lerpf(WATER_Y - 14.0, top + 26.0, fposmod(i * 0.37, 1.0)) - ph * 22.0
		var r := (12.0 + 18.0 * ph) * (0.8 + 0.4 * smoothstep(cx - 460.0, cx - 120.0, bx))
		var a := sin(PI * ph)
		draw_circle(Vector2(bx - ph * 10.0, by + 6.0), r, Color(shade_deep, 0.55 * a))
		draw_circle(Vector2(bx - ph * 10.0 - 2.0, by), r * 0.85, Color(foam, 0.8 * a))
	# contorno de cima em "couve-flor": duas camadas de bolhas
	for i in tops.size():
		var p := tops[i]
		var k := smoothstep(cx - 460.0, cx - 120.0, p.x)
		var r := 15.0 + 13.0 * k + 6.0 * sin(t * 2.5 + i * 1.9)
		draw_circle(p + Vector2(5, 10), r, shade)
		draw_circle(p + Vector2(0, 2), r * 0.9, foam)
	for i in range(0, tops.size(), 3):
		var p := tops[i]
		draw_circle(p + Vector2(-6, -4 - 4.0 * sin(t * 3.0 + i)), 9.0 + 4.0 * sin(t * 4.0 + i), foam.lightened(0.05))

	# --- cortina do lip ---
	var n := 26
	var outer: PackedVector2Array = wave.curtain_outer(n)
	var inner: PackedVector2Array = wave.curtain_inner(n)
	var ca := PackedColorArray()
	var cb := PackedColorArray()
	for q in n:
		var s := float(q) / (n - 1)
		ca.append(Color(lip.lerp(foam, smoothstep(0.4, 1.0, s)), 0.96))
		cb.append(Color(light.lerp(foam, smoothstep(0.5, 1.0, s)), 0.8 + 0.15 * s))
	DrawUtil.strip(self, outer, inner, ca, cb)
	draw_polyline(inner, Color(1, 1, 1, 0.3), 2.0, true)
	draw_polyline(outer.slice(0, 12), foam, 5.0, true)
	for q in range(2, 10, 2):
		var wob := Vector2(sin(t * 6.0 + q), cos(t * 5.0 + q * 1.3)) * 2.5
		draw_circle(outer[q] + wob, 3.5 + 2.0 * sin(t * 7.0 + q), foam)

	# --- explosão: a parte de trás do lip arrebenta e a espuma sobe acima da crista ---
	for i in 36:
		var ph := fposmod(t * (0.55 + 0.04 * (i % 5)) + i * 0.381, 1.0)
		var s := 0.22 + 0.78 * fposmod(i * 0.618, 1.0)
		var base := outer[int(s * (n - 1))] + Vector2(-16.0, 0.0)
		var p := base + Vector2(-26.0 * ph, -(36.0 + 46.0 * (1.0 - s)) * ph)
		var r := 16.0 + 24.0 * ph + 8.0 * s
		var a := 1.0 - ph * ph
		draw_circle(p + Vector2(5, 9), r, Color(shade, 0.9 * a))
		draw_circle(p, r * 0.9, Color(foam, a))
	# miolo fixo da bola de espuma (garante que a parte de trás e a queda do lip fiquem cobertas)
	for j in 16:
		var s := 0.26 + 0.74 * j / 15.0
		var p := outer[int(s * (n - 1))] + Vector2(-12.0 + 6.0 * sin(t * 3.0 + j), 4.0 * cos(t * 2.6 + j * 1.7))
		var r := 24.0 + 8.0 * sin(t * 4.0 + j * 1.3) + 8.0 * s
		draw_circle(p + Vector2(5, 9), r, shade)
		draw_circle(p, r * 0.92, foam)
	# ponte de espuma: fecha o "vale" entre a massa da quebra e a bola de espuma do tubo
	for j in 8:
		var px := lerpf(cx - 190.0, cx - 5.0, j / 7.0)
		var py := ly - 4.0 - 16.0 * sin(PI * j / 7.0) + 5.0 * sin(t * 2.4 + j * 1.9)
		var r := 30.0 + 6.0 * sin(t * 3.1 + j * 1.3)
		draw_circle(Vector2(px + 5.0, py + 10.0), r, shade)
		draw_circle(Vector2(px, py), r * 0.92, foam)
	for j in 7:
		var px := lerpf(cx - 175.0, cx - 20.0, j / 6.0) + 6.0 * sin(t * 1.7 + j)
		var py := ly - 34.0 - 12.0 * sin(PI * j / 6.0) - 6.0 * absf(sin(t * 2.8 + j * 1.4))
		var r := 17.0 + 5.0 * sin(t * 4.2 + j * 2.1)
		draw_circle(Vector2(px + 4.0, py + 7.0), r, shade)
		draw_circle(Vector2(px, py), r * 0.9, foam)
	# crista de espuma por cima da parte de trás do lip (onde ele começa a arrebentar)
	for j in 9:
		var p := outer[4 + j] + Vector2(-8.0, -10.0 - 6.0 * absf(sin(t * 3.4 + j * 1.1)))
		var r := 13.0 + 5.0 * sin(t * 5.0 + j * 1.7)
		draw_circle(p + Vector2(4, 7), r, shade)
		draw_circle(p, r * 0.9, foam)

	# explosão onde o lip bate na base
	var land := outer[n - 1].lerp(inner[n - 1], 0.5)
	for i in 14:
		var ph := fposmod(t * 0.9 + i * 0.29, 1.0)
		var ang := -PI * (0.08 + 0.84 * fposmod(i * 0.618, 1.0))
		var p := land + Vector2.from_angle(ang) * (14.0 + 50.0 * ph)
		var r := 10.0 + 14.0 * ph
		draw_circle(p + Vector2(3, 6), r, Color(shade, 1.0 - ph))
		draw_circle(p, r * 0.9, Color(foam, 1.0 - ph * 0.8))
	draw_circle(land + Vector2(0, -10), 26.0, foam)

	# névoa: spray fino levado pelo vento por cima de tudo
	for i in 14:
		var ph := fposmod(t * 0.22 + i * 0.137, 1.0)
		var px := cx - 40.0 - ph * 420.0 + 20.0 * sin(i * 2.7)
		var py := ly + 10.0 - 70.0 * ph - 30.0 * sin(i * 1.9)
		var r := 26.0 + 40.0 * ph
		draw_circle(Vector2(px, py), r, Color(1, 1, 1, 0.22 * sin(PI * ph)))


func _mass_top(x: float, cx: float, hgt: float, t: float) -> float:
	var k := smoothstep(cx - 460.0, cx - 120.0, x)
	return WATER_Y - hgt * (0.62 + 0.5 * k) - 7.0 * sin(x * 0.05 + t * 3.0) - 4.0 * sin(x * 0.13 - t * 2.0)
