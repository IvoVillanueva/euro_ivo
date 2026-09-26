source("R/utils.R")

año <- temporada_actual()
temporada <- temporada_label(año)


# Revisa que los quintetos del pbp enriquecido cuadren con el boxscore

comprobar_quintetos <- function(competicion) {
  pbp_csv <- paste0(
    "data/", competicion, "_pbp_enriquecido_", temporada, ".csv"
  )
  box_csv <- paste0("data/", competicion, "_boxscore_", temporada, ".csv")

  if (!file.exists(pbp_csv) || !file.exists(box_csv)) {
    return(NULL)
  }

  pbp <- read_csv(pbp_csv, col_types = cols(markertime = "c", dorsal = "c"))
  plantillas <- read_csv(box_csv, show_col_types = FALSE) %>%
    filter(!is.na(jugador)) %>%
    distinct(gamecode, jugador, team, is_starter)
  lados <- pbp %>%
    filter(!is.na(court)) %>%
    distinct(gamecode, court, codeteam)

  en_pista <- pbp %>%
    mutate(fila = row_number()) %>%
    select(fila, gamecode, h1:h5, a1:a5) %>%
    pivot_longer(-c(fila, gamecode), values_to = "jugador") %>%
    mutate(court = if_else(str_starts(name, "h"), "home", "away")) %>%
    left_join(lados, by = c("gamecode", "court")) %>%
    left_join(plantillas, by = c("gamecode", "jugador"))


  # IN de alguien que ya estaba en pista u OUT de alguien que no estaba

  cambios_raros <- pbp %>%
    filter(playtype %in% c("IN", "OUT")) %>%
    left_join(plantillas, by = c("gamecode", "jugador")) %>%
    group_by(gamecode, jugador) %>%
    filter(playtype == lag(
      playtype,
      default = if (isTRUE(first(is_starter) == 1)) "IN" else "OUT"
    )) %>%
    ungroup()

  message(
    competicion, ":",
    "\n  lados con mas de un equipo: ",
    sum(count(lados, gamecode, court)$n > 1),
    "\n  jugador en pista de otro equipo: ",
    sum(en_pista$team != en_pista$codeteam, na.rm = TRUE),
    "\n  jugador en pista fuera del boxscore: ",
    sum(!is.na(en_pista$jugador) & is.na(en_pista$team)),
    "\n  huecos en el quinteto: ", sum(is.na(en_pista$jugador)),
    "\n  jugador repetido en una jugada: ",
    sum(count(en_pista, fila, jugador)$n > 1),
    "\n  jugador con dos equipos en un partido: ",
    sum(count(plantillas, gamecode, jugador)$n > 1),
    "\n  IN/OUT fuera de secuencia: ", nrow(cambios_raros)
  )

  if (nrow(cambios_raros) > 0) {
    cambios_raros %>%
      select(gamecode, quarter, markertime, playtype, jugador) %>%
      print()
  }
}

walk(c("euroleague", "eurocup"), comprobar_quintetos)
