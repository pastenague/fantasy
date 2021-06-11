pacman::p_load(tidyverse, dplyr, # Tidyverse
               magrittr, # Pipes
               glue, stringr, stringi, pracma, # String operations
               tictoc, # Timing
               hablar, # Non-astonishing behavior!
               neuralnet, # Neural networks
               lubridate, # Datetime processing
               snakecase, # String casing
               gtools)

source("../../main/r_scripts/rw_utils.R")

project <- "fantasy"
raw_player_seasons <- readRDS("../rds/fantasy/fantasy_analysis.rds")
player_seasons <- raw_player_seasons %>%
   ungroup() %>%
   mutate(position = case_when(str_detect(fantasy_position, "GK") ~ 1,
                               str_detect(fantasy_position, "DEF") ~ 2,
                               str_detect(fantasy_position, "MID") ~ 3,
                               str_detect(fantasy_position, "FWD") ~ 4,
                               TRUE ~ -1)) %>%
   filter(position != -1) %>%
   select(league, season, team,
          player, player_id,
          fantasy_position, position,
          matches, mins,
          goals, assists,
          yellows, reds,
          own_goals, clean_sheets,
          full_score) %>%
   rename(points = full_score)

players_w_prices <- player_seasons %>% mutate(start_price = -1, end_price = -1, next_price = -1)
player_ids <- player_seasons %>% distinct(player_id)

tic("Loading neural networks")
start_price_nn <- readRDS("../rds/fantasy/start_price_nn.rds")
start_price_nn_scales <- readRDS("../rds/fantasy/start_price_nn_scales.rds")
end_price_nn <- readRDS("../rds/fantasy/end_price_nn.rds")
end_price_nn_scales <- readRDS("../rds/fantasy/end_price_nn_scales.rds")
next_price_nn <- readRDS("../rds/fantasy/next_price_nn.rds")
next_price_nn_scales <- readRDS("../rds/fantasy/next_price_nn_scales.rds")

start_maxs <- readRDS("../rds/fantasy/start_maxs.rds")
start_mins <- readRDS("../rds/fantasy/start_mins.rds")
end_maxs <- readRDS("../rds/fantasy/end_maxs.rds")
end_mins <- readRDS("../rds/fantasy/end_mins.rds")
next_maxs <- readRDS("../rds/fantasy/next_maxs.rds")
next_mins <- readRDS("../rds/fantasy/next_mins.rds")
toc()

tic("Price calculation")
players_calc_prices <- c()
for (i in 1:nrow(player_ids)) {
   if (i %% 500 == 0) { print(glue("{i} players completed!")) }
   player_history <- players_w_prices %>%
      filter(player_id == player_ids$player_id[i]) %>%
      arrange(mixedorder(season))

   # Predict start price for initial season
   player_history_factors <- player_history %>%
      select(-league, -season, -team, -player, -player_id, -fantasy_position, -matches, -start_price, -end_price, -next_price)
   player_history_factors <- as_tibble(scale(player_history_factors,
                                             center = start_mins,
                                             scale = start_maxs - start_mins))
   start_price_pred_unscaled <- predict(start_price_nn, player_history_factors %>% slice(1))
   start_price_pred_scaled <-
      (start_price_pred_unscaled*(start_price_nn_scales$max_scale - start_price_nn_scales$min_scale) +
      start_price_nn_scales$min_scale)[1,1]
   start_price_pred_rounded <- round(start_price_pred_scaled/0.5)*(0.5)
   player_history$start_price[1] <- start_price_pred_rounded

   # Predict end price for initial season
   player_history_factors <- player_history %>%
      select(-league, -season, -team, -player, -player_id, -fantasy_position, -matches, -end_price, -next_price)
   player_history_factors <- as_tibble(scale(player_history_factors,
                                             center = end_mins,
                                             scale = end_maxs - end_mins))
   end_price_pred_unscaled <- predict(end_price_nn, player_history_factors %>% slice(1))
   end_price_pred_scaled <-
      (end_price_pred_unscaled*(end_price_nn_scales$max_scale - end_price_nn_scales$min_scale) +
          end_price_nn_scales$min_scale)[1,1]
   end_price_pred_rounded <- round(end_price_pred_scaled/0.1)*(0.1)
   player_history$end_price[1] <- end_price_pred_rounded

   if (nrow(player_history) > 1) {
      for (i in 2:nrow(player_history)) {
         if ((year(as.Date(gsub("[0-9]{2}-", "", player_history$season[i]), format = "%Y")) -
              year(as.Date(gsub("[0-9]{2}-", "", player_history$season[i-1]), format = "%Y"))) == 1) {
            # Predict next season's starting price
            player_history_factors <- player_history %>%
               select(-league, -season, -team, -player, -player_id, -fantasy_position, -matches, -next_price)
            player_history_factors <- as_tibble(scale(player_history_factors,
                                                      center = next_mins,
                                                      scale = next_maxs - next_mins))
            next_price_pred_unscaled <- predict(next_price_nn, player_history_factors %>% slice(i-1))
            next_price_pred_scaled <-
               (next_price_pred_unscaled*(next_price_nn_scales$max_scale - next_price_nn_scales$min_scale) +
                   next_price_nn_scales$min_scale)[1,1]
            next_price_pred_rounded <- round(next_price_pred_scaled/0.5)*(0.5)
            player_history$start_price[i] <- next_price_pred_rounded
         }
         else {
            player_history$start_price[i] <- player_history$start_price[i-1]
         }

         # Predict end price for next season
         player_history_factors <- player_history %>%
            select(-league, -season, -team, -player, -player_id, -fantasy_position, -matches, -end_price, -next_price)
         player_history_factors <- as_tibble(scale(player_history_factors,
                                                   center = end_mins,
                                                   scale = end_maxs - end_mins))
         end_price_pred_unscaled <- predict(end_price_nn, player_history_factors %>% slice(i))
         end_price_pred_scaled <-
            (end_price_pred_unscaled*(end_price_nn_scales$max_scale - end_price_nn_scales$min_scale) +
                end_price_nn_scales$min_scale)[1,1]
         end_price_pred_rounded <- round(end_price_pred_scaled/0.1)*(0.1)
         player_history$end_price[i] <- end_price_pred_rounded
      }
   }

   for (i in 1:nrow(player_history)) {
      # Predict next season's starting price, inline with the current season
      player_history_factors <- player_history %>%
         select(-league, -season, -team, -player, -player_id, -fantasy_position, -matches, -next_price)
      player_history_factors <- as_tibble(scale(player_history_factors,
                                                center = next_mins,
                                                scale = next_maxs - next_mins))
      next_price_pred_unscaled <- predict(next_price_nn, player_history_factors %>% slice(i))
      next_price_pred_scaled <-
         (next_price_pred_unscaled*(next_price_nn_scales$max_scale - next_price_nn_scales$min_scale) +
             next_price_nn_scales$min_scale)[1,1]
      next_price_pred_rounded <- round(next_price_pred_scaled/0.5)*(0.5)
      player_history$next_price[i] <- next_price_pred_rounded
   }

   players_calc_prices <- players_calc_prices %>% bind_rows(player_history)
   # print(player_history %>% select(league, season, team, player, start_price, end_price))
}
toc()

