# Licence par défaut
usethis::use_proprietary_license(copyright_holder = "Secrétariat général des Ministères économiques et financiers")

# Auteur
# Jules Rostand

# Description
# Ce script R propose une exploration dans les données essentielles de la commande publique (DECP).
# Celles-ci sont enrichies par le BercyHub; et publiées en open source.
# https://data.economie.gouv.fr/explore/dataset/decp_augmente/information/
# Ces données sont préparées en Python, dans le dossier data/filtres

# Librairies génériques
library(readr)
library(dplyr)
library(ggplot2)

# Statistiques descriptives
library(lubridate)
library(pastecs)

# Détections de ruptures
library(GGally)
library(ggfortify)
library(changepoint)

########################
## Import des données ##
########################

# DECP
read_delim(file = "data/decp-budget_clean/decp_aife_etat_post2018_marche.csv", 
           delim = ";", 
           escape_double = FALSE, 
           col_types = cols(codeCPV_Original = col_character(),
                            codeCPV_division = col_character(), 
                            dateNotification = col_datetime(format = "%Y-%m-%d"), 
                            anneeNotification = col_double(), 
                            datePublicationDonnees = col_datetime(format = "%Y-%m-%d"), 
                            montant = col_number(), montantCalcule = col_number(), 
                            idAcheteur = col_character(), 
                            dateFinCalculee = col_date(format = "%Y-%m-%d"), 
                            mensualiteEstimee = col_number()), 
           locale = locale(date_names = "fr", decimal_mark = ","), 
           trim_ws = TRUE) -> decp_aife_etat_post2018_marche

# DECP avec estimation des paiements mensuels
read_delim(file = "data/decp-budget_clean/mensualite.csv",
           delim = ";", escape_double = FALSE, 
           col_types = cols(dateNotification = col_datetime(format = "%Y-%m-%d"), 
                            anneeNotification = col_double(), 
                            datePublicationDonnees = col_datetime(format = "%Y-%m-%d"), 
                            montant = col_number(), montantCalcule = col_number(), 
                            idAcheteur = col_character(), 
                            dateFinCalculee = col_date(format = "%Y-%m-%d"), 
                            mensualiteEstimee = col_number(),
                            dt = col_datetime(format = "%Y-%m-%d")), 
           locale = locale(date_names = "fr", decimal_mark = ","), 
           trim_ws = TRUE) -> mensualite

###########################
## Distribution des prix ##
###########################

# Statistiques descriptives
decp_aife_etat_post2018_marche %>%
  select(montant, montantCalcule) %>%
  stat.desc()

# COMMENT
# La std.dev ets particulièrement importante, de l'ordre de plusieurs dizaines de millions d'euros, 
# pour une moyenne de 2 millions, et une médiane à 90 000 euros.
# Le montant est trois fois plus variable (std.dev 3.448438e+07) que le montantCalcule (1.321604e+07)

# La distribution des prix s'étudie en log, au vu de l'extrême disparité constatée
# représentation graphique ...
decp_aife_etat_post2018_marche %>%
  select(montant, montantCalcule) %>%
  ggplot(aes(x = log(montantCalcule))) +
    geom_histogram() +
    labs(x = "montant calculé (en log)", y = "densité", 
         title = "Distribution du montant des marchés") +
    theme_minimal() +
    theme(legend.position="top", legend.title=element_blank(), 
          plot.title = element_text(size = 10, face = "bold", hjust = 0.5))

# ... et statistiques descriptives
decp_aife_etat_post2018_marche %>%
  mutate(log_montantCalcule = ifelse(montantCalcule > 0, log(montantCalcule), 0)) %>%
  select(log_montantCalcule) %>%
  stat.desc()

# COMMENT
# En log, celle-ci s'apparente à une loi normale, de moyenne 11,40 et d'écart-type 2,23

