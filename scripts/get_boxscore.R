source("R/utils.R")

año <- temporada_actual()
temporada <- temporada_label(año)


# Boxscore de un partido; NULL si aun no tiene datos

boxscore_partido <- function(gamecode, season_code) {
  url <- paste0(
    Sys.getenv("EUROLEAGUE_LIVE_API"), "/Boxscore?gamecode=", gamecode,
    "&seasoncode=", season_code
  )
  raw <- httr::GET(url) %>% httr::content()

  if (length(raw$Stats) < 2) {
    return(NULL)
  }

  equipos <- map_chr(raw$Stats, "Team")

  local <- raw$Stats[[1]]$PlayersStats %>%
    tibble(value = .) %>%
    unnest_wider(value) %>%
    mutate(team_name = equipos[1], opp_team_name = equipos[2])

  visitante <- raw$Stats[[2]]$PlayersStats %>%
    tibble(value = .) %>%
    unnest_wider(value) %>%
    mutate(team_name = equipos[2], opp_team_name = equipos[1])

  bind_rows(local, visitante) %>%
    clean_names() %>%
    mutate(
      gamecode = gamecode,
      live = isTRUE(raw$Live),
      player_id = str_squish(player_id),
      .before = 1
    ) %>%
    mutate(jugador = formatear_nombre(player), .after = player)
}


# Baja los partidos jugados que faltan y rehace los que estaban en directo

update_boxscores <- function(competicion, prefijo) {
  jornadas <- read_csv(
    paste0("data/gamecodes_", competicion, "_", temporada, ".csv"),
    show_col_types = FALSE
  )
  csv <- paste0("data/", competicion, "_boxscore_", temporada, ".csv")

  guardados <- tibble(gamecode = character(), live = character())
  if (file.exists(csv)) {
    guardados <- read_csv(csv, col_types = cols(.default = "c"))
  }

  terminados <- guardados %>%
    filter(live == "FALSE") %>%
    pull(gamecode)

  pendientes <- jornadas %>%
    filter(date <= now(), !gamecode %in% terminados)

  nuevos <- map_df(
    pendientes$gamecode, boxscore_partido,
    season_code = paste0(prefijo, año)
  )

  if (nrow(nuevos) == 0) {
    return(invisible(NULL))
  }


  # Todo a texto para juntarlo con lo guardado sin choques de tipos

  nuevos %>%
    left_join(select(jornadas, gamecode, jornada, date), by = "gamecode") %>%
    relocate(jornada, date, .after = gamecode) %>%
    mutate(across(everything(), as.character)) %>%
    bind_rows(filter(guardados, !gamecode %in% nuevos$gamecode)) %>%
    arrange(date) %>%
    write_csv(csv)
}

update_boxscores("euroleague", "E")
update_boxscores("eurocup", "U")
