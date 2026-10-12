extends Control
## Personalizar surfista: cor da pele, cabelo (estilo e cor), barba, lycra, bermuda e prancha.
## Pré-visualização ao vivo; a escolha fica salva e vale no menu e na partida.

const UiKit = preload("res://scripts/ui_kit.gd")
const SurferLook = preload("res://scripts/surfer_look.gd")
const WorldScript = preload("res://scripts/world/world.gd")
const SurferScene = preload("res://scenes/surfer.tscn")

var world
var preview_surfer
var _rows: VBoxContainer
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	theme = Game.get_theme()
	_rng.randomize()
	world = WorldScript.new()
	world.speed = 200.0
	world.progress = 0.42
	add_child(world)
	var veil := ColorRect.new()
	veil.color = Color(0.01, 0.04, 0.09, 0.55)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var title := UiKit.label("Seu surfista", 62, UiKit.SAND, Game.font_display, 12)
	title.position = Vector2(0, 6)
	title.size = Vector2(1280, 104)
	add_child(title)

	# pré-visualização grande
	var card := PreviewCard.new()
	card.position = Vector2(60, 122)
	card.size = Vector2(440, 500)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	var holder := Node2D.new()
	holder.position = Vector2(220, 400)
	holder.scale = Vector2(3.0, 3.0)
	card.add_child(holder)
	preview_surfer = SurferScene.instantiate()
	preview_surfer.preview = true
	holder.add_child(preview_surfer)

	# opções
	var panel := PanelContainer.new()
	panel.position = Vector2(536, 122)
	panel.size = Vector2(684, 500)
	add_child(panel)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 12)
	_rows.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(_rows)
	_build_rows()

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 20)
	bar.position = Vector2(390, 642)
	add_child(bar)
	bar.add_child(UiKit.button("Aleatório", _randomize, 240.0))
	var back := UiKit.button("Voltar", func(): Game.goto("menu"), 240.0)
	bar.add_child(back)
	back.grab_focus()


func _process(delta: float) -> void:
	world.advance(delta)
	preview_surfer.step(delta)


func _build_rows() -> void:
	for c in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()
	_add_colors("Cor da pele", "skin", SurferLook.SKINS)
	_add_options("Cabelo", "hair_style", SurferLook.HAIR_STYLES)
	_add_colors("Cor do cabelo", "hair_color", SurferLook.HAIR_COLORS)
	_add_options("Barba", "beard", SurferLook.BEARDS)
	_add_colors("Lycra", "top", SurferLook.CLOTHES)
	_add_colors("Bermuda", "shorts", SurferLook.CLOTHES)
	_add_colors("Prancha", "board", SurferLook.BOARDS)


func _row(title: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 7)
	var l := UiKit.label(title, 22, UiKit.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.custom_minimum_size = Vector2(186, 0)
	h.add_child(l)
	_rows.add_child(h)
	return h


func _add_colors(title: String, key: String, colors: Array) -> void:
	var h := _row(title)
	var group := ButtonGroup.new()
	for i in colors.size():
		var b := _swatch(colors[i])
		b.button_group = group
		b.button_pressed = int(Game.look[key]) == i
		b.pressed.connect(_set_option.bind(key, i))
		h.add_child(b)


func _add_options(title: String, key: String, options: Array) -> void:
	var h := _row(title)
	var name_label := UiKit.label(options[int(Game.look[key])], 22, UiKit.SAND)
	name_label.custom_minimum_size = Vector2(170, 0)
	var left := _arrow("<")
	var right := _arrow(">")
	left.pressed.connect(func(): _cycle(key, options, -1, name_label))
	right.pressed.connect(func(): _cycle(key, options, 1, name_label))
	h.add_child(left)
	h.add_child(name_label)
	h.add_child(right)


func _cycle(key: String, options: Array, dir: int, label: Label) -> void:
	var i := posmod(int(Game.look[key]) + dir, options.size())
	label.text = options[i]
	_set_option(key, i)


func _set_option(key: String, value: int) -> void:
	var look := Game.look.duplicate()
	look[key] = value
	Game.set_look(look)
	_apply()
	Sfx.play("click")


func _randomize() -> void:
	Game.set_look(SurferLook.random(_rng))
	_apply()
	_build_rows()


func _apply() -> void:
	preview_surfer.apply_look(Game.look)
	world.surfer.apply_look(Game.look)


func _swatch(color: Color) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(38, 38)
	b.add_theme_stylebox_override("normal", UiKit.box(color, Color(1, 1, 1, 0.3), 19, 2, 0))
	b.add_theme_stylebox_override("hover", UiKit.box(color.lightened(0.08), Color(1, 1, 1, 0.85), 19, 3, 0))
	var selected := UiKit.box(color, UiKit.SUN, 19, 4, 0)
	b.add_theme_stylebox_override("pressed", selected)
	b.add_theme_stylebox_override("hover_pressed", selected)
	b.add_theme_stylebox_override("focus", UiKit.box(Color(0, 0, 0, 0), Color.WHITE, 19, 2, 0))
	return b


func _arrow(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(44, 40)
	b.add_theme_font_size_override("font_size", 22)
	return b


## Cartão da pré-visualização: céu, sol e mar, com o surfista em escala grande por cima.
class PreviewCard extends Control:
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var sky_top := Color(0.33, 0.6, 0.9)
		var sky_bot := Color(0.98, 0.85, 0.65)
		var sea_top := Color(0.12, 0.5, 0.64)
		var sea_bot := Color(0.04, 0.22, 0.36)
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, 360), Vector2(0, 360)]),
			PackedColorArray([sky_top, sky_top, sky_bot, sky_bot]))
		for i in 4:
			draw_circle(Vector2(w - 90, 90), 34.0 + i * 18.0, Color(1, 0.95, 0.75, 0.08))
		draw_circle(Vector2(w - 90, 90), 32.0, Color(1, 0.96, 0.82))
		draw_polygon(PackedVector2Array([Vector2(0, 360), Vector2(w, 360), Vector2(w, size.y), Vector2(0, size.y)]),
			PackedColorArray([sea_top, sea_top, sea_bot, sea_bot]))
		var line := PackedVector2Array()
		var x := 0.0
		while x <= w:
			line.append(Vector2(x, 402.0 + 3.0 * sin(x * 0.04 + t * 2.0)))
			x += 10.0
		draw_polyline(line, Color(1, 1, 1, 0.7), 3.0, true)
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.25), false, 2.0)
