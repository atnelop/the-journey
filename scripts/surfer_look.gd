extends RefCounted
## Opções de personalização do surfista (tela "Personalizar surfista").
## O visual escolhido fica salvo em Game.look como índices destas listas.

const SKINS := [
	Color(0.98, 0.82, 0.69), Color(0.93, 0.72, 0.56), Color(0.86, 0.62, 0.44),
	Color(0.72, 0.5, 0.33), Color(0.55, 0.36, 0.23), Color(0.38, 0.25, 0.16),
]
const HAIR_STYLES := ["Curto", "Comprido", "Coque", "Moicano", "Careca"]
const HAIR_COLORS := [
	Color(0.1, 0.07, 0.05), Color(0.24, 0.15, 0.08), Color(0.9, 0.72, 0.38), Color(0.68, 0.27, 0.12),
	Color(0.9, 0.9, 0.88), Color(0.2, 0.5, 0.95), Color(0.95, 0.4, 0.7),
]
const BEARDS := ["Nenhuma", "Bigode", "Barba"]
const CLOTHES := [
	Color(1.0, 0.8, 0.18), Color(0.95, 0.3, 0.3), Color(0.25, 0.65, 0.98), Color(0.1, 0.24, 0.58),
	Color(0.15, 0.75, 0.5), Color(0.6, 0.35, 0.85), Color(1.0, 0.55, 0.2), Color(0.95, 0.95, 0.95),
	Color(0.12, 0.12, 0.16),
]
const BOARDS := [
	Color(1.0, 0.45, 0.32), Color(0.3, 0.85, 0.85), Color(1.0, 0.85, 0.25),
	Color(0.95, 0.95, 0.95), Color(0.55, 0.85, 0.35), Color(0.95, 0.45, 0.75),
]
const DEFAULT := {"skin": 2, "hair_style": 0, "hair_color": 1, "beard": 0, "top": 0, "shorts": 3, "board": 0}
const SIZES := {
	"skin": 6, "hair_style": 5, "hair_color": 7, "beard": 3, "top": 9, "shorts": 9, "board": 6,
}


## Garante que o visual tem todas as chaves e índices válidos (ex.: save antigo ou corrompido).
static func sanitize(look) -> Dictionary:
	var out := DEFAULT.duplicate()
	if look is Dictionary:
		for k in SIZES.keys():
			if look.has(k):
				out[k] = clampi(int(look[k]), 0, int(SIZES[k]) - 1)
	return out


static func random(rng: RandomNumberGenerator) -> Dictionary:
	var out := {}
	for k in SIZES.keys():
		out[k] = rng.randi_range(0, int(SIZES[k]) - 1)
	return out
