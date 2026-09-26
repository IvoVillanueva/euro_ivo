source("R/utils.R")

año <- temporada_actual()
temporada <- temporada_label(año)

if (!dir.exists("png")) {
  dir.create("png")
}


# Pace por equipo; la Euroliga no publica posesiones, formula estandar

ritmo <- read_csv(
  paste0("data/euroleague_team_stats_traditional_", temporada, ".csv"),
  show_col_types = FALSE
) %>%
  transmute(
    team_code,
    team_gp = games_played,
    posesiones = two_pointers_attempted + three_pointers_attempted -
      offensive_rebounds + turnovers + 0.44 * free_throws_attempted,
    pace = 40 * posesiones / minutes_played
  )


# Top 20 por 100 posesiones con mas del 60% de los partidos de su equipo

ranking <- read_csv(
  paste0("data/euroleague_player_stats_traditional_", temporada, ".csv"),
  show_col_types = FALSE
) %>%
  inner_join(ritmo, by = "team_code") %>%
  filter(games_played > 0.6 * team_gp) %>%
  mutate(
    poss = minutes_played / 40 * pace,
    fg3_pct = parse_number(three_pointers_percentage) / 100,
    fg3a = three_pointers_attempted / poss * 100,
    pts = points_scored / poss * 100,
    ast = assists / poss * 100,
    tov = turnovers / poss * 100,
    prof = (2 / (1 + exp(-fg3a)) - 1) * fg3_pct,
    box_creation = ast * 0.1843 + (pts + tov) * 0.0969 - 2.3021 * prof +
      0.0582 * ast * (pts + tov) * prof - 1.1942
  ) %>%
  slice_max(box_creation, n = 20, with_ties = FALSE) %>%
  transmute(
    rk = row_number(),
    nombre = word(name, 1),
    apellido = word(name, 2, -1),
    foto = image_url,
    escudo = team_image_url,
    team_code,
    gp = games_played,
    min = minutes_played,
    pts,
    ast,
    box_creation
  )


# Puesto en un cuadrado con degradado naranja

celda_puesto <- function(rk) {
  glue::glue(
    "<div style='background: linear-gradient(135deg, #fff 0%, #FF6200 100%);",
    " width: 60px; height: 60px; border-radius: 20%; text-align: center;",
    " font-size: 40px; font-weight: 900; color: white;'>{rk}</div>"
  )
}


# Escudo de fondo, foto y cuña translúcida que funde el hombro con la tabla

celda_foto <- function(escudo, foto) {
  glue::glue(
    "<div style='position: relative; width: 280px; height: 160px;",
    " overflow: hidden; background: #f1f2f3;'>",
    "<img src='{escudo}' style='position: absolute; left: -28px; top: -14px;",
    " width: 210px; opacity: 0.3;'>",
    "<div style='position: absolute; left: 98px; width: 108px; height: 160px;",
    " border-right: 2px solid #fff; box-shadow: -5px 0 10px rgba(0,0,0,0.3);",
    " transform: skew(-25deg); opacity: 0.7;'></div>",
    "<img src='{foto}' style='position: absolute; right: 10px; top: 4px;",
    " height: 240px;'>",
    "<div style='position: absolute; right: -40px; top: 0; width: 76px;",
    " height: 160px; background: #f1f2f3; transform: skew(-25deg);",
    " opacity: 0.7;'></div>",
    "</div>"
  )
}


# Nombre fino, apellido en negrita y escudo pequeno con el codigo del equipo

celda_nombre <- function(nombre, apellido, escudo, team_code) {
  glue::glue(
    "<div style='text-align: left; line-height: 45px;'>",
    "<div style='font-weight: 200; font-variant: small-caps;",
    " font-size: 45px;'>{nombre}</div>",
    "<div style='font-weight: 700; font-variant: small-caps;",
    " font-size: 45px;'>{apellido}</div>",
    "<div style='display: flex; align-items: center; margin-top: 4px;'>",
    "<img src='{escudo}' style='height: 42px; margin-right: 2px;'>",
    "<span style='font-weight: bold; color: grey; font-size: 24px;'>",
    "{team_code}</span></div></div>"
  )
}

titulo <- paste0(
  "<div style='display: flex; align-items: center; height: 68px;",
  " font-family: Signate Grotesk; text-transform: uppercase;",
  " font-size: 54px;'>",
  "<img src='https://media-cdn.incrowdsports.com/",
  "23610a1b-1c2e-4d2a-8fe4-ac2f8e400632.svg'",
  " style='height: 84px; padding-right: 12px'>",
  "<span>Lideres en Box Creation</span></div>"
)

subtitulo <- paste0(
  "<span style='font-family: Signate Grotesk; color: #8C8C8C;",
  " font-size: 30px'>",
  "Más del 60% de los partidos de su equipo, por 100 posesiones | Temporada ",
  temporada, "</span>"
)

caption <- paste0(
  "<div style='display: flex; align-items: center;'>",
  "<span><b>Datos</b>: <i>@EuroLeague</i> • <b>Gráfico</b>:",
  " <i>Ivo Villanueva</i> •&nbsp;</span>",
  "<span style='color: #c04719; font-family: \"Font Awesome 6 Brands\";",
  " font-size: 1.6em; padding-right: 8px;'>&#xE61A;</span>",
  "<span style='font-weight: bold;'><i>@elchef</i></span>",
  "<span>&nbsp;•&nbsp;</span>",
  "<img src='https://raw.githubusercontent.com/IvoVillanueva/data/refs/heads/",
  "main/elcheff_thecleanshotlogo.png'",
  " style='height: 1.5em; width: 1.5em; padding-right: 8px;'>",
  "<span style='font-weight: bold;'>Visita thecleanshot.com</span></div>"
)

ranking %>%
  mutate(
    rk = map(celda_puesto(rk), gt::html),
    foto = map(celda_foto(escudo, foto), gt::html),
    nombre = map(celda_nombre(nombre, apellido, escudo, team_code), gt::html)
  ) %>%
  select(rk, foto, nombre, gp, min, pts, ast, box_creation) %>%
  gt() %>%
  cols_label(
    rk = "",
    foto = "",
    nombre = "",
    gp = "GP",
    min = "MP",
    pts = "PTS",
    ast = "AST",
    box_creation = html("BOX<br>CREATION")
  ) %>%
  cols_width(c(gp, min, pts, box_creation) ~ px(150)) %>%
  fmt_number(columns = c(min, pts, ast, box_creation), decimals = 2) %>%
  cols_align(align = "center", columns = c(gp, min, pts, ast, box_creation)) %>%
  data_color(columns = box_creation, palette = c("white", "#FF6200")) %>%
  tab_header(title = html(titulo), subtitle = html(subtitulo)) %>%
  tab_source_note(source_note = html(caption)) %>%
  tab_options(
    heading.align = "left",
    heading.border.bottom.style = "none",
    table.border.bottom.style = "none",
    column_labels.border.top.style = "none",
    column_labels.border.bottom.color = "black",
    data_row.padding = px(0),
    table.font.size = 60,
    column_labels.font.size = 30,
    column_labels.font.weight = "bold",
    source_notes.font.size = 25,
    table_body.hlines.color = "gray90",
    table.font.names = "Oswald"
  ) %>%
  gtsave("png/euroleague.png", vwidth = 3000, vheight = 1500, expand = 100)
