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
│   ├── oecp
│   │   └── oecp_chiffres-clefs-decp-2020_octobre-2021
```

## Méthodologie et traitement des données

Ce projet nécessite la mise en œuvre d'un étape de sélection manuelle, qui peut être sautée, puis de deux étapes principales.

### Sélection manuelle des données (optionnelle)

La sélection manuelle des données consiste ici à ne sélectionner que les marchés de la commande publique relevant du périmètre de l'État. Pour ce faire, il est nécessaire de disposer d'une liste des acheteurs de l'État. Afin d'établir celle-ci, le script `filtre_budget_etat.py` établit la liste des identifiants et des noms des acheteurs présents dans la base de données. Celle-ci doit être ensuite traitée manuellement, pour spécifier si chaque couple d’identifiant et de nom relève bien de ce périmètre.