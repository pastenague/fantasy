pacman::p_load(tidyverse, dplyr, # Tidyverse
               magrittr, # Pipes
               glue, stringr, stringi, pracma, # String operations
               tictoc, # Timing
               hablar, # Non-astonishing behavior!
               readr, tools, # File reading/writing
               ggplot2, ggrepel, # ggplotting tools,
               cowplot, # Plotting tools
               knitr) # Markdown/HTML tables

source("../../main/r_scripts/rw_utils.R")
source("../../main/r_scripts/plot_utils.R")
source("../../main/r_scripts/name_utils.R")

theme_blankPitch <- function(size = 12, background_colour = "#f01d43") {
   theme(
      axis.text.x = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks.length = unit(0, "lines"),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      legend.background = element_rect(fill = background_colour, colour = NA),
      legend.key = element_rect(colour = background_colour, fill = background_colour),
      legend.key.size = unit(1.2, "lines"),
      legend.text = element_text(size = size),
      legend.title = element_text(size = size, face = "bold", hjust = 0),
      strip.background = element_rect(colour = background_colour, fill = background_colour, size = .5),
      panel.background = element_rect(fill = background_colour, colour = background_colour),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.spacing = element_blank(),
      plot.background = element_blank(),
      plot.margin = unit(c(0, 0, 0, 0), "lines"),
      plot.title = element_text(size = size*1.1),
      strip.text.y = element_text(colour = background_colour, size = size, angle = 270),
      strip.text.x = element_text(size = size*1)
   )
}

get_save_loc <- function(dream_team_file) {
   return(dream_team_file %>% str_split("/") %>% pluck(1) %>%
             str_replace(".csv", "_lineup.png") %>% str_replace(".rds", "_lineup.png") %>% str_replace("rds", "viz") %>%
             str_c(collapse = "/"))
}

get_league <- function(save_loc) {
   return(save_loc %>% str_split("/") %>% pluck(1, 7) %>%
             str_replace_all("_lineup.png", "") %>% str_split("_") %>% pluck(1, 2) %>%
             str_replace_all("-", " "))
}

get_season <- function(save_loc) {
   return(save_loc %>% str_split("/") %>% pluck(1, 7) %>%
             str_replace_all("_lineup.png", "") %>% str_split("_") %>% pluck(1, 1) %>%
             str_replace_all("l-S", "l S"))
}

