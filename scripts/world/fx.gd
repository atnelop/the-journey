extends Node2D
## Partículas simples (spray e respingos), desenhadas como círculos.

const MAX_PARTICLES := 700
const GRAVITY := 900.0

var _parts: Array = []


func emit(pos: Vector2, vel: Vector2, count: int, spread: float, col: Color, size: float, life: float) -> void:
	for i in count:
		if _parts.size() >= MAX_PARTICLES:
			return
		var v := vel.rotated(randf_range(-spread, spread)) * randf_range(0.6, 1.2)
		var l := life * randf_range(0.6, 1.0)
		_parts.append({
			"p": pos + Vector2(randf_range(-6, 6), randf_range(-3, 3)),
			"v": v,
			"life": l,
			"max": l,
			"r": size * randf_range(0.6, 1.3),
			"c": col,
		})


func splash(pos: Vector2, count: int, power: float) -> void:
	emit(pos, Vector2(0, -260.0 * power), count, 1.0, Color(0.96, 0.99, 1.0, 0.95), 4.0, 0.7)


func step(delta: float) -> void:
	for p in _parts:
		var v: Vector2 = p["v"]
		v.y += GRAVITY * delta
		p["v"] = v
		p["p"] = p["p"] + v * delta
		p["life"] = p["life"] - delta
	_parts = _parts.filter(func(p): return p["life"] > 0.0)
	queue_redraw()


func _draw() -> void:
	for p in _parts:
		var k: float = p["life"] / p["max"]
		var c: Color = p["c"]
		c.a *= k
		draw_circle(p["p"], p["r"] * (0.5 + 0.5 * k), c)
