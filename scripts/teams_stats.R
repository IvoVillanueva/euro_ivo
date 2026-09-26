source("R/utils.R")

if (!dir.exists("data")) {
  dir.create("data")
}

año <- temporada_actual()
temporada <- temporada_label(año)


# Un CSV por tipo; t= salta la cache de la API; sin datos no escribe

stats_equipos <- function(tipo, competicion, liga) {
  url <- paste0(
    Sys.getenv("EUROLEAGUE_FEEDS_V3"), "/competitions/", liga,
    "/statistics/teams/", tipo,
    "?seasonMode=Single&limit=1000&seasonCode=", liga, año,
    "&statisticMode=perGame&statisticSortMode=perGame",
    "&t=", as.integer(Sys.time())
  )
  equipos <- httr::GET(url) %>%
    httr::content() %>%
    purrr::pluck("teams")

  if (length(equipos) == 0) {
    message(competicion, " ", tipo, ": sin datos aun")
    return(NULL)
  }

  equipos %>%
    tibble(value = .) %>%
    unnest_wider(value) %>%
    unnest_wider(team, names_sep = "_") %>%
    clean_names() %>%
    write_csv(paste0(
      "data/", competicion, "_team_stats_", tipo, "_", temporada, ".csv"
    ))
}

tipos <- c(
  "traditional", "advanced", "opponentsTraditional", "opponentsAdvanced"
)

walk(tipos, stats_equipos, competicion = "euroleague", liga = "E")
walk(tipos, stats_equipos, competicion = "eurocup", liga = "U")
