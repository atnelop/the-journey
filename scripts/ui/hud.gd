extends Control
## HUD da partida (GDD 8): pontuação atual, recorde, contador de combo com os marcos
## de Tubo (3) e Aéreo (5), progresso da onda e mensagens temporárias.

const UiKit = preload("res://scripts/ui_kit.gd")

var score := 0
var best := 0
var combo := 0
var time_left := 180.0
var duration := 180.0
var level := 0

var _popups: Array = []
var _toast := {}
var _banner := {}
var _hint := ""
var _hint_t := 0.0
var _combo_flash := 0.0
var _panel: StyleBoxFlat
var _shadow := Color(0.02, 0.06, 0.12, 0.85)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = UiKit.box(Color(0.02, 0.08, 0.15, 0.6), Color(1, 1, 1, 0.12), 16, 2, 0)


func popup(text: String, pos: Vector2, color: Color = UiKit.SAND) -> void:
	_popups.append({"text": text, "pos": pos, "t": 0.0, "color": color})


func banner(title: String, sub: String = "", dur: float = 1.4, color: Color = UiKit.SAND) -> void:
	_banner = {"title": title, "sub": sub, "t": 0.0, "dur": dur, "color": color}


## Aviso de nível novo, abaixo da barra da onda.
func toast(title: String, sub: String, dur: float = 3.0) -> void:
	_toast = {"title": title, "sub": sub, "t": 0.0, "dur": dur}


func hint(text: String, dur: float) -> void:
	_hint = text
	_hint_t = dur


func bump_combo() -> void:
	_combo_flash = 0.35


func _process(delta: float) -> void:
	for p in _popups:
		p["t"] = p["t"] + delta
	_popups = _popups.filter(func(p): return p["t"] < 0.9)
	if not _banner.is_empty():
		_banner["t"] = _banner["t"] + delta
		if _banner["t"] >= _banner["dur"]:
			_banner = {}
	if not _toast.is_empty():
		_toast["t"] = _toast["t"] + delta
		if _toast["t"] >= _toast["dur"]:
			_toast = {}
	_hint_t -= delta
	_combo_flash -= delta
	queue_redraw()


func _draw() -> void:
	var ft: Font = Game.font_title
	var fb: Font = Game.font_body
	_draw_score(ft, fb)
	_draw_wave_bar(ft, fb)
	_draw_combo(ft, fb)
	for p in _popups:
		var k: float = p["t"] / 0.9
		var c: Color = p["color"]
		c.a = 1.0 - k
		var pos: Vector2 = p["pos"] + Vector2(-60, -60.0 * k)
		_text(ft, pos, p["text"], 30, c, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 7)
	if not _toast.is_empty():
		_draw_toast(ft, fb)
	if not _banner.is_empty():
		_draw_banner(ft, fb)
	if _hint_t > 0.0:
		var a := clampf(_hint_t, 0.0, 1.0)
		draw_rect(Rect2(0, 664, 1280, 44), Color(0.02, 0.06, 0.12, 0.45 * a))
		_text(fb, Vector2(0, 694), _hint, 22, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 0)


