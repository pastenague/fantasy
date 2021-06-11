pacman::p_load(tidyverse, dplyr, # Tidyverse
               magrittr, # Pipes
               glue, stringr, stringi, pracma, # String operations
               tictoc, # Timing
               hablar, # Non-astonishing behavior!
               readr, tools) # File reading/writing

source("../../main/r_scripts/rw_utils.R")
source("../../main/r_scripts/player_id_utils.R")

RDS_filepath <- "../../main/rds/data/match/combined/us_match_data_all_1_to_7_seasons.rds"
project <- "fantasy"

tic("Loading")
match_info <- read_data(RDS_filepath) %>% as_tibble()
toc()

tic("Assigning player positions")
gk_pos <- c("GK")
def_pos <- c("DMR", "DR", "DC", "DL", "DML")
mid_pos <- c("DMC", "MR", "MC", "ML", "AMR", "AMC", "AML")
fwd_pos <- c("FWR", "FW", "FWL")
sub_pos <- c("Sub")

player_positions <- match_info %>%
   filter(!position %in% sub_pos) %>%
   mutate(fantasy_position = case_when(position %in% gk_pos ~ "GK",
                                       position %in% def_pos ~ "DEF",
                                       position %in% mid_pos ~ "MID",
                                       position %in% fwd_pos ~ "FWD",
                                       TRUE ~ "")) %>%
   group_by(season, team, player, player_id) %>%
   summarise(fantasy_position = first(names(sort(table(fantasy_position), decreasing = TRUE))))
toc()

tic("Calculating points and bonus points")
fantasy_match_info <- match_info %>%
   left_join(player_positions, by = c("season", "team", "player", "player_id")) %>%
   filter(!is.na(fantasy_position)) %>%
   mutate(clean_sheets = if_else((!position %in% sub_pos) & (mins >= 60) & (opponent_final == 0),
                                 1,
                                 0)) %>%
   mutate(raw_score = case_when(fantasy_position == "GK" ~
                                       if_else(mins >= 60, 2, 1) +
                                       6*goals + 3*assists +
                                       4*clean_sheets +
                                       (-1)*floor(opponent_final/2) +
                                       (-1)*yellows +
                                       (-3)*reds +
                                       (-2)*own_goals,
                                    fantasy_position == "DEF" ~
                                       if_else(mins >= 60, 2, 1) +
                                       6*goals + 3*assists +
                                       4*clean_sheets +
                                       (-1)*floor(opponent_final/2) +
                                       (-1)*yellows +
                                       (-3)*reds +
                                       (-2)*own_goals,
                                    fantasy_position == "MID" ~
                                       if_else(mins >= 60, 2, 1) +
                                       5*goals + 3*assists +
                                       1*clean_sheets +
                                       (-1)*yellows +
                                       (-3)*reds +
                                       (-2)*own_goals,
                                    fantasy_position == "FWD" ~
                                       if_else(mins >= 60, 2, 1) +
                                       4*goals + 3*assists +
                                       (-1)*yellows +
                                       (-3)*reds +
                                       (-2)*own_goals,
                                    TRUE ~ -1)) %>%
   mutate(raw_bonus = case_when(fantasy_position == "GK" ~
                                   if_else(mins >= 60, 6, 3) +
                                   14*goals + 12*assists +
                                   15*clean_sheets +
                                   (-3)*floor(opponent_final/2) +
                                   (-3)*yellows +
                                   (-9)*reds +
                                   (-6)*own_goals +
                                   (1)*key_passes +
                                   round((10)*xG_buildup, 0),
                                fantasy_position == "DEF" ~
                                   if_else(mins >= 60, 6, 3) +
                                   14*goals + 12*assists +
                                   12*clean_sheets +
                                   (-3)*floor(opponent_final/2) +
                                   (-3)*yellows +
                                   (-9)*reds +
                                   (-6)*own_goals +
                                   (1)*key_passes +
                                   round((10)*xG_buildup, 0),
                                fantasy_position == "MID" ~
                                   if_else(mins >= 60, 6, 3) +
                                   16*goals + 9*assists +
                                   (-3)*yellows +
                                   (-9)*reds +
                                   (-6)*own_goals +
                                   (1)*key_passes +
                                   round((10)*xG_buildup, 0),
                                fantasy_position == "FWD" ~
                                   if_else(mins >= 60, 6, 3) +
                                   18*goals + 9*assists +
                                   (-3)*yellows +
                                   (-9)*reds +
                                   (-6)*own_goals +
                                   (1)*key_passes +
                                   round((6)*xG_buildup, 0),
                                TRUE ~ -1)) %>%
   group_by(season, league, match_id) %>%
   arrange(desc(raw_bonus), .by_group = TRUE) %>%
   mutate(bonus_rank = rank(-raw_bonus, ties.method = "average"),
          bonus_score = case_when((bonus_rank < 2) ~ 3,
                                  (bonus_rank < 3) & (bonus_rank >= 2) ~ 2,
                                  (bonus_rank < 4) & (bonus_rank >= 3) ~ 1,
                                  TRUE ~ 0),
          full_score = raw_score + bonus_score) %>%
   select(season, league,
          year, month, day,
          match_id,
          team_final, opponent_final,
          team, opponent,
          team_id, h_a,
          player_id, player,
          position, fantasy_position,
          mins,
          raw_score, raw_bonus, bonus_rank, bonus_score, full_score,
          goals, assists, GA,
          xG, xA, xGA,
          shots, key_passes, SKP,
          xG_buildup,
          clean_sheets,
          own_goals,
          yellows, reds) %>%
   ungroup() %>%
   arrange(season, league, year, month, day, match_id)
