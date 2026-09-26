source("R/utils.R")

año <- temporada_actual()
temporada <- temporada_label(año)


# Jugadas de un partido con marcador, cuarto y stats por jugada; NULL sin datos

pbp_partido <- function(gamecode, season_code) {
  url <- paste0(
    Sys.getenv("EUROLEAGUE_LIVE_API"), "/PlaybyPlay?gamecode=", gamecode,
    "&seasoncode=", season_code
  )
  respuesta <- httr::GET(url)
  txt <- httr::content(respuesta, "text", encoding = "UTF-8")


  # Sin jugar o API saturada (429): NULL, se reintenta en la siguiente pasada

  if (httr::status_code(respuesta) != 200 || !nzchar(txt)) {
    return(NULL)
  }

  raw <- jsonlite::fromJSON(txt)
  cuartos <- c(
    "FirstQuarter", "SecondQuarter", "ThirdQuarter", "ForthQuarter",
    "ExtraTime"
  )
  jugadas <- raw[cuartos] %>%
    keep(is.data.frame) %>%
    bind_rows()

  if (nrow(jugadas) == 0) {
    return(NULL)
  }

  jugadas %>%
    mutate(across(where(is.character), str_squish)) %>%
    mutate(
      gamecode = gamecode,
      live = isTRUE(raw$Live),
      court = case_when(TEAM == raw$TeamA ~ "home", TEAM == raw$TeamB ~ "away"),
      quarter = case_when(
        PLAYINFO %in% c("End Period", "End Game") ~ 0,
        MINUTE <= 40 ~ ceiling(MINUTE / 10),
        TRUE ~ 4 + ceiling((MINUTE - 40) / 5)
      ),
      MARKERTIME = case_when(
        PLAYINFO == "Begin Period" & MINUTE > 40 ~ "05:00",
        PLAYINFO == "Begin Period" ~ "10:00",
        PLAYINFO %in% c("End Period", "End Game") ~ "00:00",
        TRUE ~ MARKERTIME
      ),
      POINTS_A = if_else(NUMBEROFPLAY == min(NUMBEROFPLAY), 0, POINTS_A),
      POINTS_B = if_else(NUMBEROFPLAY == min(NUMBEROFPLAY), 0, POINTS_B),
      jugador_asiste = if_else(PLAYTYPE == "AS", PLAYER, NA),
      jugador_asistido = if_else(PLAYTYPE == "AS", lag(PLAYER), NA),
      three_make = as.numeric(PLAYTYPE == "3FGM"),
      three_misses = as.numeric(PLAYTYPE == "3FGA"),
      two_make = as.numeric(PLAYTYPE == "2FGM"),
      two_misses = as.numeric(PLAYTYPE == "2FGA"),
      free_make = as.numeric(PLAYTYPE == "FTM"),
      free_misses = as.numeric(PLAYTYPE == "FTA"),
      .before = 1
    ) %>%
    # "(1/2 - 7 pt)": 1 anotados, 2 intentos, 7 puntos; "(3)": 3 en el partido

    mutate(
      hechos = as.numeric(str_match(PLAYINFO, "\\((\\d+)/")[, 2]),
      intentos = as.numeric(str_match(PLAYINFO, "/(\\d+)")[, 2]),
      total = as.numeric(coalesce(
        str_match(PLAYINFO, "(\\d+) pt\\)")[, 2],
        str_match(PLAYINFO, "\\((\\d+)\\)")[, 2]
      )),
      PLAYINFO = str_squish(str_remove(PLAYINFO, "\\(.*?\\)")),
      stat_3pts_atemp = if_else(PLAYTYPE %in% c("3FGA", "3FGM"), intentos, 0),
      stat_3pts_sucess = if_else(PLAYTYPE == "3FGM", hechos, 0),
      stat_2pts_atemp = if_else(PLAYTYPE %in% c("2FGA", "2FGM"), intentos, 0),
      stat_2pts_sucess = if_else(PLAYTYPE == "2FGM", hechos, 0),
      stat_1pt_atemp = if_else(PLAYTYPE %in% c("FTA", "FTM"), intentos, 0),
      stat_1pt_sucess = if_else(PLAYTYPE == "FTM", hechos, 0),
      stat_asis = if_else(PLAYTYPE == "AS", total, 0),
      stat_def_rebound = if_else(PLAYTYPE == "D", total, 0),
      stat_off_rebound = if_else(PLAYTYPE == "O", total, 0),
      stat_turnovers = if_else(PLAYTYPE == "TO", total, 0),
      stat_foul = if_else(PLAYTYPE == "CM", total, 0),
      stat_foul_drawn = if_else(PLAYTYPE == "RV", total, 0),
      stat_block = if_else(PLAYTYPE == "FV", total, 0),
      stat_block_recived = if_else(PLAYTYPE == "AG", total, 0),
      stat_points = if_else(PLAYTYPE %in% c("3FGM", "2FGM", "FTM"), total, 0),
      valoracion = case_when(
        three_make == 1 ~ 3,
        two_make == 1 ~ 2,
        free_make == 1 ~ 1,
        three_misses == 1 | two_misses == 1 | free_misses == 1 ~ -1,
        PLAYTYPE %in% c("D", "O", "AS", "ST", "FV", "RV") ~ 1,
        PLAYTYPE %in% c("TO", "AG", "CM", "OF", "CMU", "B") ~ -1,
        TRUE ~ 0
      )
    ) %>%
    fill(POINTS_A, POINTS_B, .direction = "down") %>%
    select(-hechos, -intentos, -total) %>%
    clean_names() %>%
    mutate(jugador = formatear_nombre(player), .after = player)
}


# Baja los partidos jugados que faltan y rehace los que estaban en directo

update_pbp <- function(competicion, prefijo) {
  jornadas <- read_csv(
    paste0("data/gamecodes_", competicion, "_", temporada, ".csv"),
    show_col_types = FALSE
  )
  csv <- paste0("data/", competicion, "_pbp_", temporada, ".csv")

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
    pendientes$gamecode, pbp_partido,
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

update_pbp("euroleague", "E")
update_pbp("eurocup", "U")
