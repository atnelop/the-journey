extends Node
## Autoload "Game": recorde salvo, mapa de controles, fontes/tema e troca de telas com fade.

const UiKit = preload("res://scripts/ui_kit.gd")
const SurferLook = preload("res://scripts/surfer_look.gd")
const SAVE_PATH := "user://the_journey.cfg"
const SCENES := {
	"menu": "res://scenes/main_menu.tscn",
	"customize": "res://scenes/customize.tscn",
	"intro": "res://scenes/intro.tscn",
	"game": "res://scenes/game.tscn",
}

var best_score := 0
var start_muted := false
## Visual do surfista (índices de surfer_look.gd).
var look: Dictionary = SurferLook.DEFAULT.duplicate()
## Pacifico: títulos com cara de surf retrô ("The Journey", "Let's Surf!", "Tubo!").
var font_display: Font
## Fredoka negrito: números e destaques (pontos, tempo, +100).
var font_title: Font
## Fredoka seminegrito: textos e botões.
var font_body: Font
var debug_log := false

var _theme: Theme
var _fade: ColorRect
var _changing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_setup_fonts()
	_build_fade()
	_load()
	_build_mute_button()
	if "--smoke-test" in OS.get_cmdline_user_args():
		debug_log = true
		add_child(load("res://tools/smoke_test.gd").new())


# --- Controles (GDD 5.5): Espaço salta, Enter/clique confirma, Esc pausa ---

func _setup_input() -> void:
	_bind("jump", [KEY_SPACE, KEY_UP, KEY_W], [JOY_BUTTON_A])
	_bind("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])
	_bind("mute", [KEY_M], [])


func _bind(action: String, keys: Array, buttons: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	for b in buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = b
		InputMap.action_add_event(action, jb)


# --- Fontes e tema ---

## As fontes ficam embutidas no projeto (assets/fonts, licença OFL), então o visual é o mesmo em qualquer PC.
func _setup_fonts() -> void:
	font_display = load("res://assets/fonts/Pacifico-Regular.ttf")
	var fredoka: Font = load("res://assets/fonts/Fredoka.ttf")
	font_title = _weight(fredoka, 700)
	font_body = _weight(fredoka, 560)


func _weight(base: Font, wght: int) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = base
	fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): wght}
	return fv


func get_theme() -> Theme:
	if _theme == null:
		_theme = UiKit.make_theme(font_body)
	return _theme


# --- Navegação entre telas ---

func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.02, 0.06, 0.12, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


## Botão de som no canto inferior esquerdo, por cima de todas as telas (inclusive na pausa).
func _build_mute_button() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	var btn: Control = load("res://scripts/ui/mute_button.gd").new()
	btn.position = Vector2(16, 660)
	layer.add_child(btn)


func goto(key: String) -> void:
	if _changing:
		return
	_changing = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.18)
	tw.tween_callback(func():
		get_tree().paused = false
		get_tree().change_scene_to_file(SCENES[key]))
	tw.tween_property(_fade, "color:a", 0.0, 0.25)
	tw.tween_callback(func():
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_changing = false)


# --- Recorde (escopo ideal: registro da melhor pontuação) ---

func submit_score(score: int) -> bool:
	if score > best_score:
		best_score = score
		_save()
		return true
	return false


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_score = int(cfg.get_value("score", "best", 0))
		start_muted = bool(cfg.get_value("audio", "muted", false))
		look = SurferLook.sanitize(cfg.get_value("surfer", "look", {}))


func save_settings() -> void:
	_save()


func set_look(new_look: Dictionary) -> void:
	look = SurferLook.sanitize(new_look)
	_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", best_score)
	cfg.set_value("audio", "muted", Sfx.muted)
	cfg.set_value("surfer", "look", look)
	cfg.save(SAVE_PATH)
