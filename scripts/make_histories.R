pacman::p_load(tidyverse, dplyr, # Tidyverse
               magrittr, # Pipes
               glue, stringr, stringi, pracma, # String operations
               tictoc, # Timing
               hablar, # Non-astonishing behavior!
               readr, tools, # File reading/writing
               lubridate, # Datetime processing
               stringdist) # String matching

source("../../main/r_scripts/rw_utils.R")
source("../../main/r_scripts/name_utils.R")

tic("Entirety")
seasons <- c("2016-17", "2017-18", "2018-19", "2019-20", "2020-21")
season_ids <- c(11, 12, 13, 14, 15)
players <- c()
player_positions <- readRDS("../../rds/fantasy/player_positions.rds") %>%
   select(season, full_name, position) %>%
   mutate(full_name = stri_trans_general(str = full_name, id = "Latin-ASCII"))

tic("Naming and pre-processing")
for (i in 1:length(seasons)) {
   folder_names <- list.files(glue("../../csv/fantasy/fpl_history/{seasons[i]}/players/"))
   full_names <- sapply(folder_names, get_player_name) %>% t() %>% as_tibble() %>% unnest(c(first_name, last_name, full_name))
   season_players <- full_names %>%
      mutate(folder_name = folder_names) %>%
      mutate(season_id = season_ids[i], season = seasons[i]) %>%
      select(season, everything())
   players %<>% bind_rows(season_players)
}
toc()

tic("Position assignment")
players %<>%
   mutate(has_history = file.exists(glue("../../csv/fantasy/fpl_history/{season}/players/{folder_name}/history.csv"))) %>%
   filter(has_history == TRUE) %>%
   group_by(full_name) %>% slice(which.max(season_id)) %>% ungroup() %>% mutate(position = -1) %>%
   mutate(full_name = stri_trans_general(str = full_name, id = "Latin-ASCII"))

for (i in 1:nrow(players)) {
   player_position_history <- player_positions %>% filter(full_name == players$full_name[i])
   if (nrow(player_position_history) > 0) {
      player_position_year <- player_position_history %>% filter(season == players$season[i])
      if (nrow(player_position_year) > 0) {
         players$position[i] <- player_position_year$position[1]
      }
      else {
         for (j in length(seasons):1) {
            player_position_year <- player_position_history %>% filter(season == seasons[j])
            if (nrow(player_position_year) > 0) {
               players$position[i] <- player_position_year$position[1]
               break
            }
         }
      }
   }
}
toc()

players %<>% filter(position != -1)

player_histories <- c()
for (i in 1:nrow(players)) {
   player_history <- glue("../../csv/fantasy/fpl_history/{players$season[i]}/players/{players$folder_name[i]}/history.csv") %>%
      read_csv(col_types = cols()) %>% as_tibble()
   player_recent_cost <- -1
   if (file.exists(glue("../../csv/fantasy/fpl_history/{players$season[i]}/players/{players$folder_name[i]}/gw.csv"))) {
      player_gw <- glue("../../csv/fantasy/fpl_history/{players$season[i]}/players/{players$folder_name[i]}/gw.csv") %>%
         read_csv(col_types = cols()) %>% as_tibble()
      player_recent_cost <- player_gw$value[1]/10
   }
   if ("season" %in% colnames(player_history) & !"season_name" %in% colnames(player_history)) {
      player_history %<>% rename(season_name = season)
   }
   player_history %<>%
      mutate(first_name = players$first_name[i],
             last_name = players$last_name[i],
             full_name = players$full_name[i],
             position = players$position[i]) %>%
      rename(mins = minutes,
             goals = goals_scored,
             yellows = yellow_cards,
             reds = red_cards,
             points = total_points,
             end_price = end_cost,
             start_price = start_cost) %>%
      mutate(start_price = round(round((start_price/10)/(0.5))*(0.5), digits = 1),
             end_price = round(round((end_price/10)/(0.1))*(0.1), digits = 1),
             price_change = round(end_price - start_price, digits = 1)) %>%
      select(season_name,
             full_name, position,
             mins,
             goals, assists,
             yellows, reds,
             own_goals, clean_sheets,
             points,
             start_price, end_price, price_change) %>%
      arrange(gtools::mixedorder(season_name)) %>%
      mutate(next_price = 0)
   if (nrow(player_history) == 1) { next }
   for (j in 1:(nrow(player_history) - 1)) {
      if (year(as.Date(gsub("[0-9]{2}-", "", player_history$season_name[j + 1]), format = "%Y")) -
          year(as.Date(gsub("[0-9]{2}-", "", player_history$season_name[j]), format = "%Y")) == 1)
         player_history$next_price[j] = player_history$start_price[j + 1]
   }
   if (player_recent_cost > 0 &
       (year(as.Date(gsub("[0-9]{2}-", "", players$season[i] %>% str_replace("-", "/")), format = "%Y")) -
        year(as.Date(gsub("[0-9]{2}-", "", player_history$season_name[nrow(player_history)]), format = "%Y")) == 1)
   ) {
      player_history$next_price[nrow(player_history)] <- player_recent_cost
   }
   player_history <- player_history %>% mutate(price_boost = next_price - start_price)
   player_histories <- player_histories %>% bind_rows(player_history)
}

player_histories <- player_histories %>% filter(next_price != 0)

player_histories %>% write_data_csv(source_folder = "fantasy",
                                    source_name = "player_histories",
                                    up = 2)
player_histories %>% save_data_RDS(source_folder = "fantasy",
                                   source_name = "player_histories",
                                   up = 2)
