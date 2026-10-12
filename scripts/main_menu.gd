extends Control
## Menu principal (GDD 8): título THE JOURNEY, Jogar e Sair, sobre a onda em modo demonstração.

const UiKit = preload("res://scripts/ui_kit.gd")
const WorldScript = preload("res://scripts/world/world.gd")

var world
var _jump_t := 2.0


func _ready() -> void:
	theme = Game.get_theme()
	world = WorldScript.new()
	world.speed = 240.0
	world.progress = 0.42
	add_child(world)

	# véu escuro à direita para dar contraste ao texto
	var grad := Gradient.new()
	grad.set_color(0, Color(0.02, 0.06, 0.12, 0.0))
	grad.set_color(1, Color(0.02, 0.06, 0.12, 0.75))
	grad.set_offset(0, 0.35)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 256
	tex.height = 4
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(1, 0)
	var veil := TextureRect.new()
	veil.texture = tex
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	veil.stretch_mode = TextureRect.STRETCH_SCALE
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veil)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 600)
	margin.add_theme_constant_override("margin_right", 50)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)

	col.add_child(UiKit.label("The Journey", 96, UiKit.SAND, Game.font_display, 16))
	col.add_child(UiKit.label("uma sessão de surfe arcade", 26, UiKit.SUN, Game.font_body, 6))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 26)
	col.add_child(gap)
	var play := UiKit.button("Jogar", func(): Game.goto("intro"))
	col.add_child(play)
	col.add_child(UiKit.button("Personalizar surfista", func(): Game.goto("customize")))
	col.add_child(UiKit.button("Sair", func(): get_tree().quit()))
	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 14)
	col.add_child(gap2)
	if Game.best_score > 0:
		col.add_child(UiKit.label("Recorde: %s" % UiKit.fmt(Game.best_score), 24, UiKit.TEAL, Game.font_title, 6))
	else:
		col.add_child(UiKit.label("Salte as pessoas, faça combos e sobreviva à onda!", 20, UiKit.TEXT, null, 5))
	col.add_child(UiKit.label("ESPAÇO saltar   ·   ESC pausar   ·   M som", 18, UiKit.MUTED, null, 4))

	var credits := UiKit.label("Henrique M. de Medeiros & Igor S. Perrot  ·  IFSC 2026", 15, UiKit.MUTED, null, 4)
	credits.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	credits.position = Vector2(1280 - 470, 720 - 34)
	credits.size = Vector2(450, 24)
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(credits)

	play.grab_focus()


func _process(delta: float) -> void:
	world.advance(delta)
	_jump_t -= delta
	if _jump_t <= 0.0:
		world.surfer.request_jump()
		_jump_t = randf_range(2.2, 4.0)
