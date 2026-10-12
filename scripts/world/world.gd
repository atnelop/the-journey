extends Node2D
## Monta as camadas da cena, de trás para a frente:
## céu/praia/mar -> corpo da onda -> pessoas -> surfista -> lip da onda -> água da frente -> partículas.
## Usado tanto pela partida quanto pelo menu (modo de demonstração).

const WATER_Y := 560.0
const Background = preload("res://scripts/world/background.gd")
const Wave = preload("res://scripts/world/wave.gd")
const WaveLip = preload("res://scripts/world/wave_lip.gd")
const Water = preload("res://scripts/world/water.gd")
const Fx = preload("res://scripts/world/fx.gd")
const SurferScene = preload("res://scenes/surfer.tscn")

var speed := 320.0
var scroll := 0.0
var progress := 0.0

var bg
var wave
var lip
var water
var fx
var surfer
var people: Node2D

var _lip_spray := 0.0


func _ready() -> void:
	bg = Background.new()
	add_child(bg)
	wave = Wave.new()
	add_child(wave)
	people = Node2D.new()
	people.name = "People"
	add_child(people)
	surfer = SurferScene.instantiate()
	add_child(surfer)
	lip = WaveLip.new()
	lip.wave = wave
	add_child(lip)
	water = Water.new()
	add_child(water)
	fx = Fx.new()
	add_child(fx)
	surfer.fx = fx


func advance(delta: float) -> void:
	scroll += speed * delta
	bg.scroll = scroll
	water.scroll = scroll
	wave.scroll = scroll
	water.curl_x = wave.curl_x()
	bg.progress = progress
	wave.progress = progress
	water.progress = progress
	bg.step(delta)
	wave.step(delta)
	water.step(delta)
	lip.queue_redraw()
	surfer.step(delta)
	for p in people.get_children():
		p.step(delta, speed)
		if p.position.x < -200.0:
			p.queue_free()
	_lip_spray += delta
	while _lip_spray > 0.05:
		_lip_spray -= 0.05
		# spray soprado da crista (vento terral) e do lip que se projeta no tubo
		var lx: float = wave.curl_x() + randf_range(150.0, 650.0)
		fx.emit(Vector2(lx, wave.lip_y(lx)), Vector2(-30, -70), 1, 0.6, Color(1, 1, 1, 0.6), 2.5, 0.7)
		var curtain: PackedVector2Array = wave.curtain_outer(8)
		fx.emit(curtain[2], Vector2(-40, -90), 1, 0.9, Color(1, 1, 1, 0.8), 3.5, 0.8)
		# respingos da explosão onde o lip arrebenta
		fx.emit(curtain[randi_range(3, 7)] + Vector2(-20, -10), Vector2(-60, -230), 2, 0.7, Color(1, 1, 1, 0.9), 5.0, 0.9)
	fx.step(delta)


func set_tube(on: bool) -> void:
	wave.tube_target = 1.0 if on else 0.0
	surfer.tube_on = on
