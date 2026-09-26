# Orden importa: calendario -> partidos -> pbp enriquecido -> stats
# (box_creation.R va aparte, en su propio workflow nocturno)

source("scripts/get_rounds.R")
source("scripts/get_boxscore.R")
source("scripts/get_pbp.R")
source("scripts/get_pbp_enriquecido.R")
source("scripts/check_quintetos.R")
source("scripts/get_players.R")
source("scripts/get_teams.R")
source("scripts/players_stats.R")
source("scripts/teams_stats.R")
