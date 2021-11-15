#! /usr/bin/python3
# Filtre pour la commande publique sur les données d'exécution budgétaire de l'État

################# 
## Description ##
#################

# Ce script a pour fonction de filtrer les données d'exécution budgétaire de l'État
# telles que proposées par la direction du Budget (2PERF), afin de ne conserver que les
# dépenses relatives à la commande publique
# A la sortie, on ne conserve que les données :
# 1. de tous les ministères, à l'exception de celui des Armées (modélisation ad-hoc)
# 2. des comptes budgétaires 31, 51 et 52, c'est-à-dire le fonctionnement,
# les dépenses d’investissement corporels, et incorporels
# 3. du compte général
# Les données sont exportées dans le dossier decp-budget_clean

##########################
## Librairies employées ##
##########################

import pandas as pd

# Suppression du message d'erreur SettingWithCopyWarning
# Cf. https://pandas.pydata.org/pandas-docs/stable/user_guide/indexing.html#returning-a-view-versus-a-copy
pd.set_option('mode.chained_assignment', None)

#####################
## Données sources ##
#####################

#  (1) Données d'exécution budgétaire de l'État
budget = pd.read_csv('data/budget/ZBUD51 budget Etat 2020.csv',
					 sep = ";",
					 thousands = " ",
					 decimal = ",",
					 dtype = {'EUR' : float})
#  (2) référentiel des ministères, outil de travail de la DB
referentiel_ministere = pd.read_excel("data/budget/Copie de RestitCalculReferentiel-20211013_13h13m25s-SUPERADM.xls")
#  (3) comptes pour les achats de l'État
filtre_budget_etat = pd.read_excel("data/budget/filtresPCE.xlsx")

# (1) On ne conserve que les informations pertinentes pour le budget de l'État
keep_cols_budget = ['Compte budgétaire', 'Compte général',
					'Référentiel de programmation', 'EUR']
budget_work = budget[keep_cols_budget]

# (2) On conserve la colonne de jointure avec les données budgétaires,
# et le nom du ministère affilié
keep_cols_referentiel_ministere = ['ID_Activite', 'Ministere']
referentiel_ministere_work = referentiel_ministere[keep_cols_referentiel_ministere]

#############
## Filtres ##
#############

# 1. Filtre sur le périmètre ministériel
# On exclut le ministère des Armées de la prévision, celui-ci étant pris en compte dans un modèle *ad-hoc*.
budget_work.rename({'Référentiel de programmation' : 'ID_Activite'},
				   axis = 1,
				   inplace = True)
budget_referentiel = budget_work.merge(referentiel_ministere_work,
									   on = "ID_Activite",
									   how = "left")
budget_civil = budget_referentiel[budget_referentiel['Ministere'] != "Armées"]

# 2. Filtre sur les comptes budgétaires
# On conserve les comptes budgétaires 31, 51 et 52, c'est-à-dire
# le fonctionnement, les dépenses d’investissement corporels, et incorporels

keep_comptes_budgetaires = [31, 51, 52]
budget_civil_fonctionnement = budget_civil[budget_civil['Compte budgétaire'].isin(keep_comptes_budgetaires)]

# 3. Filtre sur les comptes généraux
# On conserve les comptes identifiés par 2PERF

filtre_budget_etat.rename({'Compte' : 'Compte général'},
						  axis = 1,
						  inplace = True)
budget_civil_fonctionnement_general = budget_civil_fonctionnement.merge(filtre_budget_etat,
											on = ['Compte général'],
											how = 'inner')

#############
## Exports ##
#############

# Données sources sur le périmètre des DECP et du budget de l'État
budget_civil_fonctionnement_general.to_csv("data/decp-budget_clean/budget_civil_fonctionnement_general.csv",
							sep = ";",
							index = False,
							decimal = ",",
							float_format = '%.3f',
							encoding = "UTF-8")
