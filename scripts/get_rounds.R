# Calendario diario: recoge aplazamientos, cambios de fecha y nuevas fases

source("R/utils.R")

if (!dir.exists("data")) {
  dir.create("data")
}

año <- temporada_actual()
temporada <- temporada_label(año)


# phase = "" devuelve todas las fases (RS, PI, PO, FF...)

descargar_jornadas <- function(competition_code, season_code, rounds,
                               phase = "") {
  descargar_jornada <- function(ronda) {
    url <- paste0(
      Sys.getenv("EUROLEAGUE_FEEDS_V2"), "/competitions/",
      competition_code, "/seasons/", season_code,
      "/games?teamCode=&phaseTypeCode=", phase, "&roundNumber=", ronda
    )

    resultado <- httr::GET(url) %>%
      httr::content() %>%
      purrr::pluck("data")


    # Jornada sin partidos todavia: se salta

    if (is.null(resultado) || length(resultado) == 0) {
      return(NULL)
    }

    resultado %>%
      dplyr::tibble(value = .) %>%
      tidyr::unnest_wider(value) %>%
      tidyr::unnest_wider(round) %>%
      tidyr::unnest_wider(confirmedDate, names_sep = "_") %>%
      dplyr::transmute(
        jornada = round,
        gamecode = code,
        date = lubridate::with_tz(lubridate::ymd_hms(date), "Europe/Madrid"),
        semana = lubridate::isoweek(date)
      )
  }

  purrr::map_df(rounds, descargar_jornada)
}


# --- Euroleague ---

euroleague_rounds <- descargar_jornadas(
  competition_code = "E", season_code = paste0("E", año), rounds = 1:47
) %>%
  arrange(date) %>%
  readr::write_csv(paste0("data/gamecodes_euroleague_", temporada, ".csv"))


# --- Eurocup ---

eurocup_rounds <- descargar_jornadas(
  competition_code = "U", season_code = paste0("U", año), rounds = 1:26
) %>%
  arrange(date) %>%
  readr::write_csv(paste0("data/gamecodes_eurocup_", temporada, ".csv"))


# --- Supercup ---

supercup_rounds <- descargar_jornadas(
  competition_code = "SC", season_code = paste0("SC", año), rounds = 1:2
)


# Solo se guarda si hubo Supercup esa temporada

if (nrow(supercup_rounds) > 0) {
  readr::write_csv(
    arrange(supercup_rounds, date),
    paste0("data/gamecodes_supercup_", temporada, ".csv")
  )
}
