# Test sur les accords cadres

decp_work %>%
  filter(nature == "ACCORD-CADRE") %>%
  mutate(formePrix <- as.factor(formePrix)) %>%
  group_by(formePrix) %>%
  summarise(nombre = n(), total = sum(montantCalcule)) %>%
  mutate(part_nombre = nombre / sum(nombre), part_total = total / sum(total)) %>%
  ggplot(aes(x=formePrix, y=part_total)) + 
  geom_boxplot() +
  theme_minimal() +
  theme(legend.position="bottom", legend.title=element_blank(), 
        plot.title = element_text(size = 10, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 8, hjust = 0.5),
        axis.title.y = element_text(size = 8))

decp_work %>%
  filter(nature == "ACCORD-CADRE") %>%
  filter(!is.na(formePrix)) %>%
  filter(montantCalcule > 20000000) %>%
  mutate(formePrix <- as.factor(formePrix)) %>%
  ggplot(aes(x=formePrix, y=montantCalcule)) + 
  geom_boxplot() +
  theme_minimal() +
  theme(legend.position="bottom", legend.title=element_blank(), 
        plot.title = element_text(size = 10, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 8, hjust = 0.5),
        axis.title.y = element_text(size = 8))

STOP = as.Date("2019-12-31")

decp_work %>%
  mutate(formePrix <- as.factor(formePrix)) %>%
  subset(anneeNotification > 2019) %>%
  filter(montantCalcule < 500000) %>%
  ggplot(aes(x=formePrix, y=montantCalcule)) + 
  geom_boxplot() +
  theme_minimal() +
  theme(legend.position="bottom", legend.title=element_blank(), 
        plot.title = element_text(size = 10, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 8, hjust = 0.5),
        axis.title.y = element_text(size = 8))


