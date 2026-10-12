extends Node2D
## Onda vista de frente (como da areia): uma parede que quebra da esquerda para a direita.
## A altura é maior perto do tubo e diminui até o "ombro", à direita.
## Aqui ficam a face e o interior do tubo (atrás do surfista).
## A cortina do lip e a espuma da parte já quebrada ficam em wave_lip.gd (na frente do surfista).

const Palette = preload("res://scripts/world/palette.gd")
const DrawUtil = preload("res://scripts/draw_util.gd")
const WATER_Y := 560.0
const CURL_X := 165.0
const CURL_X_TUBE := 392.0

var t := 0.0
var scroll := 0.0
var progress := 0.0
## 0 = tubo na posição normal; 1 = tubo avançou e envolve o surfista (evento TUBO).
var tube_k := 0.0
var tube_target := 0.0


func step(delta: float) -> void:
	t += delta
	tube_k = move_toward(tube_k, tube_target, delta * 1.6)
	queue_redraw()


func tube_amount() -> float:
	return smoothstep(0.0, 1.0, tube_k)


func curl_x() -> float:
	return lerpf(CURL_X, CURL_X_TUBE, tube_amount()) + 5.0 * sin(t * 1.2)


func height_at(x: float) -> float:
	return lerpf(250.0, 150.0, smoothstep(260.0, 1400.0, x))


func lip_y(x: float) -> float:
	var wx := x + scroll
	return WATER_Y - height_at(x) + 2.5 * sin(wx * 0.021 + t * 1.6) + 1.5 * sin(wx * 0.057 - t * 0.9)


func _curl_top() -> Vector2:
	var cx := curl_x()
	return Vector2(cx + 150.0, WATER_Y - height_at(cx))


## Borda externa do lip: sai do topo da parede, projeta-se para a frente e cai na base, à esquerda.
func curtain_outer(n: int) -> PackedVector2Array:
	var cx := curl_x()
	var hgt := height_at(cx)
	var ly := WATER_Y - hgt
	return DrawUtil.bezier(_curl_top(), Vector2(cx + 35.0, ly - 24.0), Vector2(cx - 120.0, ly + 0.1 * hgt), Vector2(cx - 118.0, WATER_Y + 4.0), n)


## Borda interna do lip (o "teto" do tubo).
func curtain_inner(n: int) -> PackedVector2Array:
	var cx := curl_x()
	var hgt := height_at(cx)
	var ly := WATER_Y - hgt
	return DrawUtil.bezier(_curl_top(), Vector2(cx + 45.0, ly + 0.22 * hgt), Vector2(cx - 80.0, ly + 0.3 * hgt), Vector2(cx - 82.0, WATER_Y + 4.0), n)


## Lado direito da boca do tubo, onde o interior escuro se funde com a face.
func _mouth_right(n: int) -> PackedVector2Array:
	var cx := curl_x()
	var hgt := height_at(cx)
	var ly := WATER_Y - hgt
	return DrawUtil.bezier(_curl_top(), Vector2(cx + 118.0, ly + 0.45 * hgt), Vector2(cx + 128.0, WATER_Y - 0.2 * hgt), Vector2(cx + 150.0, WATER_Y + 4.0), n)


func _draw() -> void:
	var pal := Palette.at(progress)
	var face: Color = pal["face"]
	var light: Color = pal["face_light"]
	var deep: Color = pal["deep"]
	var foam: Color = pal["foam"]
	var cx := curl_x()
	var x0 := cx - 70.0

	# face em duas faixas de gradiente: topo translúcido (luz atravessando) e corpo mais escuro
	var tops := PackedVector2Array()
	var mids := PackedVector2Array()
	var bots := PackedVector2Array()
	var c_top := PackedColorArray()
	var c_mid := PackedColorArray()
	var lip_cols := PackedColorArray()
	var x := x0
	while x <= 1300.0:
		var ly := lip_y(x)
		var hgt := WATER_Y - ly
		tops.append(Vector2(x, ly))
		mids.append(Vector2(x, ly + hgt * 0.32))
		bots.append(Vector2(x, WATER_Y + 6.0))
		var near := 1.0 - smoothstep(cx, cx + 520.0, x)
		c_top.append(light.lerp(face, 0.1 + 0.35 * near))
		c_mid.append(face.lerp(deep, 0.1 + 0.25 * near))
		lip_cols.append(Color(foam, 0.25 + 0.65 * (1.0 - smoothstep(cx + 150.0, 1250.0, x))))
		x += 16.0
	DrawUtil.strip(self, tops, mids, c_top, c_mid)
	DrawUtil.strip(self, mids, bots, c_mid, PackedColorArray([deep]))

	# brilho logo abaixo da crista
	var glow := PackedVector2Array()
	for p in tops:
		glow.append(p + Vector2(0, 16))
	DrawUtil.strip(self, tops, glow, PackedColorArray([Color(light.lightened(0.25), 0.5)]), PackedColorArray([Color(light, 0.0)]))

	# riscos na face, correndo para a esquerda (mostram o avanço do surfista)
	for i in 24:
		var f := 0.1 + 0.82 * fposmod(i * 0.37, 1.0)
		var length := 60.0 + fposmod(i * 53.0, 150.0)
		var sx := fposmod(i * 197.0 - scroll * 0.9, 1750.0) - 220.0
		var pts := PackedVector2Array()
		for q in 7:
			var px := sx + length * q / 6.0
			if px < x0 + 40.0 or px > 1300.0:
				continue
			var ly := lip_y(px)
			pts.append(Vector2(px, ly + f * (WATER_Y - ly)))
		if pts.size() >= 2:
			draw_polyline(pts, Color(1, 1, 1, 0.13 * (1.0 - f * 0.6)), 2.0, true)

	# borda da crista
	draw_polyline_colors(tops, lip_cols, 3.0, true)

	# interior do tubo: escuro lá dentro, clareando na abertura
	var n := 18
	var inner := curtain_inner(n)
	var right := _mouth_right(n)
	var c_in := PackedColorArray()
	var c_out := PackedColorArray()
	for q in n:
		var s := float(q) / (n - 1)
		c_in.append(deep.darkened(0.45).lerp(deep, s * 0.4))
		c_out.append(Color(face.lerp(deep, 0.3), 0.0))
	DrawUtil.strip(self, inner, right, c_in, c_out)

	# borbulhas na base da parede
	for i in 14:
		var bx := fposmod(i * 131.0 - scroll * 0.95, 1500.0) - 100.0
		if bx < cx + 120.0:
			continue
		draw_colored_polygon(DrawUtil.ellipse(Vector2(bx, WATER_Y - 5.0), 14.0 + (i % 3) * 6.0, 3.0, 14), Color(foam, 0.35))
