# The Journey

Arcade de surfe 2D feito em Godot 4.7 (GDScript), seguindo o GDD v1.2 (escopo enxuto).

## Como jogar

- **ESPAÇO**: saltar (também ↑ ou W)
- **ESC**: pausar
- **M** ou o **botão de alto-falante** (canto inferior esquerdo): liga/desliga o som (a escolha fica salva)

Salte as pessoas e os animais na água. Cada obstáculo superado vale **100 pontos** e +1 de combo.
Com **combo 3** vem o **TUBO** (+300). Com **combo 5** vem o **AÉREO** (+500) e o combo recomeça.
Bateu em algo, a partida acaba. Sobreviva à onda inteira (3 min) para concluir a sessão.

No menu, **Personalizar surfista** permite escolher cor da pele, estilo e cor do cabelo, barba,
cor da lycra, da bermuda e da prancha (com pré-visualização ao vivo; a escolha fica salva).

A cada **20 segundos** sobe um nível: os obstáculos aparecem mais rápido e algo novo entra na água.

| Nível | Novidade |
|---|---|
| 1 | banhistas e crianças de boia |
| 2 | bodyboarders e **tartarugas** |
| 3 | surfistas remando e **golfinhos** (saltam; às vezes em dupla) |
| 4 | casais e **tubarões** (nadam mais rápido que o resto) |
| 5 | stand-up paddles |
| 6 | **baleias** (enormes) |
| 7–9 | tudo junto, cada vez mais rápido |

O espaçamento entre obstáculos é calculado pelo instante em que cada um chega ao surfista,
então sempre dá tempo de pousar e saltar de novo, mesmo com o tubarão chegando mais rápido.

## Como rodar

Abra a pasta no Godot 4.7 e aperte **F5**.

## Estrutura

| Arquivo | Papel |
|---|---|
| `scripts/game.gd` | Loop da sessão: geração de pessoas, colisão, pontuação, combo, Tubo/Aéreo, vitória e derrota |
| `scripts/world/surfer.gd` | Surfista: salto com altura e duração fixas, animações, hitbox, visual personalizado |
| `scripts/customize.gd`, `scripts/surfer_look.gd` | Tela de personalização e opções de visual (paletas) |
| `scripts/world/person.gd` | Obstáculo reutilizável (`scenes/person.tscn`) com 6 tipos e visual sorteado |
| `scripts/world/animal.gd` | Animais (`scenes/animal.tscn`): tartaruga, tubarão, golfinho e baleia |
| `scripts/world/wave.gd`, `wave_lip.gd` | Onda: face, tubo, lip e espuma |
| `scripts/world/background.gd`, `water.gd` | Céu, costa, mar, água rasa e areia (o dia vira pôr do sol durante a sessão) |
| `scripts/ui/hud.gd`, `pause_menu.gd` | HUD e menu de pausa |
| `scripts/sfx.gd` | Efeitos, música e som do mar gerados por código |
| `scripts/game_state.gd` | Controles, recorde salvo, troca de telas |

Os valores de balanceamento (pontos, bônus, duração, velocidade, intervalo por nível, folga entre saltos
e o que entra em cada nível) ficam no topo de `scripts/game.gd`.

## Créditos de fontes

- [Pacifico](https://fonts.google.com/specimen/Pacifico) (títulos) e [Fredoka](https://fonts.google.com/specimen/Fredoka) (textos),
  ambas sob a SIL Open Font License; licenças em `assets/fonts/`.

## Teste automático

`godot --path . -- --smoke-test` joga sozinho com piloto automático e salva capturas em `user://smoke/`.
