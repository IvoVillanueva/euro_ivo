source("R/utils.R")

if (!dir.exists("data")) {
  dir.create("data")
}

año <- temporada_actual()
temporada <- temporada_label(año)


# Acumulativo: quien deja el equipo se queda en el CSV con active = FALSE

jugadores <- function(competicion, liga) {
  url <- paste0(
    Sys.getenv("EUROLEAGUE_FEEDS_V2"), "/competitions/", liga,
    "/seasons/", liga, año,
    "/people?personType=J&Limit=1000&Offset=0&active=true&search=&sortBy=name"
  )
  personas <- httr::GET(url) %>%
    httr::content() %>%
    purrr::pluck("data")

  if (length(personas) == 0) {
    message(competicion, ": sin datos aun")
    return(NULL)
  }

  csv <- paste0("data/jugadores_", competicion, "_", temporada, ".csv")
  guardados <- tibble()
  if (file.exists(csv)) {
    guardados <- read_csv(csv, col_types = cols(.default = "c")) %>%
      mutate(active = "FALSE")
  }

  personas %>%
    tibble(value = .) %>%
    unnest_wider(value) %>%
    unnest_wider(person, names_sep = "_") %>%
    unnest_wider(person_country, names_sep = "_") %>%
    unnest_wider(person_birthCountry) %>%
    unnest_wider(person_images, names_sep = "_") %>%
    unnest_wider(images) %>%
    unnest_wider(club, names_sep = "_") %>%
    unnest_wider(season, names_sep = "_") %>%
    unnest_wider(club_images) %>%
    mutate(jugador = formatear_nombre(person_name), .after = person_name) %>%
    mutate(across(everything(), as.character)) %>%
    bind_rows(guardados) %>%
    distinct(person_code, club_code, .keep_all = TRUE) %>%
    write_csv(csv)
}

jugadores("euroleague", "E")
jugadores("eurocup", "U")