players_calc_prices_joined <- players_calc_prices %>%
   mutate(start_price = round(start_price, digits = 2),
          end_price = round(end_price, digits = 2),
          price_change = round(end_price - start_price, digits = 2)) %>%
   left_join(raw_player_seasons %>%
                ungroup() %>%
                select(1:4,
                       raw_score:bonus_score,
                       key_passes:raw_bonus_p_match),
             by = c("league", "season", "team", "player")) %>%
   rename_at(vars(starts_with("raw_score")), ~ str_replace_all(., "raw_score", "raw_points")) %>%
   rename_at(vars(starts_with("bonus_score")), ~ str_replace_all(., "bonus_score", "bonus_points")) %>%
   rename_at(vars(starts_with("full_score")), ~ str_replace_all(., "full_score", "points")) %>%
   select(-player_id, -position) %>%
   mutate(price_delta = next_price - start_price) %>%
   rename(League = league,
          Season = season,
          Club = team,
          Player = player,
          Position = fantasy_position,
          Matches = matches,
          Mins = mins,
          Goals = goals,
          Assists = assists,
          Yellows = yellows,
          Reds = reds,
          Own_Goals = own_goals,
          Clean_Sheets = clean_sheets,
          Points = points,
          Start_Price = start_price,
          End_Price = end_price,
          Price_Change = price_change,
          Next_Price = next_price,
          Price_Delta = price_delta) %>%
   rename_all(to_title_case) %>% rename_all(to_parsed_case) %>%
   mutate(PP90 = round(Points/(Mins/90), digits = 3),
          PPM = round(Points/Matches, digits = 3),
          PPMM = round(PPM/Start_Price, digits = 3),
          VAPM = round((PPM - 2)/Start_Price, digits = 3),
          VfP = round(sqrt((Points^2)/sqrt(Start_Price -
                                              case_when(str_detect(Position, "GK") | str_detect(Position, "DEF") ~ 4.0,
                                                        str_detect(Position, "MID") | str_detect(Position, "FWD") ~ 4.5))),
                      digits = 3)) %>%
   select(League, Season, Club,
          Player, Position,
          Matches, Mins,
          Goals, Assists,
          Yellows, Reds,
          Clean_Sheets, Own_Goals,
          Points,
          Start_Price, End_Price, Price_Change, Next_Price, Price_Delta,
          PP90, PPM, PPMM, VAPM, VfP, everything()) %>%
   rename_at(vars(contains("Own_Goals")), ~ str_replace_all(., "Own_Goals", "OG")) %>%
   rename_at(vars(contains("Yellows")), ~ str_replace_all(., "Yellows", "YC")) %>%
   rename_at(vars(contains("Reds")), ~ str_replace_all(., "Reds", "RC")) %>%
   rename_at(vars(contains("Key_Passes")), ~ str_replace_all(., "Key_Passes", "KP")) %>%
   rename_at(vars(contains("Clean_Sheets")), ~ str_replace_all(., "Clean_Sheets", "CS"))
players_calc_prices_joined$VfP[which(!is.finite(players_calc_prices_joined$VfP))] <- "-"

source_name <- "fantasy_analysis"
players_calc_prices_joined %>%
   write_data_csv(source_folder = project,
                  source_name = source_name,
                  extension = glue("w_prices_next"))
players_calc_prices_joined %>%
   save_data_RDS(source_folder = project,
                 source_name = source_name,
                 extension = glue("w_prices_next"))
