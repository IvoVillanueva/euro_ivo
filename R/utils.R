library(tidyverse)
library(httr)
library(janitor)
library(gt)


# Año de inicio de la temporada; cambia en septiembre

temporada_actual <- function() {
  hoy <- lubridate::today(tzone = "Europe/Madrid")
  if (lubridate::month(hoy) >= 9) {
    lubridate::year(hoy)
  } else {
    lubridate::year(hoy) - 1
  }
}


# 2026 -> "2026-27", para los nombres de fichero

temporada_label <- function(year = temporada_actual()) {
  paste0(year, "-", stringr::str_sub(as.character(year + 1), 3, 4))
}


# "LLULL, SERGIO" -> "Sergio Llull"; respeta O'Neale y sufijos romanos (III)

formatear_nombre <- function(player) {
  player %>%
    str_replace("^(.*?),\\s*(.*)$", "\\2 \\1") %>%
    str_to_title() %>%
    str_replace_all("'\\w", toupper) %>%
    str_replace_all("\\b(Ii{1,2}|Iv|Vi{1,3}|Ix)\\b", toupper) %>%
    str_squish()
}