plot_lineup <- function(players,
                        orient = c("landscape", "portrait"),
                        text_color = "#ffffff",
                        pitch_color = "#000000",
                        save_loc,
                        fig_size = 5) {
   team_colors <- "../../csv/data/descriptors/team_descriptors.csv" %>% read_csv(col_types = cols()) %>% rename(Club = team)
   league <- get_league(save_loc)
   league_color <- case_when(league == "Bundesliga" ~ "#f01d43",
                             league == "La Liga" ~ "#c9b928",
                             league == "Ligue 1" ~ "#4597d1",
                             league == "Premier League" ~ "#8446f0",
                             league == "Serie A" ~ "#74d145",
                             league == "All Leagues" ~ "#ffffff")
   season <- get_season(save_loc)
   budget <- case_when(str_detect(save_loc, "no_bank") ~ "Max. Cost: ∞",
                       str_detect(save_loc, "start") ~ "Max. Start Cost: €83.0",
                       str_detect(save_loc, "end") ~ "Max. End Cost: €83.0")

   formation <- list(num_gk = players %>% filter(Position == "GK") %>% nrow(),
                     num_def = players %>% filter(Position == "DEF") %>% nrow(),
                     num_mid = players %>% filter(Position == "MID") %>% nrow(),
                     num_fwd = players %>% filter(Position == "FWD") %>% nrow())
   players_plot <- players %>% bind_cols(format_names(players$Player)) %>%
      select(-Player) %>% rename(Player = short_name) %>%
      group_by(Position) %>% mutate(Member = row_number()) %>% ungroup() %>%
      mutate(Formation = case_when(Position == "GK" ~ formation$num_gk,
                                   Position == "DEF" ~ formation$num_def,
                                   Position == "MID" ~ formation$num_mid,
                                   Position == "FWD" ~ formation$num_fwd)) %>%
      mutate(x = -1, y = -1) %>%
      left_join(team_colors, by = "Club") %>%
      mutate(Number = row_number())
   wiggle_room <- ifelse(orient == "landscape", 1, 1.20)
   player_base <- 2.5
   player_spacing <- ifelse(orient == "landscape", 30, 25)
   pitch_ar <- 1.15 # Aspect ratio
   if (orient == "landscape") {
      pitch_width <- 100
      pitch_height <- pitch_width/pitch_ar
      players_plot <- players_plot %>%
         mutate(x = case_when(Position == "GK" ~ ((-pitch_width/2 + player_base) + (0)*(player_spacing)),
                              Position == "DEF" ~ ((-pitch_width/2 + player_base) + (1)*(player_spacing)),
                              Position == "MID" ~ ((-pitch_width/2 + player_base) + (2)*(player_spacing)),
                              Position == "FWD" ~ ((-pitch_width/2 + player_base) + (3)*(player_spacing)))) %>%
         mutate(y = (wiggle_room*pitch_height)*((Member)*(1/(Formation + 1)) - 1/2))
   }
   else if (orient == "portrait") {
      pitch_height <- 100
      pitch_width <- pitch_height/pitch_ar
      players_plot <- players_plot %>%
         mutate(y = case_when(Position == "GK" ~ ((pitch_height/2 - player_base) - (0)*(player_spacing)),
                              Position == "DEF" ~ ((pitch_height/2 - player_base) - (1)*(player_spacing)),
                              Position == "MID" ~ ((pitch_height/2 - player_base) - (2)*(player_spacing)),
                              Position == "FWD" ~ ((pitch_height/2 - player_base) - (3)*(player_spacing))
                              )
                ) %>%
         mutate(x = (wiggle_room*pitch_width)*((Member)*(1/(Formation + 1)) - 1/2))
   }
   player_text_size <- fig_size*max(c(pitch_height, pitch_width))/(150)
   graphic <- ggplot(players_plot, aes(x, y, shape = Position, fill = factor(Number), color = factor(Number))) +
      theme_nothing() +
      theme(panel.background = element_rect(fill = pitch_color, color = pitch_color)) +
      geom_point(stroke = fig_size/4, size = fig_size/1.5)
   for (i in 1:nrow(players_plot)) {
      cost <- case_when(str_detect(save_loc, "no_bank") ~ glue("€{players_plot$Start_Price[i]} | €{players_plot$End_Price[i]}"),
                        str_detect(save_loc, "start") ~ glue("{{€{players_plot$Start_Price[i]}}} | €{players_plot$End_Price[i]}"),
                        str_detect(save_loc, "end") ~ glue("€{players_plot$Start_Price[i]} | {{€{players_plot$End_Price[i]}}"))
      graphic <- graphic +
         annotate("text",
                  x = players_plot$x[i],
                  y = players_plot$y[i] - 1.00*ifelse(orient == "landscape", (pitch_height/20), (pitch_width/20)),
                  label = glue("{players_plot$Points[i]} ({players_plot$Bonus_Points[i]})"),
                  family = "Lato Black",
                  size = player_text_size,
                  color = text_color) +
         annotate("text",
                  x = players_plot$x[i],
                  y = players_plot$y[i] - 1.825*ifelse(orient == "landscape", (pitch_height/20), (pitch_width/20)),
                  label = cost,
                  family = "Lato Black",
                  size = player_text_size,
                  color = text_color) +
         annotate("text",
                  x = players_plot$x[i],
                  y = players_plot$y[i] - 2.60*ifelse(orient == "landscape", (pitch_height/20), (pitch_width/20)),
                  label = players_plot$Player[i],
                  family = "Lato Black",
                  size = player_text_size,
                  color = text_color) +
         annotate("text",
                  x = players_plot$x[i],
                  y = players_plot$y[i] - 3.35*ifelse(orient == "landscape", (pitch_height/20), (pitch_width/20)),
                  label = players_plot$Club[i],
                  family = "Lato",
                  size = player_text_size/1.15,
                  color = text_color) +
         annotate("text",
                  x = players_plot$x[i],
                  y = players_plot$y[i] - 4.10*ifelse(orient == "landscape", (pitch_height/20), (pitch_width/20)),
                  label = players_plot$Season[i],
                  family = "Lato",
                  size = player_text_size/1.15,
                  color = text_color)
   }
   graphic <- graphic +
      scale_shape_manual(values = 21:24) +
      scale_fill_manual(values = players_plot$primary_color) +
      scale_color_manual(values = players_plot$secondary_color) +
      coord_cartesian(xlim = ifelse(orient == "landscape", 1.15, 1.05)*c(-pitch_width/2, pitch_width/2),
                      ylim = ifelse(orient == "landscape", 1, 1.05)*c(-pitch_height/2, pitch_height/2),
                      expand = FALSE)
   graphic <- graphic +
      statebins:::geom_rrect(mapping = aes(xmin = pitch_width*((0) - (1/2)),
                                           xmax = pitch_width*((1/4) - (1/2)),
                                           ymin = pitch_height*((1/2) - (1/20)),
                                           ymax = pitch_height*((1/2) - (0))),
                             color = "white", fill = "black") +
      statebins:::geom_rrect(mapping = aes(xmin = pitch_width*((0) - (1/2)),
                                           xmax = pitch_width*((1/4) - (1/2)),
                                           ymin = pitch_height*((1/2) - (3/20)),
                                           ymax = pitch_height*((1/2) - (1/20))),
                             color = "white", fill = "black") +
      statebins:::geom_rrect(mapping = aes(xmin = pitch_width*((45/64) - (1/2)),
                                           xmax = pitch_width*((63/64) - (1/2)),
                                           ymin = pitch_height*((1/2) - (1/20)),
                                           ymax = pitch_height*((1/2) - (0))),
                             color = "white", fill = "black") +
      statebins:::geom_rrect(mapping = aes(xmin = pitch_width*((45/64) - (1/2)),
                                           xmax = pitch_width*((63/64) - (1/2)),
                                           ymin = pitch_height*((1/2) - (2/20)),
                                           ymax = pitch_height*((1/2) - (1/20))),
                             color = "white", fill = "black") +
      statebins:::geom_rrect(mapping = aes(xmin = pitch_width*((45/64) - (1/2)),
                                           xmax = pitch_width*((63/64) - (1/2)),
                                           ymin = pitch_height*((1/2) - (3/20)),
                                           ymax = pitch_height*((1/2) - (2/20))),
                             color = "white", fill = "black") +
      annotate("text",
               x = pitch_width*((1/8) - (1/2)),
               y = pitch_height*((1/2) - (1/40)),
               label = glue("Dream Team"),
               family = "Poppins Bold",
               size = player_text_size*1.25,
               color = text_color) +
      annotate("text",
               x = pitch_width*((1/8) - (1/2)),
               y = pitch_height*((1/2) - (1/10.25)),
               label = glue("Total Points:\n{players_plot$Points %>% sum()}"),
               family = "Lato Black",
               size = player_text_size*1.15,
               color = text_color) +
      annotate("text",
               x = pitch_width*((27/32) - (1/2)),
               y = pitch_height*((1/2) - (1/42)),
               label = season,
               family = "Lato Black",
               size = player_text_size*1.25,
               color = text_color) +
      annotate("text",
               x = pitch_width*((27/32) - (1/2)),
               y = pitch_height*((1/2) - (1/13.5)),
               label = league,
               family = "Lato Black",
               size = player_text_size*1.25,
               color = league_color) +
      annotate("text",
               x = pitch_width*((27/32) - (1/2)),
               y = pitch_height*((1/2) - (1/8)),
               label = budget,
               family = "Lato Black",
               size = player_text_size/1.15,
               color = text_color)
   if (orient == "landscape") {
      save_plot(save_loc, plot = graphic, base_height = fig_size, base_width = fig_size*pitch_ar/wiggle_room)
   }
   else if (orient == "portrait") {
      save_plot(save_loc, plot = graphic, base_height = fig_size*pitch_ar/wiggle_room, base_width = fig_size)
   }
   return(graphic)
}