func _draw_score(ft: Font, fb: Font) -> void:
	draw_style_box(_panel, Rect2(24, 20, 270, 98))
	draw_string(fb, Vector2(44, 46), "PONTOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiKit.MUTED)
	_text(ft, Vector2(42, 88), UiKit.fmt(score), 40, UiKit.SAND, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 6)
	draw_string(fb, Vector2(44, 109), "RECORDE  " + UiKit.fmt(maxi(best, score)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UiKit.MUTED)


func _draw_wave_bar(ft: Font, fb: Font) -> void:
	var rect := Rect2(470, 50, 340, 14)
	draw_string(fb, Vector2(470, 42), "ONDA", HORIZONTAL_ALIGNMENT_CENTER, 340, 16, UiKit.MUTED)
	draw_style_box(UiKit.box(Color(0.02, 0.08, 0.15, 0.7), Color(1, 1, 1, 0.2), 7, 2, 0), rect.grow(3))
	var k := clampf(time_left / duration, 0.0, 1.0)
	var col := UiKit.TEAL.lerp(UiKit.CORAL, clampf(1.0 - time_left / 30.0, 0.0, 1.0))
	if k > 0.0:
		draw_style_box(UiKit.box(col, Color(0, 0, 0, 0), 6, 0, 0), Rect2(rect.position, Vector2(rect.size.x * k, rect.size.y)))
	var secs := int(ceil(time_left))
	var label := "%d:%02d" % [int(secs / 60.0), secs % 60]
	_text(ft, Vector2(470, 94), label, 24, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 340.0, 5)
	_text(fb, Vector2(470, 94), "NÍVEL %d" % (level + 1), 17, UiKit.SUN, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 4)
	# marcas de nível na barra (a cada 20 s)
	var steps := int(duration / 20.0)
	for i in range(1, steps):
		var mx := rect.position.x + rect.size.x * (1.0 - float(i) / steps)
		draw_line(Vector2(mx, rect.position.y), Vector2(mx, rect.end.y), Color(0.02, 0.08, 0.15, 0.5), 2.0)


func _draw_toast(ft: Font, fb: Font) -> void:
	var tt: float = _toast["t"]
	var dur: float = _toast["dur"]
	var a := clampf(tt / 0.2, 0.0, 1.0) * clampf((dur - tt) / 0.4, 0.0, 1.0)
	var slide := 12.0 * (1.0 - clampf(tt / 0.25, 0.0, 1.0))
	var rect := Rect2(440, 104 - slide, 400, 60)
	draw_style_box(UiKit.box(Color(0.02, 0.08, 0.15, 0.78 * a), Color(UiKit.SUN, 0.8 * a), 14, 2, 0), rect)
	_text(ft, Vector2(440, 131 - slide), _toast["title"], 24, Color(UiKit.SUN, a), HORIZONTAL_ALIGNMENT_CENTER, 400.0, 0)
	_text(fb, Vector2(440, 154 - slide), _toast["sub"], 17, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, 400.0, 0)


func _draw_combo(ft: Font, fb: Font) -> void:
	draw_style_box(_panel, Rect2(986, 20, 270, 98))
	draw_string(fb, Vector2(1006, 46), "COMBO", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiKit.MUTED)
	var pulse := maxf(_combo_flash, 0.0) / 0.35
	for i in 5:
		var c := Vector2(1022.0 + i * 49.0, 74.0)
		var milestone := UiKit.TEAL if i == 2 else (UiKit.SUN if i == 4 else Color(1, 1, 1, 0.35))
		var r := 13.0
		if i == combo - 1:
			r += 4.0 * pulse
		if i < combo:
			draw_circle(c, r, milestone if i == 2 or i == 4 else UiKit.SAND)
		else:
			draw_circle(c, r, Color(0.02, 0.06, 0.12, 0.6))
		draw_arc(c, r, 0.0, TAU, 32, milestone, 2.5, true)
	draw_string(fb, Vector2(1022.0 + 2 * 49.0 - 30.0, 109), "TUBO", HORIZONTAL_ALIGNMENT_CENTER, 60, 13, UiKit.TEAL)
	draw_string(fb, Vector2(1022.0 + 4 * 49.0 - 30.0, 109), "AÉREO", HORIZONTAL_ALIGNMENT_CENTER, 60, 13, UiKit.SUN)


func _draw_banner(ft: Font, fb: Font) -> void:
	var bt: float = _banner["t"]
	var dur: float = _banner["dur"]
	var a := clampf((dur - bt) / 0.3, 0.0, 1.0)
	var grow := 1.0 + 0.3 * (1.0 - clampf(bt / 0.15, 0.0, 1.0))
	var col: Color = _banner["color"]
	col.a = a
	var font_size := int(84.0 * grow)
	_text(ft, Vector2(0, 262), _banner["title"], font_size, col, HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 16)
	var sub: String = _banner["sub"]
	if sub != "":
		_text(ft, Vector2(0, 316), sub, 34, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 8)


func _text(font: Font, pos: Vector2, text: String, size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0, outline: int = 8) -> void:
	if outline > 0:
		var sh := _shadow
		sh.a *= color.a
		draw_string_outline(font, pos, text, align, width, size, outline, sh)
	draw_string(font, pos, text, align, width, size, color)
