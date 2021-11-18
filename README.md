# Exploration des DECP et prévision budgétaire

Ce dossier contient le texte et le code de la note étudiant les données essentielles de la commande publique (DECP) au service de l'exercice de prévision budgétaire porté par la direction du Budget.

## Sources et données

Avant de lancer l'exécution des programmes, il convient de disposer des données, selon l’arborescence présentée ci-dessous :

```
├── data
│   ├── budget
│   │   ├── Copie de RestitCalculReferentiel-20211013_13h13m25s-SUPERADM.xls
│   │   ├── filtresPCE.xlsx
│   │   └── ZBUD51 budget Etat 2020.csv
│   ├── decp
│   │   ├── decp_augmente.csv
│   │   └── table corr V2.csv
│   ├── decp-budget_clean
│   ├── oecp
│   │   └── oecp_chiffres-clefs-decp-2020_octobre-2021
```

## Méthodologie et traitement des données

Ce projet nécessite la mise en œuvre d'un étape de sélection manuelle, qui peut être sautée, puis de deux étapes principales, qui opèrent chacun des filtre sur les données essentielles de la commande publique et sur le budget de l'État, afin de construire un périmètre identique.

### Sélection manuelle des données (optionnelle)

La sélection manuelle des données consiste ici à ne sélectionner que les marchés de la commande publique relevant du périmètre de l'État. Pour ce faire, il est nécessaire de disposer d'une liste des acheteurs de l'État. Afin d'établir celle-ci, le script `preparation_filtre_perimetre_etat.py` établit la liste des identifiants et des noms des acheteurs présents dans la base de données. Celle-ci doit être ensuite traitée manuellement, pour spécifier si chaque couple d’identifiant et de nom relève bien de ce périmètre.

### Filtres

#### Filtre sur les données essentielles de la commande publique

Le script `filtre_decp_etat.py` a pour fonction de filtrer les données essentielles de la commande publique (DECP), telles que enrichies par le BercyHub, et publiées en accès ouvert à l'adresse : <https://data.economie.gouv.fr/explore/dataset/decp_augmente/table/>. À la sortie, on ne conserve que les données :

- publiées par l'AIFE
- passées par les acheteurs de l'État 
- postérieures à 2018
- définies comme des marchés 

On enrichit ces données en construisant une mensualité théorique pour chacun des marchés.

#### Filtre sur l'exécution budgétaire

Le script `filtre_budget_etat.py` a pour fonction de filtrer les données d'exécutions budgétaires, telles que fournies par le direction du Budget. À la sortie, on conserve les données : 

- sur l'ensemble du périmètre des ministères, à l'exception de celui des Armées, faisant l'objet d'une modélisation spécifique ;
- sur les comptes budgétaires 31, 51 et 52, c'est-à-dire les dépenses e fonctionnement, les dépenses d’investissement corporels et les dépenses d’investissement incorporels ;
- sur les comptes généraux, en suivant les recommandations de la direction du Budget.

## Exploration et note de synthèse

### Exploration des données

L'exploration de données est menée en R, avec les scripts `explore_oecp.R`, `explore_budget.R` et `explore_decp.R`. Ces scripts représentent une première approche graphique et commentée à ces données. 

### Note de synthèse

La note de synthèse produite ici est disponible dans le fichier `note_decp-budget.Rmd`. Elle propose une estimation de l'effet de la hausse d'un point de l'inflation sur la période du 1er juillet 2021 au 31 juin 2022 pour les dépenses d'achats de l'État. Elle repose sur l'état des données essentielles de la commande publique en novembre 2021, et nécessiterait d'être actualisée dans l'hypothèse d'une nouvelle commande en la matière.

## Ressources

La préparation et le premier traitement des données est effectué en Python (3.8.8). L'exploration des données est menée en R, notamment à l'aide des librairies suivantes : 

- readr : 2.0.2
- dplyr : 1.0.7
- ggplot2 : 3.3.5
- lubridate : 1.8.0
- pastecs : 1.3.21
- GGally : 2.1.2
- ggfortify : 0.4.12
- changepoint : 2.2.2

Rédigée en Rmarkdown (2.11), la note est générée en PDF à l'aide de la chaîne proposée par RStudio, via knitr (1.36) et pandoc (2.12).
