pacman::p_load(tidyverse, dplyr, # Tidyverse
               magrittr, # Pipes
               glue, stringr, stringi, pracma, # String operations
               tictoc, # Timing
               hablar, # Non-astonishing behavior!
               neuralnet, # Neural networks
               gtools)

source("../../main/r_scripts/rw_utils.R")

# tic("Entirety")
prices_full <- readRDS("../rds/player_histories.rds")

# NEXT SEASON PRICE PREDICTION
prices <- prices_full %>% select(-season_name, -full_name, -price_change, -price_boost)

cut_index <- sample(1:nrow(prices), round(0.75*nrow(prices)))
maxs <- apply(prices, 2, max)
mins <- apply(prices, 2, min)
print(maxs)
print(mins)
maxs[-length(maxs)] %>%
   save_data_RDS(source_folder = "fantasy",
                 source_name = "next_maxs",
                 up = 2)
mins[-length(mins)] %>%
   save_data_RDS(source_folder = "fantasy",
                 source_name = "next_mins",
                 up = 2)
prices_scaled <- as_tibble(scale(prices, center = mins, scale = maxs - mins))
prices_train <- prices_scaled %>% slice(cut_index)
prices_test <- prices_scaled %>% slice(-cut_index)

n <- colnames(prices_train)
f <- as.formula(paste("next_price ~", paste(n[!n %in% "next_price"], collapse = " + ")))
tic("Neural network training")
next_price_nn <- neuralnet(f, data = prices_train, hidden = 3, linear.output = T)

next_price_nn %>%
   save_data_RDS(source_folder = "fantasy",
                 source_name = "next_price_nn",
                 up = 2)
list(min_scale = min(prices$next_price), max_scale = max(prices$next_price)) %>%
   save_data_RDS(source_folder = "fantasy",
                 source_name = "next_price_nn_scales",
                 up = 2)
toc()

sum((round(((predict(next_price_nn,
               prices_train %>% select(-next_price))*(max(prices$next_price) - min(prices$next_price)) +
          min(prices$next_price)) %>% as.list() %>% unlist())/0.5)*0.5 -
        ((prices_train$next_price)*(max(prices$next_price) - min(prices$next_price)) +
            min(prices$next_price)))^2)/nrow(prices_train) -> MSE_train
print(glue("MSE (train): {MSE_train}"))

sum((round(((predict(next_price_nn,
                     prices_test %>% select(-next_price))*(max(prices$next_price) - min(prices$next_price)) +
                min(prices$next_price)) %>% as.list() %>% unlist())/0.5)*0.5 -
        ((prices_test$next_price)*(max(prices$next_price) - min(prices$next_price)) +
            min(prices$next_price)))^2)/nrow(prices_test) -> MSE_test
print(glue("MSE (test): {MSE_test}"))

prices_pred_price <- prices_full %>% slice(-cut_index) %>% mutate(pred_next_price = pr.nn_,
                                                                  pred_next_price_error = pred_next_price - next_price)
prices_pred_price <- prices_pred_price %>%
   select(1:13,
          next_price, pred_next_price, pred_next_price_error)

prices_pred_price %>% write_data_csv(source_folder = "fantasy",
                                     source_name = "players_pred_next_season_prices",
                                     up = 2)
prices_pred_price %>% save_data_RDS(source_folder = "fantasy",
                                    source_name = "players_pred_next_season_prices",
                                    up = 2)

# toc()
