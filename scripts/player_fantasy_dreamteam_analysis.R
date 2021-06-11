pacman::p_load(tidyverse, dplyr, # Tidyverse
               magrittr, # Pipes
               glue, stringr, stringi, pracma, # String operations
               tictoc, # Timing
               hablar, # Non-astonishing behavior!
               readr, tools, # File reading/writing
               lpSolve, # Linear programming
               janitor)

round2 = function(x, n) {
   posneg = sign(x)
   z = abs(x)*10^n
   z = z + 0.5
   z = trunc(z)
   z = z/10^n
   z*posneg
}

get_obj <- function(players) {
   return(players %>% select(Points) %>% unname() %>% unlist())
}

get_const_mat_start <- function(players) {
   return(players %>% select(Goalkeeper, Defender, Midfielder, Forward, Start_Price) %>%
             unname() %>% unlist() %>% matrix(nrow = 5, byrow = TRUE))
}

get_const_mat_end <- function(players) {
   return(players %>% select(Goalkeeper, Defender, Midfielder, Forward, End_Price) %>%
             unname() %>% unlist() %>% matrix(nrow = 5, byrow = TRUE))
}

get_const_mat_no_bank <- function(players) {
   return(players %>% select(Goalkeeper, Defender, Midfielder, Forward) %>%
             unname() %>% unlist() %>% matrix(nrow = 4, byrow = TRUE))
}

get_dream_squad_no_bank <- function(players_raw, max_gk = 2, max_def = 5, max_mid = 5, max_fwd = 3) {
   players <- players_raw %>%
      mutate(Goalkeeper = ifelse(Position == "GK", 1, 0),
             Defender = ifelse(Position == "DEF", 1, 0),
             Midfielder = ifelse(Position == "MID", 1, 0),
             Forward = ifelse(Position == "FWD", 1, 0))
   solved <- lp("max", get_obj(players),
                get_const_mat_no_bank(players),
                c("=", "=", "=", "="),
                c(max_gk, max_def, max_mid, max_fwd),
                all.bin = TRUE, all.int = TRUE)
   dream_squad <- players %>%
      slice(which(solved$solution == 1)) %>%
      arrange(desc(Goalkeeper), desc(Defender), desc(Midfielder), desc(Forward)) %>%
      select(-Goalkeeper, -Defender, -Midfielder, -Forward) %>%
      select(League, Season, Club, Player, Position, Points, Bonus_Points, Start_Price, End_Price) %>%
      arrange(desc(Points)) %>%
      arrange(match(Position, c("GK", "DEF", "MID", "FWD")))
   return(dream_squad)
}

get_dream_squad_start <- function(players_raw, max_gk = 2, max_def = 5, max_mid = 5, max_fwd = 3, max_cost = 100.0) {
   players <- players_raw %>%
      mutate(Goalkeeper = ifelse(Position == "GK", 1, 0),
             Defender = ifelse(Position == "DEF", 1, 0),
             Midfielder = ifelse(Position == "MID", 1, 0),
             Forward = ifelse(Position == "FWD", 1, 0))
   solved <- lp("max", get_obj(players),
                get_const_mat_start(players),
                c("=", "=", "=", "=", "<="),
                c(max_gk, max_def, max_mid, max_fwd, max_cost),
                all.bin = TRUE, all.int = TRUE)
   dream_squad <- players %>%
      slice(which(solved$solution == 1)) %>%
      arrange(desc(Goalkeeper), desc(Defender), desc(Midfielder), desc(Forward)) %>%
      select(-Goalkeeper, -Defender, -Midfielder, -Forward) %>%
      select(League, Season, Club, Player, Position, Points, Bonus_Points, Start_Price, End_Price) %>%
      arrange(desc(Points)) %>%
      arrange(match(Position, c("GK", "DEF", "MID", "FWD")))
   return(dream_squad)
}

get_dream_squad_end <- function(players_raw, max_gk = 2, max_def = 5, max_mid = 5, max_fwd = 3, max_cost = 100.0) {
   players <- players_raw %>%
      mutate(Goalkeeper = ifelse(Position == "GK", 1, 0),
             Defender = ifelse(Position == "DEF", 1, 0),
             Midfielder = ifelse(Position == "MID", 1, 0),
             Forward = ifelse(Position == "FWD", 1, 0))
   solved <- lp("max", get_obj(players),
                get_const_mat_end(players),
                c("=", "=", "=", "=", "<="),
                c(max_gk, max_def, max_mid, max_fwd, max_cost),
                all.bin = TRUE, all.int = TRUE)
   dream_squad <- players %>%
      slice(which(solved$solution == 1)) %>%
      arrange(desc(Goalkeeper), desc(Defender), desc(Midfielder), desc(Forward)) %>%
      select(-Goalkeeper, -Defender, -Midfielder, -Forward) %>%
      select(League, Season, Club, Player, Position, Points, Bonus_Points, Start_Price, End_Price) %>%
      arrange(desc(Points)) %>%
      arrange(match(Position, c("GK", "DEF", "MID", "FWD")))
   return(dream_squad)
}

