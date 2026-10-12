extends RefCounted
## Paleta da cena. A cor muda com o progresso da sessão (tarde -> dourado -> pôr do sol),
## sinalizando visualmente quanto falta para a onda terminar.

const KEYS := [
	{ # tarde
		"sky_top": Color(0.30, 0.62, 0.92), "sky_bot": Color(0.93, 0.92, 0.82),
		"sun": Color(1.0, 0.96, 0.82), "cloud": Color(1.0, 1.0, 1.0),
		"hill": Color(0.55, 0.69, 0.78), "sand": Color(0.96, 0.87, 0.67),
		"sea_far": Color(0.17, 0.52, 0.68), "sea_near": Color(0.08, 0.38, 0.55),
		"face": Color(0.10, 0.50, 0.62), "face_light": Color(0.40, 0.82, 0.80),
		"deep": Color(0.03, 0.17, 0.30), "lip": Color(0.55, 0.90, 0.86), "foam": Color(0.97, 0.99, 1.0),
	},
	{ # dourado
		"sky_top": Color(0.33, 0.50, 0.82), "sky_bot": Color(1.0, 0.80, 0.52),
		"sun": Color(1.0, 0.86, 0.52), "cloud": Color(1.0, 0.93, 0.82),
		"hill": Color(0.60, 0.58, 0.68), "sand": Color(0.98, 0.80, 0.58),
		"sea_far": Color(0.22, 0.46, 0.62), "sea_near": Color(0.09, 0.32, 0.48),
		"face": Color(0.10, 0.42, 0.56), "face_light": Color(0.45, 0.78, 0.74),
		"deep": Color(0.04, 0.14, 0.27), "lip": Color(0.62, 0.88, 0.80), "foam": Color(1.0, 0.97, 0.92),
	},
	{ # pôr do sol
		"sky_top": Color(0.22, 0.20, 0.46), "sky_bot": Color(1.0, 0.52, 0.42),
		"sun": Color(1.0, 0.62, 0.38), "cloud": Color(1.0, 0.72, 0.66),
		"hill": Color(0.42, 0.34, 0.52), "sand": Color(0.80, 0.56, 0.52),
		"sea_far": Color(0.30, 0.30, 0.52), "sea_near": Color(0.12, 0.17, 0.36),
		"face": Color(0.12, 0.25, 0.44), "face_light": Color(0.50, 0.56, 0.70),
		"deep": Color(0.05, 0.08, 0.20), "lip": Color(0.72, 0.74, 0.86), "foam": Color(1.0, 0.92, 0.90),
	},
]


static func at(progress: float) -> Dictionary:
	var x := clampf(progress, 0.0, 1.0) * (KEYS.size() - 1)
	var i := mini(int(x), KEYS.size() - 2)
	var f := x - i
	var a: Dictionary = KEYS[i]
	var b: Dictionary = KEYS[i + 1]
	var out := {}
	for k in a.keys():
		var ca: Color = a[k]
		var cb: Color = b[k]
		out[k] = ca.lerp(cb, f)
	return out
