#! /usr/bin/python3
# Filtre sur les données de la commande publique

################# 
## Description ##
#################

# Ce script a pour fonction de filtrer les données essentielles de la commande publique (DECP)
# telles que enrichies par le BercyHub, et publiées en accès ouvert
# https://data.economie.gouv.fr/explore/dataset/decp_augmente/table/
# A la sortie, on ne conserve que les données :
# 1. publiées par l'AIFE
# 2. passées par les acheteurs de l'État 
# 3. postérieures à 2018
# 4. définies comme des marchés 
# On enrichit ces données en construisant une mensualité théorique
# pour chacun des marchés.

##########################
## Librairies employées ##
##########################

import pandas as pd
import datetime
from dateutil.relativedelta import relativedelta

# Suppression du message d'erreur SettingWithCopyWarning
# Cf. https://pandas.pydata.org/pandas-docs/stable/user_guide/indexing.html#returning-a-view-versus-a-copy
pd.set_option('mode.chained_assignment', None)

#####################
## Données sources ##
#####################

decp = pd.read_csv("data/decp/decp_augmente.csv",
	sep = ";", 
	dtype={'idAcheteur': str, 'montant': float}, 
	encoding="UTF-8")
filtre_decp_etat = pd.read_csv("data/decp/table corr V2.csv",
	sep = ";", 
	dtype = {'idAcheteur' : str})

# On ne conserve que les informations (vraiment) essentielles à ce stade, en excluant notamment la géolocalisation, etc.
keep_cols_decp_work = ['source', 'type', 'natureObjetMarche', 'objetMarche',
	'codeCPV_Original', 'codeCPV', 'codeCPV_division', 'referenceCPV',
	'dateNotification', 'anneeNotification', 'moisNotification',
	'datePublicationDonnees', 'dureeMois', 'dureeMoisEstimee',
	'dureeMoisCalculee', 'montant', 'nombreTitulaireSurMarchePresume',
	'montantCalcule', 'formePrix', 'nature',
	'accord-cadrePresume', 'procedure', 'idAcheteur', 'sirenAcheteurValide',
	'nomAcheteur']
decp_work = decp[keep_cols_decp_work]

#############
## Filtres ##
#############

# 1. Conservation des données provenant de l'Agence pour l'information financière de l'État (AIFE)
decp_aife = decp_work[decp_work['source'] == 'data.gouv.fr_aife']

# 2. Au sein des données de l'AIFE, filtrage sur le seul périmètre État, d'après la table établie par 2PERF (DB)
keep_cols_filtre_decp_etat = ['idAcheteur', 'nomAcheteur', 'OKKO']
filtre_decp_etat_work = filtre_decp_etat[keep_cols_filtre_decp_etat]
decp_aife_etat = decp_aife.merge(filtre_decp_etat_work, 
	on = ['idAcheteur', 'nomAcheteur'], 
	how = 'inner')
decp_aife_etat = decp_aife_etat[decp_aife_etat['OKKO'] == 'OK']

# 3. Filtrage pour les marchés dont la date de notification est postérieure à 2018
decp_aife_etat.loc[:, 'dateNotification'] = pd.to_datetime(decp_aife_etat['dateNotification'], 
	infer_datetime_format=True)  # Conversion des dates au format Pandas
decp_aife_etat_post2018 = decp_aife_etat[decp_aife_etat['dateNotification'] > datetime.datetime(2018, 1, 1)]

# 4. Au sein des données de l'AIFE sur le périmètre État, conserver uniquement les marchés
decp_aife_etat_post2018_marche = decp_aife_etat_post2018[decp_aife_etat_post2018["type"] == "Marché"]

#####################
## Enrichissements ##
#####################

# Création de la date de fin de contrat calculée, en additionnant la date de notification et le nombre de mois calculé
# Cette information est utile pour l'étude des marchés à prix fermes arrivant  échéance après juin 2022
# elle sert également pour le calcul des mensualités sur le budget
get_dateFinCalculee = lambda x: x['dateNotification'] + relativedelta(months = int(x['dureeMoisCalculee']))
decp_aife_etat_post2018_marche['dateFinCalculee'] = decp_aife_etat_post2018_marche.apply(get_dateFinCalculee, axis=1)

# Construction d'une mensualité théorique estimée
decp_aife_etat_post2018_marche['mensualiteEstimee'] = decp_aife_etat_post2018_marche['montantCalcule'] / decp_aife_etat_post2018_marche['dureeMoisCalculee']

# Transposition d'un dataframe d'extremum en fréquence
# Source : https://stackoverflow.com/a/57644703
time_series = (decp_aife_etat_post2018_marche[['dateNotification', 'dateFinCalculee']]
               .apply(lambda x: pd.date_range(*x, freq='1M'), # Fréquence mensuelle
                      axis=1)
               .explode()
               .rename('dt') # Nom de l'index
              )

mensualite = decp_aife_etat_post2018_marche.join(time_series).reset_index(drop=True) # jointure sur l'index

# Conserver la fréquence mensuelle, avec les paiements relatifs à cette dernière
keep_cols_mensualite = ['dt', 'mensualiteEstimee']
mensualite_work = mensualite[keep_cols_mensualite]

#############
## Exports ##
#############

# Données sources sur le périmètre des DECP et du budget de l'État
decp_aife_etat_post2018_marche.to_csv("data/decp-budget_clean/decp_aife_etat_post2018_marche.csv",
	sep = ";", 
	index=False, 
	decimal=",", 
	float_format='%.3f', 
	encoding="UTF-8")

# Mensualisations, et agrégats sur mensualisations
mensualite.to_csv("data/decp-budget_clean/mensualite.csv",
	sep = ";", 
	index=False, 
	decimal=",", 
	float_format='%.3f', 
	encoding="UTF-8")