get_dream_team_no_bank <- function(dream_squad, comment = "") {
   dream_squad <- dream_squad %>% arrange(Position, desc(Points))
   gks <- dream_squad %>% filter(Position == "GK")
   defs <- dream_squad %>% filter(Position == "DEF")
   mids <- dream_squad %>% filter(Position == "MID")
   fwds <- dream_squad %>% filter(Position == "FWD")
   formations <-
      tribble(~gk, ~def, ~mid, ~fwd,
              1, 3, 4, 3,
              1, 3, 5, 2,
              1, 4, 3, 3,
              1, 4, 4, 2,
              1, 4, 5, 1,
              1, 5, 2, 3,
              1, 5, 3, 2,
              1, 5, 4, 1)
   max_points <- -1
   best_formation <- c(0, 0, 0, 0)
   dream_team <- c()
   for (i in 1:nrow(formations)) {
      gks_picked <- gks %>% slice(1:formations$gk[i])
      defs_picked <- defs %>% slice(1:formations$def[i])
      mids_picked <- mids %>% slice(1:formations$mid[i])
      fwds_picked <- fwds %>% slice(1:formations$fwd[i])
      max_points_trial <-
         gks_picked$Points %>% sum() +
         defs_picked$Points %>% sum() +
         mids_picked$Points %>% sum() +
         fwds_picked$Points %>% sum()
      if (max_points_trial > max_points) {
         max_points <- max_points_trial
         best_formation <- formations %>% slice(i) %>% as_vector()
      }
   }
   "[No Bank] {comment}: {best_formation[[\"def\"]]}-{best_formation[[\"mid\"]]}-{best_formation[[\"fwd\"]]}" %>%
      glue() %>% print()
   dream_team <- dream_team %>% bind_rows(gks %>% slice(1:best_formation[["gk"]]),
                                          defs %>% slice(1:best_formation[["def"]]),
                                          mids %>% slice(1:best_formation[["mid"]]),
                                          fwds %>% slice(1:best_formation[["fwd"]])
                                          )
   dream_team <- dream_team %>% adorn_totals() %>%
      mutate(Start_Price = Start_Price %>% round(1) %>% format(1),
             End_Price = End_Price %>% round(1) %>% format(1))
   return(dream_team)
}

get_dream_team_start <- function(players_raw, comment = "") {
   formations <-
      tribble(~gk, ~def, ~mid, ~fwd,
              1, 3, 4, 3,
              1, 3, 5, 2,
              1, 4, 3, 3,
              1, 4, 4, 2,
              1, 4, 5, 1,
              1, 5, 2, 3,
              1, 5, 3, 2,
              1, 5, 4, 1)
   max_points <- -1
   best_formation <- c(0, 0, 0, 0)
   dream_team <- c()
   for (i in 1:nrow(formations)) {
      dream_team_trial <- get_dream_squad_start(players_raw,
                                                max_gk = formations$gk[i],
                                                max_def = formations$def[i],
                                                max_mid = formations$mid[i],
                                                max_fwd = formations$fwd[i],
                                                max_cost = 83.0)
      max_points_trial <- dream_team_trial$Points %>% sum()
      if (max_points_trial > max_points) {
         max_points <- max_points_trial
         best_formation <- formations %>% slice(i) %>% as_vector()
         dream_team <- dream_team_trial
      }
   }
   "[Starting Cost] {comment}: {best_formation[[\"def\"]]}-{best_formation[[\"mid\"]]}-{best_formation[[\"fwd\"]]}" %>%
      glue() %>% print()
   dream_team <- dream_team %>% adorn_totals() %>%
      mutate(Start_Price = Start_Price %>% round(1) %>% format(1),
             End_Price = End_Price %>% round(1) %>% format(1))
   return(dream_team)
}

