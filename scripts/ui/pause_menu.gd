extends Control
## Menu de pausa (escopo ideal). Só processa com a árvore pausada.

signal resumed
signal restart_requested
signal menu_requested

const UiKit = preload("res://scripts/ui_kit.gd")

var _first: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Game.get_theme()
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.04, 0.09, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)
	col.add_child(UiKit.label("Pausado", 60, UiKit.SAND, Game.font_display, 10))
	col.add_child(UiKit.label("ESPAÇO saltar  ·  ESC continuar  ·  M som", 18, UiKit.MUTED))
	_first = UiKit.button("Continuar", func(): resumed.emit())
	col.add_child(_first)
	col.add_child(UiKit.button("Reiniciar sessão", func(): restart_requested.emit()))
	col.add_child(UiKit.button("Menu principal", func(): menu_requested.emit()))
	hide()


func open() -> void:
	show()
	_first.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		resumed.emit()
