<div align="center">

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/EuroLeague_logo.svg/330px-EuroLeague_logo.svg.png" width="260" alt="EuroLeague"><br><br>
<img src= "https://media-cdn.incrowdsports.com/07d1f1d3-42ea-480d-b36b-f050147fcba2.svg" width="200" alt="EuroCup">

**Extracción automática de datos de la Euroliga y la Eurocup**: jornadas, boxscores, play-by-play, jugadores, equipos y estadísticas de temporada.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![R](https://img.shields.io/badge/R-tidyverse-276DC3)

</div>

---

<div align="center">

<img src="https://media-cdn.incrowdsports.com/371b0d9b-9250-4c09-bda7-0686cf024657.png" width="40" title="Real Madrid">
<img src="https://media-cdn.incrowdsports.com/789423ac-3cdf-4b89-b11c-b458aa5f59a6.png" width="40" title="Olympiacos Piraeus">
<img src="https://media-cdn.incrowdsports.com/35dfa503-e417-481f-963a-bdf6f013763e.png" width="40" title="FC Barcelona">
<img src="https://media-cdn.cortextech.io/1b533342-78f5-4932-b714-a7d80b5826b5.png" width="40" title="Maccabi Rapyd Tel Aviv">
<img src="https://media-cdn.cortextech.io/1dU3kpCqReRp93/1BSdBWIjCgOCxM/a844756c-a58d-4666-93b8-48f7337bc79d.png" width="40" title="Anadolu Efes Istanbul">
<img src="https://media-cdn.cortextech.io/1dU3kpCqReRp93/1BSdBWIjChWbHH/5c2f0ab6-f86a-4df0-b2f3-f9ab92f7267b.png" width="40" title="Armani Olimpia Milan">
<img src="https://media-cdn.cortextech.io/1dU3kpCqReRp93/1BSdBWIjCiezrk/aa39750a-6203-49ee-a87d-edd0c6f0397d.png" width="40" title="Fenerbahce Tarfin Istanbul">
<img src="https://media-cdn.incrowdsports.com/817b0e58-d595-4b09-ab0b-1e7cc26249ff.png" width="40" title="FC Bayern Munich">
<img src="https://media-cdn.incrowdsports.com/e3dff28a-9ec6-4faf-9d96-ecbc68f75780.png" width="40" title="Panathinaikos AKTOR Athens">
<img src="https://media-cdn.incrowdsports.com/2681304e-77dd-4331-88b1-683078c0fb49.png" width="40" title="Partizan Mozzart Bet Belgrade">
<img src="https://media-cdn.incrowdsports.com/a033e5b3-0de7-48a3-98d9-d9a4b9df1f39.png" width="40" title="Paris Basketball">
<img src="https://media-cdn.cortextech.io/cbc49cb0-99ce-4462-bdb7-56983ee03cf4.png" width="40" title="Kosner Baskonia Vitoria-Gasteiz">
<img src="https://media-cdn.cortextech.io/1dU3kpCqReRp93/1BSdBWIjChWbHL/bc3e00b2-fea4-40be-a7ec-1e633129bde3.png" width="40" title="Valencia Basket">
<img src="https://media-cdn.incrowdsports.com/0aa09358-3847-4c4e-b228-3582ee4e536d.png" width="40" title="Zalgiris Kaunas">

</div>

---


<div align="center">

<img src="https://raw.githubusercontent.com/IvoVillanueva/EUROLIGAS/main/png/euroleague.png" width="500" alt="Líderes en Box Creation de la Euroliga">

</div>

Se actualiza sola cada noche de jornada a las 23:55 (hora de Madrid). Entran los jugadores que han jugado más del 60% de los partidos de su equipo; valores por 100 posesiones.

## ✨ Qué hace

- **Jornadas**: gamecodes y fechas de todos los partidos de la temporada (Euroliga, Eurocup y Supercup).
- **Boxscores**: estadísticas por jugador y partido, extracción **incremental**: solo baja partidos nuevos y rehace los que estaban en directo.
- **Play-by-play**: jugada a jugada con marcador, cuarto (prórrogas incluidas), asistente/asistido, stats por jugada y `valoracion`.
- **Play-by-play enriquecido**: quinteto en pista (`h1`-`h5` / `a1`-`a5`) y `+/-` por quinteto.
- **Jugadores**: plantillas con foto, equipo, nacionalidad, posición... acumulativo: quien deja el equipo se queda con `active = FALSE`.
- **Equipos**: nombre, escudo y colores oficiales.
- **Stats de temporada**: un CSV por tipo (`traditional`, `advanced`, `misc`, `scoring` en jugadores; `traditional`, `advanced` y sus `opponents` en equipos).
- **Box Creation**: ranking en imagen (arriba), con posesiones y pace calculados por equipo.
- **Temporada automática**: se calcula sola a partir de la fecha del sistema.

## 📂 Estructura

```
EUROLIGAS/
├── R/
│   └── utils.R                 # librerias + temporada y formatear_nombre()
├── scripts/
│   ├── main.R                  # orquesta la descarga (GitHub Actions)
│   ├── get_rounds.R            # calendario / gamecodes
│   ├── get_boxscore.R          # boxscore por partido (incremental)
│   ├── get_pbp.R               # play-by-play por partido (incremental)
│   ├── get_pbp_enriquecido.R   # quintetos y +/- a partir de pbp + boxscore
│   ├── check_quintetos.R       # comprueba que los quintetos cuadran
│   ├── get_players.R           # plantillas (acumulativo)
│   ├── get_teams.R             # equipos, escudos y colores
│   ├── players_stats.R         # stats de temporada por jugador
│   ├── teams_stats.R           # stats de temporada por equipo
│   └── box_creation.R          # imagen del ranking de Box Creation
├── data/                       # CSVs generados, uno por temporada
├── png/                        # imagen del ranking
└── .github/workflows/          # automatizacion
```

## ⚙️ Cómo funciona

Usa las mismas APIs que la web de la Euroliga:

- `feeds.incrowdsports.com/provider/euroleague-feeds/{v2,v3}`: calendario, jugadores, equipos y stats de temporada.
- `live.euroleague.net/api`: boxscore y play-by-play.

Las URLs base se leen de variables de entorno (`EUROLEAGUE_FEEDS_V2`, `EUROLEAGUE_FEEDS_V3`, `EUROLEAGUE_LIVE_API`): en local desde `.Renviron` y en GitHub Actions desde los *secrets* del repositorio.

## 🧪 Ejecutar localmente

```r
install.packages(c("tidyverse", "httr", "jsonlite", "janitor", "gt"))
```

```bash
Rscript scripts/main.R
Rscript scripts/box_creation.R
```

## 🗓️ Automatización

- [`main.yml`](.github/workflows/main.yml): cada 10 minutos entre septiembre y junio, o a mano desde *Actions*. Actualiza los CSV de `data/`.
- [`box_creation.yml`](.github/workflows/box_creation.yml): cada noche a las 23:55 (hora de Madrid) saca la foto del ranking y la sube a `png/euroleague.png`.

## 🧹 Estilo

El código sigue `styler` (`tidyverse_style`) y `lintr`.

## 📄 Licencia

[MIT](LICENSE)
