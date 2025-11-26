library(tidyverse)

#base directory where all of your simulation results are (should have Maynas, National, District base directories) - change this to personal directory
base <- "/Users/cobihenry/Downloads/P_FALCIPARUM/PeruSims/PfalPeru_2"

#CHANGE SELECTION COEFFICIENT THAT YOU WANT TO SEE - automatically reads files 
#such as 0.0, 0.0001, 0.001, 0.01, 0.03, 0.05, 0.07

selection_coefficient <- "0.0" 

#reading selection coefficient directories
simulation_folders <- list(
  full = file.path(base, paste0("simulations_full/hrp2_", selection_coefficient, "_hrp3_", selection_coefficient, "/haplotype_frequencies")),
  Maynas = file.path(base, paste0("simulations_Maynas/hrp2_", selection_coefficient, "_hrp3_", selection_coefficient, "/haplotype_frequencies")),
  district = file.path(base, paste0("simulations_district/hrp2_", selection_coefficient, "_hrp3_", selection_coefficient, "/haplotype_frequencies"))
)

#reading CSV and making a row with replicate ID so individual repliactes can be plotted separately
read_simulations <- function(folder, label) {
  files <- list.files(folder, pattern = "\\.csv$", full.names = TRUE) #files are named like output1.csv, output2.csv, and so on.
  map_dfr(seq_along(files), function(i) {
    read_csv(files[i], show_col_types = FALSE) %>% 
      mutate(replicate = i) #add ID row
  }) %>%
    select(generation, double_deletion, replicate) %>% #only selecting double deletion column, generation, and repID for this plot
    mutate(region = label)
}

#make a dataframe of all geographic regions
sim_data <- bind_rows(
  read_simulations(simulation_folders$full, "National"),
  read_simulations(simulation_folders$Maynas, "Maynas"),
  read_simulations(simulation_folders$district, "District")
)

#creating a hierarchy of geographic regions based on scale for plotting purposes
sim_data$region <- factor(sim_data$region, levels = c("National", "Maynas", "District"))

#reading in the real data (wide orientation)
empirical_data <- read.csv("/Users/cobihenry/Downloads/deletion_freq_wide.csv", sep = ",")

#Average years 2003 and 2004 and merge into year"2003/2004"
observed_adjusted <- empirical_data %>%
  mutate(Year = as.character(year)) %>%
  select(Year, Double.deleted) %>% #only want to see the year and double deletion frequencies over time
  group_by(Year = ifelse(Year %in% c("2003","2004"), "2003/2004", Year)) %>%
  summarise(Double.deleted = mean(Double.deleted), .groups = "drop")

#creating a vector of year orders - we must do this because we have the 2003/2004 entry which is not a regular numerical value, so it is not automatically ordered. 
year_order <- c("2003/2004", "2005", "2006", "2007", "2008", "2009", "2010",
                "2011", "2012", "2013", "2014", "2015", "2016", "2017", "2018")

observed_with_gen <- observed_adjusted %>%
  mutate(Year = factor(Year, levels = year_order)) %>% #setting factored year orders
  arrange(Year) %>%
  mutate(
    #mapping the year to the corresponding simulation generation, assuming 9 generations per year
    generation = case_when(
      Year == "2003/2004" ~ 0, #note that the simulation records frequencies at the END of each generation. We consider the 2003/2004 to be the initial frequency, which effectively generation "0," i.e., before anything happens in the first generation. I did it this way because slim internally records the generation number as 1, and I didn't want to have 2 time points for generation 1 (one at the beginning and one at the end) because it would make plotting complicated
      Year == "2005" ~ 10,
      Year == "2006" ~ 19,
      Year == "2007" ~ 28,
      Year == "2008" ~ 37,
      Year == "2009" ~ 46,
      Year == "2010" ~ 55,
      Year == "2011" ~ 64,
      Year == "2012" ~ 73,
      Year == "2013" ~ 82,
      Year == "2014" ~ 91,
      Year == "2015" ~ 100,
      Year == "2016" ~ 109,
      Year == "2017" ~ 118,
      Year == "2018" ~ 135
    )
  )

#extract initial frequencies at 2003/2004 (all of them start at this frequency at the beginning of generation 1)
starting_freq <- observed_with_gen$Double.deleted[observed_with_gen$Year == "2003/2004"]

#create generation 0 for simulated data (which is the observed starting frequency)
sim_gen0 <- sim_data %>%
  distinct(region, replicate) %>%
  mutate(
    generation = 0, 
    double_deletion = starting_freq
  )

#keep all generations that match observed time points -- the simulation gives us the frequency at the end of generation 1, but since we cant have two time points for the same year, we are only going to plot generation "0" which is the starting frequency. This is because we want to show that all of the simulations start from the same frequency. 
sim_other_gens <- sim_data %>%
  filter(generation %in% observed_with_gen$generation[observed_with_gen$generation > 1]) #removing the point at the "end" of generation 1
#making merged dataset with initial frequencies and rest of data
sim_plot <- bind_rows(sim_gen0, sim_other_gens)

#we have to assign a numerical index to each year, since they are strings and don't have any meaning for plotting ("2003/2004")
observed_with_index <- observed_with_gen %>%
  mutate(Year_Index = row_number())

#we are doing the same thing here with generations so it is easier to map the year and generation
gen_lookup <- observed_with_index %>%
  select(generation, Year_Index)

sim_plot_with_index <- sim_plot %>%
  left_join(gen_lookup, by = "generation")


#defining X axis labels to plot every 2 years
x_labels <- c("2003/2004", "2006", "2008", "2010", "2012", "2014", "2016", "2018")
x_breaks_index <- observed_with_index %>%
  filter(Year %in% x_labels) %>%
  pull(Year_Index)

#creating the plot
plot_fixed <- ggplot(sim_plot_with_index,
                     aes(x = Year_Index, y = double_deletion, group = replicate)) +
  #plotting individual sim replications
  geom_line(alpha = 0.25, color = "#58676D") +
  #plotting points for empirical data
  geom_point(
    data = observed_with_index,
    aes(x = Year_Index, y = Double.deleted),
    color = "#C93312",
    size = 2,
    inherit.aes = FALSE
  ) +
  #plotting lines for empirical data
  geom_line(
    data = observed_with_index,
    aes(x = Year_Index, y = Double.deleted, group = 1),
    color = "#C93312",
    linewidth = 1.2,
    inherit.aes = FALSE
  ) +
  #stacking by geographic region
  facet_wrap(~region, ncol = 1, scales = "fixed",
             labeller = labeller(region = c(
               National = "1) National: Peru",
               Maynas = "2) Province: Maynas",
               District = "3) Districts: Iquitos, San Juan Bautista, Punchana"
             ))) +
  theme_minimal(base_size = 14) +
  theme(strip.text = element_text(face = "bold")) +
  scale_x_continuous(
    limits = c(min(observed_with_index$Year_Index), max(observed_with_index$Year_Index)),
    breaks = x_breaks_index,
    labels = x_labels
  ) +
  labs(
    x = "Year",
    y = "Double deletion frequency"
  )

plot_fixed

ggsave(
  filename = "/Users/cobihenry/Downloads/P_FALCIPARUM/FinalPfalPeruPlots/double_deletion_plot_s03_final.png",
  plot = plot_fixed, 
  width = 7, 
  height = 4.8, 
  units = "in", 
  dpi = 300,
  bg = "white"
)
