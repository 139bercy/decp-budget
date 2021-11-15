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

Le script `filtre_decp_etat` a pour fonction de filtrer les données essentielles de la commande publique (DECP), telles que enrichies par le BercyHub, et publiées en accès ouvert à l'adresse : <https://data.economie.gouv.fr/explore/dataset/decp_augmente/table/>. À la sortie, on ne conserve que les données :

- publiées par l'AIFE
- passées par les acheteurs de l'État 
- postérieures à 2018
- définies comme des marchés 

On enrichit ces données en construisant une mensualité théorique pour chacun des marchés.
