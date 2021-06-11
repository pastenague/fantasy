pacman::p_load(tidyverse, dplyr, # Tidyverse
               magrittr, # Pipes
               glue, stringr, stringi, pracma, # String operations
               tictoc, # Timing
               hablar, # Non-astonishing behavior!
               neuralnet, # Neural networks
               gtools)

source("../../main/r_scripts/rw_utils.R")

tic("Entirety")
prices_full <- readRDS("../rds/player_prices.rds")

# START PRICE PREDICTION
prices <- prices_full %>% select(-season, -season_id, -player, -full_name, -end_price, -price_change)

cut_index <- sample(1:nrow(prices), round(0.75*nrow(prices)))
maxs <- apply(prices, 2, max)
mins <- apply(prices, 2, min)
print(maxs)
print(mins)
maxs[-length(maxs)] %>%
   save_data_RDS(source_folder = "fantasy",
                 source_name = "start_maxs",
                 up = 2)
mins[-length(mins)] %>%
   save_data_RDS(source_folder = "fantasy",
                 source_name = "start_mins",
                 up = 2)

maxs %>%
   save_data_RDS(source_folder = "fantasy",
                 source_name = "end_maxs",
                 up = 2)
mins %>%
   save_data_RDS(source_folder = "fantasy",
                 source_name = "end_mins",
                 up = 2)

prices_scaled <- as_tibble(scale(prices, center = mins, scale = maxs - mins))
prices_train <- prices_scaled %>% slice(cut_index)
prices_test <- prices_scaled %>% slice(-cut_index)

n <- colnames(prices_train)
f <- as.formula(paste("start_price ~", paste(n[!n %in% "start_price"], collapse = " + ")))
tic("Neural network training")
start_price_nn <- neuralnet(f, data = prices_train, hidden = 3, linear.output = T)

start_price_nn %>%
   save_data_RDS(source_folder = "fantasy",
                 source_name = "start_price_nn",
                 up = 2)
list(min_scale = min(prices$start_price), max_scale = max(prices$start_price)) %>%
   save_data_RDS(source_folder = "fantasy",
                 source_name = "start_price_nn_scales",
                 up = 2)

toc()
# plot(start_price_nn)

pr.nn <- predict(start_price_nn, prices_test %>% select(-start_price))
pr.nn_ <- pr.nn*(max(prices$start_price) - min(prices$start_price)) + min(prices$start_price)
pr.nn_ <- pr.nn_ %>% as.list() %>% unlist()
pr.nn_ <- round(pr.nn_/0.5)*(0.5)
test.r <- (prices_test$start_price)*(max(prices$start_price)-min(prices$start_price)) + min(prices$start_price)
MSE.nn <- sum((test.r - pr.nn_)^2)/nrow(prices_test)
print(glue("MSE (starting price): {MSE.nn}"))

prices_pred_price <- prices_full %>% slice(-cut_index) %>% mutate(pred_start_price = pr.nn_,
                                                                  pred_start_price_error = pred_start_price - start_price)

# END PRICE PREDICTION
prices <- prices_full %>% select(-season, -season_id, -player, -full_name, -price_change)

maxs <- apply(prices, 2, max)
mins <- apply(prices, 2, min)
prices_scaled <- as_tibble(scale(prices, center = mins, scale = maxs - mins))
prices_train <- prices_scaled %>% slice(cut_index)
prices_test <- prices_scaled %>% slice(-cut_index)

n <- colnames(prices_train)
f <- as.formula(paste("end_price ~", paste(n[!n %in% "end_price"], collapse = " + ")))
tic("Neural network training")
end_price_nn <- neuralnet(f, data = prices_train, hidden = 3, linear.output = T)

end_price_nn %>%
   save_data_RDS(source_folder = "fantasy",
                 source_name = "end_price_nn",
                 up = 2)
list(min_scale = min(prices$end_price), max_scale = max(prices$end_price)) %>%
   save_data_RDS(source_folder = "fantasy",
                 source_name = "end_price_nn_scales",
                 up = 2)
toc()

pr.nn <- predict(end_price_nn, prices_test %>% select(-end_price))
pr.nn_ <- pr.nn*(max(prices$end_price) - min(prices$end_price)) + min(prices$end_price)
pr.nn_ <- pr.nn_ %>% as.list() %>% unlist()
pr.nn_ <- round(pr.nn_/0.1)*(0.1)
test.r <- (prices_test$end_price)*(max(prices$end_price) - min(prices$end_price)) + min(prices$end_price)
MSE.nn <- sum((test.r - pr.nn_)^2)/nrow(prices_test)
print(glue("MSE (ending price): {MSE.nn}"))

prices_pred_price <- prices_pred_price %>% mutate(pred_end_price = pr.nn_,
                                                  pred_end_price_error = round((pred_end_price - end_price)/(0.1))*(0.1))

prices_pred_price <- prices_pred_price %>%
   mutate(pred_price_change = pred_end_price - pred_start_price,
          pred_price_change_error = round((pred_price_change - price_change)/0.1)*(0.1)) %>%
   select(1:13,
          start_price, pred_start_price, pred_start_price_error,
          end_price, pred_end_price, pred_end_price_error,
          price_change, pred_price_change, pred_price_change_error)

prices_pred_price %>%
   write_data_csv(source_folder = "fantasy",
                  source_name = "players_pred_start_end_prices",
                  up = 2)
prices_pred_price %>%
   save_data_RDS(source_folder = "fantasy",
                 source_name = "players_pred_start_end_prices",
                 up = 2)

toc()