fantasy_match_info$player_id %<>% as.character
toc()

toc("Post-processing")
# quick_fantasy_info <- fantasy_match_info %>%
#    select(season, league,
#           year, month, day,
#           match_id,
#           team_final, opponent_final,
#           team, opponent,
#           player,
#           position, fantasy_position,
#           mins,
#           raw_score, raw_bonus, bonus_rank, bonus_score, full_score,
#           goals, assists,
#           key_passes,
#           xG_buildup,
#           clean_sheets,
#           own_goals,
#           yellows, reds) %>%
#    rename(pos = position, f_pos = fantasy_position,
#           kp = key_passes,
#           y = yellows, r = reds, xGB = xG_buildup, og = own_goals,
#           GS = team_final, GC = opponent_final)

fantasy_players <- fantasy_match_info %>%
   mutate(matches = 1) %>%
   rename(team_final_scored = team_final, team_final_conceded = opponent_final) %>%
   group_by(season, league, team, player, player_id, fantasy_position) %>%
   summarise_if(is.numeric, sum) %>%
   mutate(avg_bonus_rank = round(bonus_rank/matches, 3),
          xG_buildup = round(xG_buildup, 3)) %>%
   select(season, league, team, player, player_id, fantasy_position,
          mins, matches,
          raw_score, bonus_score, full_score,
          goals, assists, clean_sheets,
          yellows, reds, own_goals,
          key_passes, xG_buildup,
          team_final_scored, team_final_conceded,
          raw_bonus, avg_bonus_rank) %>%
   mutate_at(vars(raw_score:raw_bonus),
             .funs = list(p_90 = ~ round(. / (mins/90), 3),
                          p_match = ~ round(. / (matches), 3)))
toc()

tic("Saving")

# fantasy_match_info %>%
#    write_data_csv(source_folder = project,
#                   source_name = source_name,
#                   extension = glue("{project}_matches"))
# fantasy_match_info %>%
#    save_data_RDS(source_folder = project,
#                  source_name = source_name,
#                  extension = glue("{project}_matches"))

fantasy_players %>%
   write_data_csv(source_folder = project,
                  source_name = glue("{project}_analysis"))
fantasy_players %>%
   save_data_RDS(source_folder = project,
                 source_name = glue("{project}_analysis"))
toc()