get_dream_team_end <- function(players_raw, comment = "") {
   formations <-
      tribble(~gk, ~def, ~mid, ~fwd,
              1, 3, 4, 3,
              1, 3, 5, 2,
              1, 4, 3, 3,
              1, 4, 4, 2,
              1, 4, 5, 1,
              1, 5, 2, 3,
              1, 5, 3, 2,
              1, 5, 4, 1)
   max_points <- -1
   best_formation <- c(0, 0, 0, 0)
   dream_team <- c()
   for (i in 1:nrow(formations)) {
      dream_team_trial <- get_dream_squad_end(players_raw,
                                                max_gk = formations$gk[i],
                                                max_def = formations$def[i],
                                                max_mid = formations$mid[i],
                                                max_fwd = formations$fwd[i],
                                                max_cost = 83.0)
      max_points_trial <- dream_team_trial$Points %>% sum()
      if (max_points_trial > max_points) {
         max_points <- max_points_trial
         best_formation <- formations %>% slice(i) %>% as_vector()
         dream_team <- dream_team_trial
      }
   }
   "[Ending Cost] {comment}: {best_formation[[\"def\"]]}-{best_formation[[\"mid\"]]}-{best_formation[[\"fwd\"]]}" %>%
      glue() %>% print()
   dream_team <- dream_team %>% adorn_totals() %>%
      mutate(Start_Price = Start_Price %>% round(1) %>% format(1),
             End_Price = End_Price %>% round(1) %>% format(1))
   return(dream_team)
}

players_lpsolve <- readRDS("../rds/fantasy/fantasy_analysis_w_prices.rds")

# NO BANK
# All seasons, All leagues
dream_squad_all_no_bank <- players_lpsolve %>% get_dream_squad_no_bank()
dream_team_all <- dream_squad_all_no_bank %>% get_dream_team_no_bank(comment = "All seasons, All leagues")
dream_team_all %>%
   saveRDS(glue("../rds/fantasy/dream_team/no_bank/All-Seasons_All-Leagues.rds"))
dream_team_all %>%
   write_csv(glue("../csv/fantasy/dream_team/no_bank/All-Seasons_All-Leagues.csv"))

# By season, All leagues
seasons <- players_lpsolve %>% distinct(Season)
for (i in 1:nrow(seasons)) {
   dream_squad <- players_lpsolve %>%
      filter(Season == seasons$Season[i]) %>%
      get_dream_squad_no_bank()
   dream_team <- dream_squad %>% get_dream_team_no_bank(comment = seasons$Season[i])
   dream_team %>%
      saveRDS(glue("../rds/fantasy/dream_team/no_bank/{seasons$Season[i]}_All-Leagues.rds"))
   dream_team %>%
      write_csv(glue("../csv/fantasy/dream_team/no_bank/{seasons$Season[i]}_All-Leagues.csv"))
}

# All seasons, By league
leagues <- players_lpsolve %>% distinct(League)
for (i in 1:nrow(leagues)) {
   dream_squad <- players_lpsolve %>%
      filter(League == leagues$League[i]) %>%
      get_dream_squad_no_bank()
   dream_team <- dream_squad %>% get_dream_team_no_bank(comment = leagues$League[i])
   dream_team %>%
      saveRDS(glue("../rds/fantasy/dream_team/no_bank/All-Seasons_{str_replace_all(leagues$League[i], \" \", \"-\")}.rds"))
   dream_team %>%
      write_csv(glue("../csv/fantasy/dream_team/no_bank/All-Seasons_{str_replace_all(leagues$League[i], \" \", \"-\")}.csv"))
}

# By season, by league
for (i in 1:nrow(seasons)) {
   for (j in 1:nrow(leagues)) {
      dream_squad <- players_lpsolve %>%
         filter(Season == seasons$Season[i], League == leagues$League[j]) %>%
         get_dream_squad_no_bank()
      dream_team <- dream_squad %>% get_dream_team_no_bank(comment = str_c(seasons$Season[i], leagues$League[j], sep = " "))
      dream_team %>%
         saveRDS(glue("../rds/fantasy/dream_team/no_bank/{seasons$Season[i]}_{str_replace_all(leagues$League[j], \" \", \"-\")}.rds"))
      dream_team %>%
         write_csv(glue("../csv/fantasy/dream_team/no_bank/{seasons$Season[i]}_{str_replace_all(leagues$League[j], \" \", \"-\")}.csv"))
   }
}

# WITH BANK - ENDING COST
# All seasons, All leagues
dream_team_all <- players_lpsolve %>% get_dream_team_start(comment = "All seasons, All leagues")
dream_team_all %>%
   saveRDS(glue("../rds/fantasy/dream_team/start/All-Seasons_All-Leagues.rds"))