# Densité de distribution en long du montant Calculé, par formes de prix
decp_aife_etat_post2018_marche %>%
  ggplot(aes(x=log(montantCalcule), color=formePrix, fill=formePrix)) +
    geom_density(alpha=.2) +
    labs(x = "montant calculé (en log)", y = "densité", 
         title = "Distribution du montant des marchés", 
         subtitle = "par forme de prix") +
    theme_minimal() +
    theme(legend.position="top", legend.title=element_blank(), 
          plot.title = element_text(size = 10, face = "bold", hjust = 0.5), 
          plot.subtitle = element_text(size = 8, hjust = 0.5))

# COMMENT
# Les NA ont une tendance particulièrement importante à représenter des montants élevés

# Densité de distribution en long du montant Calculé, par nature de la commande
decp_aife_etat_post2018_marche %>%
  ggplot(aes(x=log(montantCalcule), color=nature, fill=nature)) +
  geom_density(alpha=.2) +
  labs(x = "montant calculé (en log)", y = "densité", 
       title = "Distribution du montant des marchés", 
       subtitle = "par nature de la commande") +
  theme_minimal() +
  theme(legend.position="top", legend.title=element_blank(), 
        plot.title = element_text(size = 10, face = "bold", hjust = 0.5), 
        plot.subtitle = element_text(size = 8, hjust = 0.5))

# Densité de distribution en long du montant Calculé, par procédure de la commande
decp_aife_etat_post2018_marche %>%
  ggplot(aes(x=log(montantCalcule), color=procedure, fill=procedure)) +
  geom_density(alpha=.2) +
  labs(x = "montant calculé (en log)", y = "densité", 
       title = "Distribution du montant des marchés", 
       subtitle = "par nature de la commande") +
  theme_minimal() +
  theme(legend.position="top", legend.title=element_blank(), 
        plot.title = element_text(size = 10, face = "bold", hjust = 0.5), 
        plot.subtitle = element_text(size = 8, hjust = 0.5))

# COMMENT
# Les procédures adpatées et les procédures avce négociation tendent à correspondre à des montants relativement faibles
# A l'inverse, les dialogues compétitifs concernent les montants plus importants, davantge que les appels d'offres

#########################
## Évolution temporelle ##
#########################

# En nombre
# représentation graphique ...
decp_aife_etat_post2018_marche %>% 
  group_by(date = floor_date(dateNotification, "month")) %>%
  summarise(nombre = n()) %>%
  ggplot() +
    geom_line(aes(x = date, y = nombre)) +
    labs(x = "", y = "", 
         title = "Nombre de marchés mensuels", 
         subtitle = "par date de notification") +
    theme_minimal() +
    theme(legend.position="top", legend.title=element_blank(), 
          plot.title = element_text(size = 10, face = "bold", hjust = 0.5), 
          plot.subtitle = element_text(size = 8, hjust = 0.5))

# ... et statistiques descriptives
decp_aife_etat_post2018_marche %>%
  group_by(date = floor_date(dateNotification, "month")) %>%
  summarise(nombre = n()) %>%
  stat.desc()

# En montant
# représentation graphique ...
decp_aife_etat_post2018_marche %>% 
  group_by(date = floor_date(dateNotification, "month")) %>%
  summarise(somme = sum(montantCalcule)) %>%
  ggplot() +
    geom_line(aes(x = date, y = somme)) +
    labs(x = "", y = "", 
         title = "Montant mensuel des marchés", 
         subtitle = "par date de notification") +
    theme_minimal() +
    theme(legend.position="top", legend.title=element_blank(), 
          plot.title = element_text(size = 10, face = "bold", hjust = 0.5), 
          plot.subtitle = element_text(size = 8, hjust = 0.5))

# ... et statistiques descriptives
decp_aife_etat_post2018_marche %>% 
  group_by(date = floor_date(dateNotification, "month")) %>%
  summarise(somme = sum(montantCalcule)) %>%
  stat.desc()

###########################################
## Caractérisation de la période d'étude ##
###########################################

# Agrégation par mois
# nombre de contrats par date de notification ...
decp_aife_etat_post2018_marche %>%  
  group_by(date = floor_date(dateNotification, "month")) %>%
  mutate(date = as.Date(date)) %>%
  summarise(metrics = n()) -> delta_nombre

