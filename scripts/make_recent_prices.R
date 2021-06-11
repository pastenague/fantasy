pacman::p_load(tidyverse, dplyr, # Tidyverse
               magrittr, # Pipes
               glue, stringr, stringi, pracma, # String operations
               tictoc, # Timing
               hablar, # Non-astonishing behavior!
               readr, tools, # File reading/writing
               lubridate, # Datetime processing
               stringdist) # String matching

most_recent_season <- "2020-21"
players <- "../../csv/fantasy/fpl_history/{most_recent_season}/players_raw.csv" %>% glue() %>% read_csv(col_types = cols())
"../../csv/fantasy/fpl_history/{most_recent_season}/players/" %>% glue() %>% list.files() -> has_folder
players %<>%
   mutate(folder_name = glue("{first_name}_{second_name}_{id}"),
          folder_path = glue("../../csv/fantasy/fpl_history/{most_recent_season}/players/{folder_name}/gw.csv")) %>%
   arrange(folder_name) %>%
   slice(which((folder_name %>% stri_trans_general(id = "Latin-ASCII")) %in%
            (has_folder %>% stri_trans_general(id = "Latin-ASCII"))))
for (i in 1:nrow(players)) {
   value_csv <- tibble(value = players$now_cost[i]) %>%
      write_csv(players$folder_path[i])
}
