extends Control
## Botão de som (alto-falante): clique liga/desliga todo o áudio do jogo. A tecla M faz o mesmo.
## Fica num CanvasLayer do autoload Game, então aparece em todas as telas, inclusive na pausa.

const SIZE := 44.0

var _hover := false


func _ready() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE   # não rouba o foco dos botões nem reage ao ESPAÇO
	tooltip_text = "Som (M)"
	mouse_entered.connect(func():
		_hover = true
		queue_redraw())
	mouse_exited.connect(func():
		_hover = false
		queue_redraw())


func _process(_delta: float) -> void:
	queue_redraw()   # acompanha também a tecla M


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		var sfx = get_node_or_null("/root/Sfx")
		if sfx:
			sfx.toggle_mute()
			if not sfx.muted:
				sfx.play("click")


func _draw() -> void:
	var sfx = get_node_or_null("/root/Sfx")
	var is_muted: bool = sfx != null and sfx.muted
	var c := Vector2(SIZE, SIZE) * 0.5
	var ring := Color(1.0, 0.74, 0.27) if _hover else Color(1, 1, 1, 0.35)
	draw_circle(c, SIZE * 0.5, Color(0.02, 0.08, 0.15, 0.72))
	draw_arc(c, SIZE * 0.5 - 1.0, 0.0, TAU, 40, ring, 2.0, true)
	var col := Color(0.99, 0.92, 0.76) if not is_muted else Color(0.74, 0.83, 0.88, 0.8)
	# alto-falante
	var o := c + Vector2(-6, 0)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-7, -4), o + Vector2(-2, -4), o + Vector2(5, -10),
		o + Vector2(5, 10), o + Vector2(-2, 4), o + Vector2(-7, 4)]), col)
	if is_muted:
		var x := c + Vector2(9, 0)
		var red := Color(1.0, 0.45, 0.38)
		draw_line(x + Vector2(-5, -5), x + Vector2(5, 5), red, 3.0, true)
		draw_line(x + Vector2(5, -5), x + Vector2(-5, 5), red, 3.0, true)
	else:
		draw_arc(o + Vector2(6, 0), 6.0, -0.9, 0.9, 12, col, 2.5, true)
		draw_arc(o + Vector2(6, 0), 11.0, -0.9, 0.9, 16, col, 2.5, true)