# ... et montant des contrats par date de notification
decp_aife_etat_post2018_marche %>%  
  group_by(date = floor_date(dateNotification, "month")) %>%
  mutate(date = as.Date(date)) %>%
  summarise(metrics = sum(montantCalcule)) -> delta_montant

# TODO
# La bibliothèque timetk pourrait permettre le lien avec les dataframe
# https://business-science.github.io/timetk/articles/TK00_Time_Series_Coercion.html

# Transformation des données en format de séries temporelles (ts, pour time series)
# en nombre ...
ts(delta_nombre$metrics, 
   start = c(2018, 1, 1), end = c(2021, 7, 1), 
   freq = 12) -> delta_nombre.metrics

# ... et en montant
ts(delta_montant$metrics, 
   start = c(2018, 1, 1), end = c(2021, 7, 1), 
   freq = 12) -> delta_montant.metrics

# Mise en exergue des périodes de stabilité, avec  des ruptures en moyenne et en variance
# en nombre ...
cpt.meanvar(delta_nombre.metrics, 
            method = "PELT",
            penalty = "BIC", 
            test.stat = "Normal", 
            minseglen=5) -> delta_nombre.metrics.res

# ... et en montant
cpt.meanvar(delta_montant.metrics,
            method = "PELT", 
            penalty = "BIC", 
            test.stat = "Normal", 
            minseglen=5) -> delta_montant.metrics.res

par(mfrow = c(2, 1),  # Ouverture de plusieurs fenêtres
    title(main = "Périodisation, en nombre et en valeur")) 

plot(delta_nombre.metrics.res, 
     main = "En nombre", 
     xlab = "", ylab = "valeur")

plot(delta_montant.metrics.res, 
     main = "En valeur", 
     xlab = "", ylab = "valeur")

# Mise en exergue des moments de ruptures
# en nombre ...
delta_nombre.metrics %>% 
  changepoint:: cpt.meanvar(method = "PELT", 
                            penalty = "BIC", 
                            test.stat = "Normal", 
                            minseglen=5) %>%
  autoplot() + 
    labs(x = "", y = "En nombre", 
         title = "Ruptures en moyenne et en variance dans le nombre de marchés de la commande publique",
         subtitle = "nombre de marchés par mois",
         hjust = 0.5) +
    theme_minimal() + 
    theme(legend.position="bottom", 
          plot.title = element_text(size = 10, face = "bold")) -> p1

# ... et en montant
delta_montant.metrics %>% 
  changepoint:: cpt.meanvar(method = "PELT", 
                            penalty = "BIC", 
                            test.stat = "Normal", 
                            minseglen=5) %>%
  autoplot() +
    labs(x = "", y = "En valeur", 
         title = "Ruptures en moyenne et en variance dans le montant calculé de marchés de la commande publique",
         subtitle = "nombre de marchés par mois",
         hjust = 0.5) +
    theme_minimal() + 
    theme(legend.position = "bottom", 
          plot.title = element_text(size = 10, face = "bold")) -> p2

ggmatrix(list(p1, p2),  # représentation graphique
         nrow = 2, ncol = 1, 
         showYAxisPlotLabels = TRUE) + 
            labs(x = "", y = "", 
                title = "Ruptures en moyenne et en variance dans les marchés de la commande publique",
                subtitle = "nombre et montant des marchés par mois",
                hjust = 0.5) +
            theme_minimal() + 
            theme(legend.position = "bottom", 
                  plot.title = element_text(size = 10, face = "bold"))

# SOURCE
# https://arxiv.org/abs/1101.1438

######################################################
## Nouvelle périodisaiton sur le nombre de contrats ##
######################################################

# On conserve la période située entre la première et la seconde rupture de la série en nombre
STARTING = date_decimal(decimal_date(as.Date("2018-01-01")) + cpts(delta_nombre.metrics.res)[1]/12)
ENDING = date_decimal(decimal_date(as.Date("2018-01-01")) + cpts(delta_nombre.metrics.res)[2]/12)

