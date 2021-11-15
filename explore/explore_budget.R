# Licence par défaut
usethis::use_proprietary_license(copyright_holder = "Secrétariat général des Ministères économiques et financiers")

# Auteur
# Jules Rostand

# Description
# Ce script R propose une exploration dans les données de l'exécution budgétaire de l'État.

# Librairies génériques
library(readr)
library(dplyr)
library(ggplot2)

# Statistiques descriptives
library(pastecs)

########################
## Import des données ##
########################

# Import des données d'exécution budgétaire
read_delim(file = "data/decp-budget_clean/budget_civil_fonctionnement_general.csv",
           delim = ";",
           col_types = cols(EUR = col_number()), 
           escape_double = FALSE,
           trim_ws = TRUE) -> budget

################################
## Distribution des paiements ##
################################

# Statistiques descriptives
budget %>%
  select(EUR) %>%  
  stat.desc()

# COMMENTAIRE
# On a des valeurs extrêmement élevées, à 4.254000e+12
# Et des valeurs négative, importantes
# Le total est de 102 mille milliards, ce qui va bien au-delà du budget de l'État
# qui est autour de 200 milliards d'euros en recettes nettes

# Etude des sommes totales par libellé des dépenses
budget %>%
  group_by(Ministere) %>%
  summarise(nombre = n(), tot = sum(EUR)) %>%
  arrange(desc(nombre))

# COMMENTAIRE
# En montant, on a essentiellement des NA, avec un ordre de grandeur dix fois supérieur 
# à celui du second poste, le ministère de l'économie et des finances
# En montant, il semble donc difficile de faire une étude par ministère
# En nombre toutefois, c'est le ministère de l'Intérieur qui dispose du nombre
# le plus important de paiements, à plus de 100 000, la moitié moins pour le ministère suivant
# celui de l'action et des comptes publics
# Notons que les MEF ont un petit nombre de paiements, pour gros montants
# Les Sports sont cohérents : peu de paiements, et pour des faibles montants.

# Etude des sommes totales par ministères
budget %>%
  group_by(Libellé) %>%
  summarise(nombre = n(), tot = sum(EUR)) %>%
  arrange(desc(tot))

# COMMENTAIRE
# La catégorie la plus importante en montant est celle des versements aux budgets annexes
# et comptes spéciaux avec 7.44e13 euros ; notons les "honoraires de conseil" en 7e position
# En nombre, il s'agit des "autres services et prestations de services" 
# avec près de 15000 paiements

# Etude des sommes totales par nature
budget %>%
  group_by(Nature) %>%
  summarise(nombre = n(), tot = sum(EUR)) %>%
  arrange(desc(tot))

# COMMENTAIRE
# Les achats sont en seconde position, avec 10 mille milliards de paiements
# Ce qui est bien plus important que les DECP ou les données de l'OECP
# Ce sont aussi les paiements les plus nombreux, avec 260 mille paiements recensés
# A noter que les Routes et les PPP sont dans des catégories à part, de même que
# les dépenses relatives à l'immobilier
