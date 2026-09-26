source("R/utils.R")

if (!dir.exists("data")) {
  dir.create("data")
}

año <- temporada_actual()
temporada <- temporada_label(año)


# Equipos con colores y escudo; si aun no hay datos no escribe

equipos <- function(competicion, liga) {
  url <- paste0(
    Sys.getenv("EUROLEAGUE_FEEDS_V2"), "/competitions/", liga,
    "/seasons/", liga, año, "/clubs"
  )
  clubes <- httr::GET(url) %>%
    httr::content() %>%
    purrr::pluck("data")

  if (length(clubes) == 0) {
    message(competicion, ": sin datos aun")
    return(NULL)
  }

  clubes %>%
    tibble(value = .) %>%
    unnest_wider(value) %>%
    unnest_wider(images) %>%
    unnest_wider(country, names_sep = "_") %>%
    clean_names() %>%
    write_csv(paste0("data/equipos_", competicion, "_", temporada, ".csv"))
}

equipos("euroleague", "E")
equipos("eurocup", "U")
