extends RefCounted
## Identidade visual da interface: paleta, tema e componentes reutilizáveis.

const SAND := Color(0.99, 0.92, 0.76)
const SUN := Color(1.0, 0.74, 0.27)
const CORAL := Color(1.0, 0.45, 0.38)
const TEAL := Color(0.3, 0.88, 0.85)
const NAVY := Color(0.02, 0.07, 0.14)
const TEXT := Color(0.98, 0.97, 0.94)
const MUTED := Color(0.74, 0.83, 0.88)


static func box(bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = 14, border_w: int = 0, pad: float = 12.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(pad)
	sb.anti_aliasing = true
	return sb


static func make_theme(body_font: Font) -> Theme:
	var th := Theme.new()
	th.default_font = body_font
	th.default_font_size = 22
	th.set_stylebox("normal", "Button", box(Color(0.04, 0.18, 0.3, 0.92), TEAL.darkened(0.35), 16, 2, 14))
	th.set_stylebox("hover", "Button", box(Color(0.07, 0.3, 0.44, 0.96), SUN, 16, 3, 14))
	th.set_stylebox("pressed", "Button", box(SUN.darkened(0.1), SUN, 16, 3, 14))
	th.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), SUN.lightened(0.25), 16, 3, 14))
	th.set_stylebox("disabled", "Button", box(Color(0.08, 0.12, 0.16, 0.75), Color(0.3, 0.35, 0.4), 16, 2, 14))
	th.set_color("font_color", "Button", TEXT)
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_focus_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", NAVY)
	th.set_color("font_hover_pressed_color", "Button", NAVY)
	th.set_color("font_disabled_color", "Button", Color(0.5, 0.55, 0.6))
	th.set_stylebox("panel", "PanelContainer", box(Color(0.02, 0.08, 0.15, 0.88), Color(1, 1, 1, 0.14), 22, 2, 30))
	th.set_color("font_color", "Label", TEXT)
	return th


static func label(text: String, size: int = 22, color: Color = TEXT, font: Font = null, outline: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", NAVY)
	return l


static func button(text: String, on_press: Callable, min_w: float = 320.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 58)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(func():
		_play_click()
		on_press.call())
	return b


static func _play_click() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root.has_node("Sfx"):
		tree.root.get_node("Sfx").play("click")


## Formata pontuação com separador de milhar: 12340 -> "12.340".
static func fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
