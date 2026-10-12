extends RefCounted
## Utilitários de desenho procedural (todas as artes do jogo são desenhadas por código).


## Preenche a faixa entre duas linhas (mesmo número de pontos) com gradiente por vértice.
## Usa triângulos diretos, então funciona mesmo com formas côncavas ou curvas.
static func strip(ci: CanvasItem, a: PackedVector2Array, b: PackedVector2Array, ca: PackedColorArray, cb: PackedColorArray) -> void:
	var n := mini(a.size(), b.size())
	if n < 2:
		return
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	pts.resize(n * 2)
	cols.resize(n * 2)
	for i in n:
		pts[i * 2] = a[i]
		pts[i * 2 + 1] = b[i]
		cols[i * 2] = ca[i] if ca.size() == n else ca[0]
		cols[i * 2 + 1] = cb[i] if cb.size() == n else cb[0]
	for i in n - 1:
		var k := i * 2
		idx.append(k)
		idx.append(k + 1)
		idx.append(k + 2)
		idx.append(k + 1)
		idx.append(k + 3)
		idx.append(k + 2)
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, pts, cols)


static func ellipse(c: Vector2, rx: float, ry: float, n: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var ang := TAU * float(i) / n
		pts.append(c + Vector2(cos(ang) * rx, sin(ang) * ry))
	return pts


static func bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		pts.append(p0.bezier_interpolate(p1, p2, p3, float(i) / (n - 1)))
	return pts


## Desenha uma linha com pontas arredondadas (membros dos personagens).
static func limb(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	ci.draw_line(a, b, col, w, true)
	ci.draw_circle(a, w * 0.5, col)
	ci.draw_circle(b, w * 0.5, col)