tic("Entirety")
types <- c("no_bank", "start", "end")
# types <- c("no_bank")
seasons <- c("2014-15", "2015-16", "2016-17", "2017-18", "2018-19", "2019-20", "2020-21", "All Seasons")
season_galleries <- c()
leagues <- c("All Leagues", "Bundesliga", "La Liga", "Ligue 1", "Premier League", "Serie A")
lineups_no_bank <- matrix(data = , nrow = 8, ncol = 6,
                          dimnames = list(seasons, leagues))
lineups_start <- matrix(data = , nrow = 8, ncol = 6,
                        dimnames = list(seasons, leagues))
lineups_end <- matrix(data = , nrow = 8, ncol = 6,
                      dimnames = list(seasons, leagues))

for (type in types) {
   season_galleries[[type]] <- glue("{seasons}")
   dream_team_files <- "../../rds/fantasy/dream_team/{type}" %>% glue() %>% list.files() %>%
      lapply(function (x) glue("../../rds/fantasy/dream_team/{type}/{x}")) %>% unlist()
   save_locs <- lapply(dream_team_files, get_save_loc) %>% unlist()
   for (i in 1:length(save_locs)) {
      print(dream_team_files[i])
      players <- readRDS(dream_team_files[i]) %>% slice(-n())
      plot_lineup(players, orient = "portrait", save_loc = save_locs[i])
      league <- get_league(save_locs[i])
      season <- get_season(save_locs[i])
      image_link <- ""
      # image_link <- "Link"
      if (type == "no_bank") { lineups_no_bank[season, league] <- glue("{sum(players$Points)}") }
      else if (type == "start") { lineups_start[season, league] <- glue("{sum(players$Points)}") }
      else if (type == "end") { lineups_end[season, league] <- glue("{sum(players$Points)}") }
      # Sys.sleep(1)
   }
}

