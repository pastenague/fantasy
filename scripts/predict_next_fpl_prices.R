pacman::p_load(tidyverse, dplyr, # Tidyverse
               magrittr, # Pipes
               glue, stringr, stringi, pracma, # String operations
               tictoc, # Timing
               hablar, # Non-astonishing behavior!
               neuralnet, # Neural networks
               gtools)

source("../../main/r_scripts/rw_utils.R")

# tic("Entirety")
project = "fantasy"
prices_full <- readRDS("../rds/player_prices.rds") %>% filter(mins > 500)

tic("Loading neural networks")
start_price_nn <- readRDS("../rds/start_price_nn.rds")
start_price_nn_scales <- readRDS("../rds/start_price_nn_scales.rds")
end_price_nn <- readRDS("../rds/end_price_nn.rds")
end_price_nn_scales <- readRDS("../rds/end_price_nn_scales.rds")
next_price_nn <- readRDS("../rds/next_price_nn.rds")
next_price_nn_scales <- readRDS("../rds/next_price_nn_scales.rds")

start_maxs <- readRDS("../rds/start_maxs.rds")
start_mins <- readRDS("../rds/start_mins.rds")
end_maxs <- readRDS("../rds/end_maxs.rds")
end_mins <- readRDS("../rds/end_mins.rds")
next_maxs <- readRDS("../rds/next_maxs.rds")
next_mins <- readRDS("../rds/next_mins.rds")
toc()

tic("Calculating prices")
next_prices <- prices_full %>%
   select(-season_id, -season, -full_name, -player, -price_change) %>%
   scale(center = next_mins, scale = next_maxs - next_mins) %>%
   predict(next_price_nn, .) %>%
   `*`(next_price_nn_scales$max_scale - next_price_nn_scales$min_scale) %>%
   `+`(next_price_nn_scales$min_scale) %>%
   `/`(0.5) %>% round() %>% `*`(0.5)
prices_full %<>% cbind(next_price = next_prices) %>% mutate(price_boost = next_price - start_price)
prices_recent <- prices_full %>% filter(season_id == max(prices_full$season_id)) %>%
   select(-season_id, -season, -full_name) %>%
   mutate(position = case_when(position == 1 ~ "GK",
                               position == 2 ~ "DEF",
                               position == 3 ~ "MID",
                               position == 4 ~ "FWD")) %>%
   # rename(OG = own_goals, CS = clean_sheets, G = goals, A = assists, YC = yellows, RC = reds, pos = position) %>%
   select(-price_change, -own_goals, -clean_sheets, -goals, -assists, -yellows, -reds, -mins)
prices_full %<>% select(-season_id)
toc()

prices_full %>%
   write_data_csv(source_folder = project,
                  source_name = "fpl_prices_all_seasons",
                  up = 2)
prices_full %>%
   save_data_RDS(source_folder = project,
                 source_name = "fpl_prices_all_seasons",
                 up = 2)

prices_recent %>%
   write_data_csv(source_folder = project,
                  source_name = "fpl_prices_recent_season",
                  up = 2)
prices_recent %>%
   save_data_RDS(source_folder = project,
                 source_name = "fpl_prices_recent_season",
                 up = 2)

prices_recent %>% arrange(desc(price_boost)) %>% filter(price_boost != 0) %>% knitr::kable() %>%
   write_lines(glue("../md/{project}/fpl_prices_recent_season.md"),
               append = FALSE)