decp_aife_etat_post2018_marche %>%
  subset(dateNotification > STARTING & dateNotification < ENDING) -> decp_work

mensualite %>%
  subset(dateNotification > STARTING & dateNotification < ENDING) -> mensualite_work

# Représentation graphique du nombre de contrats, avec une mise en avant de la tendance
decp_work %>%
  group_by(date = floor_date(dateNotification, "month")) %>%
  summarise(nombre = n()) %>%
  ggplot(aes(x = date, y = nombre)) +
    geom_line() +
    geom_smooth() +
    ylim(0, 1200) +
    labs(x = "", y = "", 
         title = "Nombre de marchés mensuels (périodisation stable)", 
         subtitle = "par date de notification") +
    theme_minimal() +
    theme(legend.position="top", legend.title=element_blank(), 
          plot.title = element_text(size = 10, face = "bold", hjust = 0.5), 
          plot.subtitle = element_text(size = 8, hjust = 0.5))

# Description de la série temporelle
decp_work %>%
  group_by(date = floor_date(dateNotification, "month")) %>%
  summarise(nombre = n()) %>%
  stat.desc()

#################################
## Formes de prix des contrats ##
#################################

# En agrégat par mois, on compare l'évolution du nombre de marchés publics par forme de prix
decp_work %>%
  group_by(date = floor_date(dateNotification, "month"), formePrix) %>%
  summarise(n = n()) %>%
  ggplot(aes(x = date, y = n, group = formePrix, color = formePrix)) +
    geom_line() +
    labs(x = "", y = "", 
         title = "Nombre des formes de prix des marchés mensuels", 
         subtitle = "par date de notification") +
    theme_minimal() +
    theme(legend.position="top", legend.title=element_blank(), 
          plot.title = element_text(size = 10, face = "bold", hjust = 0.5), 
          plot.subtitle = element_text(size = 8, hjust = 0.5))

# COMMENTAIRE
# Il semble que l'on connaisse à la fin de l'année 2019 une amélioration de la réolte des types de formes de prix
# avec une baisse sensible du nombre de NA

# Répartition du nombre de contrats
decp_work %>% 
  select(c(dateNotification, formePrix)) %>%
  group_by(date = floor_date(dateNotification, "3 months"), formePrix) %>%
  summarise(total = n()) %>%
  mutate(percentage = total / sum(total)) %>%
  ggplot(aes(x = date, y = percentage, fill = formePrix)) + 
    geom_area(alpha = 0.6 , size = 0.1, colour = "black") + 
    scale_fill_brewer(na.value = "grey50") +
    labs(x = "", y = "en pourcentage", 
         title = "Évolution temporelle de la répartition des formes de prix des contrats de la commande publique",
         subtitle = "nombre de contrats trimestriels, par date de notification") + 
    theme_minimal() +
    theme(legend.position="top", legend.title=element_blank(), 
          plot.title = element_text(size = 10, face = "bold", hjust = 0.5), 
          plot.subtitle = element_text(size = 8, hjust = 0.5),
          axis.title.y = element_text(size = 8))

# COMMENTAIRE
# En prenant une échelle trimestrielle, on identifie la part des contrats à prix fermes dans la commande publique
# Sur la période, celle-ci passe de 25% à 12,5%

#####################################################
## La valeur des contrats par leurs formes de prix ##
#####################################################

# COMMENTAIRE
# Si l'on obtient une part du nombre de contrats à prix fermes, 
# à quel point celle-ci est-elle représentative des dépenses ?
# Une première appriche consiste à étudier la veleur totale des formes de prix
# Il faut dès lors interroger ce que représentent les NA
# Celle-ci se complète en étudiant les mensualités

