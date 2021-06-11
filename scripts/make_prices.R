pacman::p_load(tidyverse, dplyr, # Tidyverse
               magrittr, # Pipes
               glue, stringr, stringi, pracma, # String operations
               tictoc, # Timing
               hablar, # Non-astonishing behavior!
               readr, tools, # File reading/writing
               purrrlyr)

source("../../main/r_scripts/rw_utils.R")
source("../../main/r_scripts/name_utils.R")

combine_players <- function(players_filepaths) {
   seasons <- c("16-17", "17-18", "18-19", "19-20", "20-21")
   season_ids <- c(11, 12, 13, 14, 15)
   all_players <- c()
   i <- 1
   for (player_filepath in players_filepaths) {
      print(player_filepath)
      player_info <- read_csv(player_filepath) %>% mutate(season = seasons[i], season_id = season_ids[i]) %>%
         select(season_id, season, first_name, second_name, web_name,
                element_type, minutes,
                goals_scored, assists,
                yellow_cards, red_cards,
                own_goals, clean_sheets,
                total_points, bonus,
                cost_change_start, now_cost)
      all_players <- all_players %>% bind_rows(player_info)
      i <- i + 1
   }
   all_players <- all_players %>% distinct(.keep_all = TRUE) %>%
      rename(player = web_name,
             position = element_type,
             mins = minutes,
             goals = goals_scored,
             yellows = yellow_cards,
             reds = red_cards,
             points = total_points,
             end_price = now_cost,
             price_change = cost_change_start) %>%
      mutate(full_name = str_c(first_name, second_name, sep = " "),
             start_price = (end_price - price_change)/10,
             price_change = price_change/10,
             end_price = end_price/10) %>%
      select(season_id, season, full_name, player, position,
             mins, goals, assists,
             yellows, reds,
             own_goals, clean_sheets,
             points,
             start_price, end_price, price_change)

   all_players %>% write_data_csv(source_folder = "fantasy",
                                  source_name = "player_prices",
                                  up = 2)
   all_players %>% save_data_RDS(source_folder = "fantasy",
                                  source_name = "player_prices",
                                 up = 2)
   all_players %>%
      select(season_id, season, full_name, player, position) %>%
      mutate(season = str_c("20", season, sep = "")) %>%
      write_data_csv(source_folder = "fantasy",
                    source_name = "player_positions",
                    up = 2)

   all_players %>%
      select(season_id, season, full_name, player, position) %>%
      mutate(season = str_c("20", season, sep = "")) %>%
      save_data_RDS(source_folder = "fantasy",
                    source_name = "player_positions",
                    up = 2)

   return(all_players)
}

tic("Entirety")
all_players <- combine_players(c("../../csv/fantasy/players_raw_16-17.csv",
                                 "../../csv/fantasy/players_raw_17-18.csv",
                                 "../../csv/fantasy/players_raw_18-19.csv",
                                 "../../csv/fantasy/players_raw_19-20.csv",
                                 "../../csv/fantasy/players_raw_20-21.csv"))
toc()
