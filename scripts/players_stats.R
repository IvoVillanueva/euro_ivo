source("R/utils.R")

if (!dir.exists("data")) {
  dir.create("data")
}

año <- temporada_actual()
temporada <- temporada_label(año)


# Un CSV por tipo; t= salta la cache de la API; sin datos no escribe

stats_jugadores <- function(tipo, competicion, liga) {
  url <- paste0(
    Sys.getenv("EUROLEAGUE_FEEDS_V3"), "/competitions/", liga,
    "/statistics/players/", tipo,
    "?seasonMode=Single&limit=1000&seasonCode=", liga, año,
    "&statisticMode=perGame&statisticSortMode=perGame",
    "&t=", as.integer(Sys.time())
  )
  jugadores <- httr::GET(url) %>%
    httr::content() %>%
    purrr::pluck("players")

  if (length(jugadores) == 0) {
    message(competicion, " ", tipo, ": sin datos aun")
    return(NULL)
  }

  jugadores %>%
    tibble(value = .) %>%
    unnest_wider(value) %>%
    unnest_wider(player) %>%
    unnest_wider(team, names_sep = "_") %>%
    clean_names() %>%
    mutate(name = formatear_nombre(name)) %>%
    write_csv(paste0(
      "data/", competicion, "_player_stats_", tipo, "_", temporada, ".csv"
    ))
}

tipos <- c("traditional", "advanced", "misc", "scoring")

walk(tipos, stats_jugadores, competicion = "euroleague", liga = "E")
walk(tipos, stats_jugadores, competicion = "eurocup", liga = "U")
