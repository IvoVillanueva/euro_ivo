source("R/utils.R")

año <- temporada_actual()
temporada <- temporada_label(año)


# Jugadores en pista de un equipo tras cada jugada, como "A;B;C;D;E"

en_pista <- function(jugadas, lado, titulares) {
  accumulate(
    seq_len(nrow(jugadas)),
    function(pista, i) {
      if (!identical(jugadas$court[i], lado)) {
        return(pista)
      }
      switch(jugadas$playtype[i],
        IN = union(pista, jugadas$jugador[i]),
        OUT = setdiff(pista, jugadas$jugador[i]),
        pista
      )
    },
    .init = titulares
  )[-1] %>%
    map_chr(\(pista) paste(sort(pista), collapse = ";"))
}


# Quintetos de local y visitante de un partido, partiendo de los titulares

quintetos_partido <- function(jugadas, clave, boxscore) {
  local <- jugadas$codeteam[which(jugadas$court == "home")[1]]
  visitante <- jugadas$codeteam[which(jugadas$court == "away")[1]]
  titulares <- filter(boxscore, gamecode == clave$gamecode, is_starter == 1)

  jugadas %>%
    mutate(
      quinteto_h = en_pista(
        jugadas, "home", titulares$jugador[titulares$team == local]
      ),
      quinteto_a = en_pista(
        jugadas, "away", titulares$jugador[titulares$team == visitante]
      )
    )
}


# pbp + quintetos (h1..h5, a1..a5) y +/- que vuelve a 0 con cada quinteto;
# en una tanda de cambios todas sus filas llevan el quinteto final

enriquecer_pbp <- function(competicion) {
  pbp_csv <- paste0("data/", competicion, "_pbp_", temporada, ".csv")
  box_csv <- paste0("data/", competicion, "_boxscore_", temporada, ".csv")

  if (!file.exists(pbp_csv) || !file.exists(box_csv)) {
    return(NULL)
  }

  boxscore <- read_csv(box_csv, show_col_types = FALSE)

  read_csv(pbp_csv, col_types = cols(markertime = "c", dorsal = "c")) %>%
    group_by(gamecode) %>%
    group_modify(quintetos_partido, boxscore = boxscore) %>%
    group_by(gamecode, quarter, markertime) %>%
    mutate(across(
      c(quinteto_h, quinteto_a),
      \(q) if_else(playtype %in% c("IN", "OUT"), last(q), q)
    )) %>%
    group_by(gamecode) %>%
    mutate(
      dif = points_a - points_b,
      racha_h = consecutive_id(quinteto_h),
      racha_a = consecutive_id(quinteto_a)
    ) %>%
    group_by(gamecode, racha_h) %>%
    mutate(plusminus_h = dif - first(dif)) %>%
    group_by(gamecode, racha_a) %>%
    mutate(plusminus_a = first(dif) - dif) %>%
    ungroup() %>%
    separate_wider_delim(
      quinteto_h, ";",
      names = paste0("h", 1:5), too_few = "align_start", too_many = "merge"
    ) %>%
    separate_wider_delim(
      quinteto_a, ";",
      names = paste0("a", 1:5), too_few = "align_start", too_many = "merge"
    ) %>%
    select(-dif, -racha_h, -racha_a) %>%
    write_csv(
      paste0("data/", competicion, "_pbp_enriquecido_", temporada, ".csv")
    )
}

walk(c("euroleague", "eurocup"), enriquecer_pbp)