dream_team_all %>%
   write_csv(glue("../csv/fantasy/dream_team/start/All-Seasons_All-Leagues.csv"))

# By season, All leagues
seasons <- players_lpsolve %>% distinct(Season)
for (i in 1:nrow(seasons)) {
   dream_team <- players_lpsolve %>%
      filter(Season == seasons$Season[i]) %>%
      get_dream_team_start(comment = seasons$Season[i])
   dream_team %>%
      saveRDS(glue("../rds/fantasy/dream_team/start/{seasons$Season[i]}_All-Leagues.rds"))
   dream_team %>%
      write_csv(glue("../csv/fantasy/dream_team/start/{seasons$Season[i]}_All-Leagues.csv"))
}

# All seasons, By league
leagues <- players_lpsolve %>% distinct(League)
for (i in 1:nrow(leagues)) {
   dream_team <- players_lpsolve %>%
      filter(League == leagues$League[i]) %>%
      get_dream_team_start(comment = leagues$League[i])
   dream_team %>%
      saveRDS(glue("../rds/fantasy/dream_team/start/All-Seasons_{str_replace_all(leagues$League[i], \" \", \"-\")}.rds"))
   dream_team %>%
      write_csv(glue("../csv/fantasy/dream_team/start/All-Seasons_{str_replace_all(leagues$League[i], \" \", \"-\")}.csv"))
}

# By season, by league
for (i in 1:nrow(seasons)) {
   for (j in 1:nrow(leagues)) {
      dream_team <- players_lpsolve %>%
         filter(Season == seasons$Season[i], League == leagues$League[j]) %>%
         get_dream_team_start(comment = str_c(seasons$Season[i], leagues$League[j], sep = " "))
      dream_team %>%
         saveRDS(glue("../rds/fantasy/dream_team/start/{seasons$Season[i]}_{str_replace_all(leagues$League[j], \" \", \"-\")}.rds"))
      dream_team %>%
         write_csv(glue("../csv/fantasy/dream_team/start/{seasons$Season[i]}_{str_replace_all(leagues$League[j], \" \", \"-\")}.csv"))
   }
}

# WITH BANK - ENDING COST
# All seasons, All leagues
dream_team_all <- players_lpsolve %>% get_dream_team_end(comment = "All seasons, All leagues")
dream_team_all %>%
   saveRDS(glue("../rds/fantasy/dream_team/end/All-Seasons_All-Leagues.rds"))
dream_team_all %>%
   write_csv(glue("../csv/fantasy/dream_team/end/All-Seasons_All-Leagues.csv"))

# By season, All leagues
seasons <- players_lpsolve %>% distinct(Season)
for (i in 1:nrow(seasons)) {
   dream_team <- players_lpsolve %>%
      filter(Season == seasons$Season[i]) %>%
      get_dream_team_end(comment = seasons$Season[i])
   dream_team %>%
      saveRDS(glue("../rds/fantasy/dream_team/end/{seasons$Season[i]}_All-Leagues.rds"))
   dream_team %>%
      write_csv(glue("../csv/fantasy/dream_team/end/{seasons$Season[i]}_All-Leagues.csv"))
}

# All seasons, By league
leagues <- players_lpsolve %>% distinct(League)
for (i in 1:nrow(leagues)) {
   dream_team <- players_lpsolve %>%
      filter(League == leagues$League[i]) %>%
      get_dream_team_end(comment = leagues$League[i])
   dream_team %>%
      saveRDS(glue("../rds/fantasy/dream_team/end/All-Seasons_{str_replace_all(leagues$League[i], \" \", \"-\")}.rds"))
   dream_team %>%
      write_csv(glue("../csv/fantasy/dream_team/end/All-Seasons_{str_replace_all(leagues$League[i], \" \", \"-\")}.csv"))
}

# By season, by league
for (i in 1:nrow(seasons)) {
   for (j in 1:nrow(leagues)) {
      dream_team <- players_lpsolve %>%
         filter(Season == seasons$Season[i], League == leagues$League[j]) %>%
         get_dream_team_end(comment = str_c(seasons$Season[i], leagues$League[j], sep = " "))
      dream_team %>%
         saveRDS(glue("../rds/fantasy/dream_team/end/{seasons$Season[i]}_{str_replace_all(leagues$League[j], \" \", \"-\")}.rds"))
      dream_team %>%
         write_csv(glue("../csv/fantasy/dream_team/end/{seasons$Season[i]}_{str_replace_all(leagues$League[j], \" \", \"-\")}.csv"))
   }
}
