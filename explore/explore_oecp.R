# Licence par défaut
usethis::use_proprietary_license(copyright_holder = "Secrétariat général des Ministères économiques et financiers")

# Auteur
# Jules Rostand

# Description
# Ce script R propose une exploration dans les données de l'observatoire de la commande publique
# (OECP) de la direction des affaires juridiques (DAJ) de Bercy

# Sources
# OECP, "Chiffres clefs 2020", octobre 2021, s. 5
# https://www.economie.gouv.fr/files/files/directions_services/daj/marches_publics/oecp/recensement/recensement_chiffres2020_20211012.pdf

# Librairies génériques
library(readr)

# Etude des données de l'OECP
# Import des chiffres clefs
read_delim(file = "data/oecp_chiffres-clefs-decp-2020_octobre-2021.csv",
           delim = ";", 
           escape_double = FALSE,
           skip = 1,
           locale = locale(date_names = "fr", decimal_mark = ","), 
           trim_ws = TRUE) -> oecp

# Présentation en Rmarkdown
knitr::kable(oecp, caption = "Chiffres clefs 2021 de l'OECP", 
             align = "lrrr", 
             digits = 2, 
             format.args = list(big.mark = " ", scientific = FALSE))
