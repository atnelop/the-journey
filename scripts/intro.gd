extends Control
## Abertura: ao clicar em Jogar, toca o vídeo de surfe (sem o áudio original; só a música do jogo),
## com a frase "LET'S SURF!" e uma fanfarra de cornetas. Quando o vídeo acaba, começa a partida.
## ESPAÇO, ENTER, ESC ou clique pulam a abertura.

const UiKit = preload("res://scripts/ui_kit.gd")
const VIDEO_PATH := "res://assets/intro.ogv"
const VIDEO_RATIO := 600.0 / 460.0
const SKIP_DELAY := 0.6   # evita pular sem querer com a mesma tecla que apertou "Jogar"
const MAX_TIME := 10.0

var _player: VideoStreamPlayer
var _title
var _t := 0.0
var _done := false


func _ready() -> void:
	theme = Game.get_theme()
	var bg := ColorRect.new()
	bg.color = UiKit.NAVY
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	if ResourceLoader.exists(VIDEO_PATH):
		var frame := AspectRatioContainer.new()
		frame.ratio = VIDEO_RATIO
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.offset_left = 40.0
		frame.offset_top = 28.0
		frame.offset_right = -40.0
		frame.offset_bottom = -150.0
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(frame)
		_player = VideoStreamPlayer.new()
		_player.stream = load(VIDEO_PATH)
		_player.expand = true
		_player.volume_db = -80.0
		_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(_player)
		_player.finished.connect(_finish)
		_player.play()

	_title = TitleText.new()
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)

	var hint := UiKit.label("ESPAÇO para pular", 16, UiKit.MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.position = Vector2(1280 - 230, 720 - 32)
	hint.size = Vector2(210, 24)
	add_child(hint)

	Sfx.play("fanfare")


func _process(delta: float) -> void:
	_t += delta
	_title.t = _t
	_title.queue_redraw()
	var skip := Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("pause")
	if (_t >= SKIP_DELAY and skip) or _t >= MAX_TIME or (_player == null and _t >= 3.0):
		_finish()


func _gui_input(event: InputEvent) -> void:
	if _t >= SKIP_DELAY and event is InputEventMouseButton and event.pressed:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	Game.goto("game")


## "Let's Surf!" em Pacifico: entra com um "pop" e depois balança como uma prancha na onda.
## (fonte script tem letras emendadas, por isso a palavra anima inteira, sem separar as letras)
class TitleText extends Control:
	const TEXT := "Let's Surf!"
	const SIZE := 86
	const CENTER := Vector2(640.0, 640.0)
	const SUN := Color(1.0, 0.74, 0.27)
	const NAVY := Color(0.02, 0.07, 0.14)
	var t := 0.0

	func _draw() -> void:
		var k := clampf((t - 0.25) / 0.45, 0.0, 1.0)
		if k <= 0.0:
			return
		var font: Font = Game.font_display
		var text_size := font.get_string_size(TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE)
		# escala com "passo do ponto" (back-out) e balanço suave depois de entrar
		var c1 := 1.70158
		var pop := 1.0 + (c1 + 1.0) * pow(k - 1.0, 3.0) + c1 * pow(k - 1.0, 2.0)
		var sway := sin(t * 2.6) * 0.035 * k
		var bob := sin(t * 3.2) * 4.0 * k
		draw_set_transform(CENTER + Vector2(0, bob), -0.06 + sway, Vector2.ONE * maxf(pop, 0.01))
		var pos := Vector2(-text_size.x * 0.5, text_size.y * 0.25)
		draw_string_outline(font, pos, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, 18, Color(NAVY, k))
		draw_string(font, pos, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Color(SUN, k))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