# Valeur par forme de contrat# Valeur par forme de contrat
decp_work %>% 
  select(c(dateNotification, formePrix, montantCalcule)) %>%
  group_by(date = floor_date(dateNotification, "month"), formePrix) %>%
  summarise(total = sum(montantCalcule)) %>%
  ggplot(aes(x = date, y = total, fill=formePrix)) + 
  geom_bar(stat = "identity") + 
  scale_fill_brewer(na.value = "grey50") +
  labs(x = "", y = "en euros", 
       title = "Évolution temporelle de la valeur des formes de prix des contrats de la commande publique",
       subtitle = "montants des contrats mensuels, par date de notification") + 
  theme_minimal() +
  theme(legend.position="bottom", legend.title=element_blank(), 
        plot.title = element_text(size = 10, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 8, hjust = 0.5),
        axis.title.y = element_text(size = 8))  
decp_work %>% 
  select(c(dateNotification, formePrix, montantCalcule)) %>%
  group_by(date = floor_date(dateNotification, "month"), formePrix) %>%
  summarise(total = sum(montantCalcule)) %>%
  ggplot(aes(x = date, y = total, fill=formePrix)) + 
    geom_bar(stat = "identity") + 
    scale_fill_brewer(na.value = "grey50") +
    labs(x = "", y = "en euros", 
         title = "Évolution temporelle de la valeur des formes de prix des contrats de la commande publique",
         subtitle = "montants des contrats mensuels, par date de notification") + 
    theme_minimal() +
    theme(legend.position="bottom", legend.title=element_blank(), 
          plot.title = element_text(size = 10, face = "bold", hjust = 0.5),
          plot.subtitle = element_text(size = 8, hjust = 0.5),
          axis.title.y = element_text(size = 8))  

########################
## Exploration des NA ##
########################

# COMMENTAIRE
# Les NA, bien que représetant peu de contrats, sont associés à des montants particulièrement importants, 
# à des moments spécifiques

decp_work %>% 
  group_by(formePrix) %>%
  summarise(nombre = n(), total = sum(montantCalcule)) %>%
  mutate(part_nombre = nombre / sum(nombre), part_total = total / sum(total))

# COMMENTAIRE
# Plus précisément, il s'agit de 6% des contrats, pour 48% des sommes totales 

decp_work %>%
  filter(is.na(formePrix) == TRUE) %>%
  group_by(natureObjetMarche, nature, `accord-cadrePresume`, procedure) %>%
  summarise(n = n(), total = sum(montantCalcule))

# COMMENTAIRE
# En explorant les données, on observe qu'il s'agit essentiellement d'accords cadres non détectés
# En plus des NA tout court

decp_work %>%
  group_by(nature) %>%
  summarise(n = n(), total = sum(montantCalcule))

# COMMENTAIRE
# Ces accords cadres représentent 7 803 contrats, pour 21 742 144 882 euros
# Les NA représentent 453 contrats pour 278 095 446 euros

decp_work %>%
  group_by(nature, formePrix) %>%
  summarise(n = n(), total = sum(montantCalcule))

# COMMENTAIRE
# On a, pour des commandes publiques de nature d'accord cadre, es forme de prix NA
# On a, pour des commandes publiques de nature NA, des formePrix fermes, etc.
# Les "purs" NA, à la fois en nature et en forme de Prix, sont au nombre de 302
# Ils représentent 171 304 693 euros, ce qui n'est pas majeur
# L'essentiel se joue dans les ACCORD-CADRE dont la forme de prix est inconnue, 
# avec 948 cas, pour 14 137 617 085 euros, près des deux tiers du total des accords cadres

# TODO
# Disribution des prix, avec histogrammes de ces derniers

###################################################
## Exclusion des accords cadres dans les marchés ##
###################################################

#decp_work %>%
#  subset(nature != "ACCORD-CADRE") -> decp_work_marche

#mensualite_work %>%
#  subset(nature != "ACCORD-CADRE") -> mensualite_work_marche

#########################################
## Exclusion des NA des formes de prix ##
#########################################

decp_work %>%
  subset(formePrix != "NA") -> decp_work_marche

mensualite_work %>%
  subset(formePrix != "NA") -> mensualite_work_marche

##########################################
## Etude des formes de prix des marchés ##
##########################################