lineups_no_bank <- lineups_no_bank %>% `rownames<-`(season_galleries$no_bank)
lineups_start <- lineups_start %>% `rownames<-`(season_galleries$start)
lineups_end <- lineups_end %>% `rownames<-`(season_galleries$end)

# fantasy_blurb <- "../../blurbs/fantasy/dream_teams_start.md"
# "# Unlimited Budget:" %>% write_lines(fantasy_blurb, append = FALSE, sep = "\n\n")
# lineups_no_bank %>%
#    kable(col.names = leagues, row.names = TRUE, align = "c") %>% str_c(collapse = "\n") %>%
#    write_lines(fantasy_blurb, append = TRUE, sep = "\n\n")
# "# Maximum Starting Budget €83.0:" %>% write_lines(fantasy_blurb, append = TRUE, sep = "\n\n")
# lineups_start %>%
#    kable(col.names = leagues, row.names = TRUE, align = "c") %>% str_c(collapse = "\n") %>%
#    write_lines(fantasy_blurb, append = TRUE, sep = "\n\n")
# "# Maximum Ending Budget €83.0:" %>% write_lines(fantasy_blurb, append = TRUE, sep = "\n\n")
# lineups_end %>%
#    kable(col.names = leagues, row.names = TRUE, align = "c") %>% str_c(collapse = "\n") %>%
#    write_lines(fantasy_blurb, append = TRUE, sep = "")
# saveRDS(lineups_no_bank, "../../blurbs/fantasy/lineups_no_bank.rds")
# saveRDS(lineups_start, "../../blurbs/fantasy/lineups_start.rds")
# saveRDS(lineups_end, "../../blurbs/fantasy/lineups_end.rds")
toc()
