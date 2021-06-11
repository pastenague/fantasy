pacman::p_load(tidyverse, dplyr, # Tidyverse
               magrittr, # Pipes
               glue, stringr, stringi, pracma, # String operations
               tictoc, # Timing
               hablar, # Non-astonishing behavior!
               readr, tools) # File reading/writing

player_histories <- function(players) {
   histories <- readRDS("../../rds/fantasy/fantasy_analysis_w_prices_next.rds")
   for (player in players) {
      blurb <- glue("Fantasy History for {player}")
      player_history <- histories %>% filter(Player == player)
      latest_next_price <- player_history %>% slice(n()) %>% pull(Next_Price)
      player_history %<>%
         select(Season, Club,
                Position,
                Matches, Mins,
                Goals, Assists,
                YC, RC,
                CS,
                Points, Bonus_Points_p_Match,
                Start_Price, End_Price) %>%
         rename(Pos = Position, G = Goals, A = Assists, Pts = Points, `BPM^*` = Bonus_Points_p_Match) %>%
         mutate(Season = str_sub(Season, start = -5L))
      if (player_history %>% distinct(Club) %>% pull(Club) %>% length() == 1) {
         blurb %<>% str_c(glue("({player_history %>% distinct(Club) %>% pull(Club)})"), sep = " ")
         player_history %<>% select(-Club)
      }
      if (player_history %>% distinct(Pos) %>% pull(Pos) %>% length() == 1) {
         blurb %<>% str_c(glue("[{player_history %>% distinct(Pos) %>% pull(Pos)}]"), sep = " ")
         player_history %<>% select(-Pos)
      }
      player_file <- glue("../../md/fantasy/players/{player %>% str_replace_all(\" \", \"-\")}.md")
      blurb %>% write_lines(player_file, append = FALSE, sep = ":\n\n")
      player_history %>% knitr::kable() %>% write_lines(player_file, append = TRUE)
      str_c("\n**Predicted start price for 21-22 season**:", glue("{latest_next_price}"), sep = " ") %>% write_lines(player_file, append = TRUE)
      "\nPlease see [my post](https://redd.it/it7my7) for details on how this is calculated. In short: FPL scoring rules + approximation of bonus points, and neural networks predict the prices based on historical FPL data).\n\n---\n\n^* BPM = Avg. Bonus Points per Match" %>%
         write_lines(player_file, append = TRUE)
   }
}

players <- c("Romain Perraud", "Javi Galán")
player_histories(players)