decp_work_marche %>%
  group_by(date = floor_date(dateNotification, "3 months"), formePrix) %>%
  summarise(n = sum(montantCalcule)) %>%
  ggplot(aes(x = date, y = n, group = formePrix, color = formePrix)) +
    geom_line() +
    labs(x = "", y = "", 
         title = "Évolution temporelle des formes de prix des contrats de la commande publique", 
         subtitle = "somme trimestrielle totale des contrats, par date de notification") +
    theme_minimal() +
    theme(legend.position="top", legend.title=element_blank(), 
          plot.title = element_text(size = 10, face = "bold", hjust = 0.5), 
          plot.subtitle = element_text(size = 8, hjust = 0.5))

decp_work_marche %>% 
  select(c(dateNotification, formePrix, montantCalcule)) %>%
  group_by(date = floor_date(dateNotification, "3 months"), formePrix) %>%
  summarise(total = sum(montantCalcule)) %>%
  mutate(percentage = total / sum(total)) %>%
  ggplot(aes(x=date, y=percentage, fill=formePrix)) + 
    geom_area(alpha=0.6 , size=0.1, colour="black") + 
    scale_fill_brewer(na.value = "grey50") +
    labs(x = "", y = "en pourcentage", 
         title = "Évolution temporelle de la répartition des formes de prix des contrats de la commande publique",
         subtitle = "part trimestrielle des formes de prix des contrats, par date de notification") + 
    theme_minimal() +
    theme(legend.position="top", legend.title=element_blank(), 
          plot.title = element_text(size = 10, face = "bold", hjust = 0.5), 
          plot.subtitle = element_text(size = 8, hjust = 0.5),
          axis.title.y = element_text(size = 8))

# COMMENTAIRE
# On constate une forte évolution dans la répartition des formes de prix
# Pour avoir une idée de la situation actuelle, il faut établir une projection de l'exécution budgétaire
# A cette fin, on se reporte aux mensuzalités construites précedemment

#############################
## Etude des flux mensuels ##
#############################

# Estimation des flux mensuels de l'exécution budgétaire issus des données essentielles de la commande publique
head(mensualite_work_marche)

# TODO : créér les mensualités directement dans R, à ce point
# https://stackoverflow.com/questions/68456807/r-count-monthly-frequency-of-occurrence-between-date-range

# Représentation graphique du montant annuel des mensualités
mensualite_work_marche %>% 
  select(c(dt, formePrix, mensualiteEstimee)) %>%
  group_by(date = floor_date(dt, "year"), formePrix) %>%
  summarise(total = sum(mensualiteEstimee)) %>%
  ggplot(aes(x = date, y = total, fill=formePrix)) + 
    geom_bar(stat = "identity") + 
    scale_fill_brewer(na.value = "grey50") +
    labs(x = "", y = "en euros", 
         title = "Évolution temporelle de la valeur des formes de prix des contrats de la commande publique",
         subtitle = "montants annuel des contrats, par date de paiement des mensualités") + 
    theme_minimal() +
    theme(legend.position="bottom", legend.title=element_blank(), 
          plot.title = element_text(size = 10, face = "bold", hjust = 0.5),
          plot.subtitle = element_text(size = 8, hjust = 0.5),
          axis.title.y = element_text(size = 8))

# On visualise le cycle de 4 ans de la commande publique
# Il serait utile de dupliquer cette distribution des données, pour avoir une sorte de paiements glissant
# avec chaque année une structure de la valeur et de la répartition des formes de prix

###################################
## Cycle de la commande publique ##
###################################

# Construction d'un agrégat annuel des paiements de la commande publique
START_CYCLE = as.Date("2018-12-31")
END_CYCLE = as.Date("2023-01-01")

mensualite_work_marche %>% 
  select(c(dt, formePrix, mensualiteEstimee)) %>%
  group_by(dt = floor_date(dt, "year"), formePrix) %>%
  summarise(nombre = n(), total = sum(mensualiteEstimee)) %>%
  mutate(part_nombre = nombre / sum(nombre), part_montant = total / sum(total)) %>%
  subset(dt > START_CYCLE & dt < END_CYCLE) -> mensualite_work_marche_cycle

# Point de vue diachronique
# En nombre...
mensualite_work_marche_cycle %>% 
  ggplot(aes(x = dt, y = part_nombre, fill=formePrix)) + 
    geom_bar(stat = "identity") + 
    scale_fill_brewer(na.value = "grey50") +
    labs(x = "", y = "en euros", 
         title = "Évolution temporelle du nombre des formes de prix des contrats de la commande publique",
         subtitle = "montants annuel des contrats, par date de paiement des mensualités") + 
    theme_minimal() +
    theme(legend.position="bottom", legend.title=element_blank(), 
          plot.title = element_text(size = 10, face = "bold", hjust = 0.5),
          plot.subtitle = element_text(size = 8, hjust = 0.5),
          axis.title.y = element_text(size = 8))

# ... et en montant
mensualite_work_marche_cycle %>% 
  ggplot(aes(x = dt, y = part_montant, fill=formePrix)) + 
    geom_bar(stat = "identity") + 
    scale_fill_brewer(na.value = "grey50") +
    labs(x = "", y = "en euros", 
         title = "Évolution temporelle de la valeur des formes de prix des contrats de la commande publique",
         subtitle = "montants annuel des contrats, par date de paiement des mensualités") + 
    theme_minimal() +
    theme(legend.position="bottom", legend.title=element_blank(), 
          plot.title = element_text(size = 10, face = "bold", hjust = 0.5),
          plot.subtitle = element_text(size = 8, hjust = 0.5),
          axis.title.y = element_text(size = 8))

# Point de vue synchronique
# Distribution, sur les quatre années, de la part des mensualités par forme de prix ...
mensualite_work_marche_cycle %>%
  mutate(formePrix <- as.factor(formePrix)) %>%
  ggplot(aes(x=formePrix, y=part_nombre)) + 
    geom_boxplot() +
    labs(x = "", y = "part du nombre estimé de paiements", 
         title = "Distribution de la part annuelle du nombre de paiements pour les marchés de la commande publique",
         subtitle = "nombre annuel des estimations de paiements mensuels par formes de prix, pour les quatre années") + 
    theme_minimal() +
    theme(legend.position="bottom", legend.title=element_blank(), 
          plot.title = element_text(size = 10, face = "bold", hjust = 0.5),
          plot.subtitle = element_text(size = 8, hjust = 0.5),
          axis.title.y = element_text(size = 8))

# ... et distribution, sur les quatre années, de la part du montant des mensualités par forme de prix
mensualite_work_marche_cycle %>%
  mutate(ormePrix <- as.factor(formePrix)) %>%
  ggplot(aes(x=formePrix, y=part_montant)) + 
    geom_boxplot() +
    labs(x = "", y = "part du montant estimé des paiements", 
         title = "Distribution de la part annuelle du montant des paiements pour les marchés de la commande publique",
         subtitle = "montant annuel des estimations de paiements mensuels par forme de prix, pour les quatre années") + 
    theme_minimal() +
    theme(legend.position="bottom", legend.title=element_blank(), 
          plot.title = element_text(size = 10, face = "bold", hjust = 0.5),
          plot.subtitle = element_text(size = 8, hjust = 0.5),
          axis.title.y = element_text(size = 8))

# COMMENTAIRE
# Pour le cycle de quatre années identifiés, on peut établir une estimation du nombre de paiements 
# pour les marchés à prix fermes
# à 20% du nombre total de paiements annuels ; en montant, cette estimation est plus incertaine, 
# elle correspond à un intervalle
# de confiance entre 10 et 25%, avec une part exceptionnellement élevée de 35%, qui correspond à l'année 2020
# Une hypothèse conservatrice retiendrait dès lors à un maximum de 20% des marchés dont les prix qui sont fermes
# Cette prévision pourrait s'améliorer dans les années à venir, avec un historique plus important
# Elle reste à vérifier dans l'intervalle temporel concerné, celui qui se coupe en juin 2022
