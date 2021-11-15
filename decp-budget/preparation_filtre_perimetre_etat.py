# Préparation du filtre sur le périmètre de l'État
# Ce script a pour fonction de proposer une liste des couples (idAcheteur, nomAcheteur), 
# à même de nourir une table de sélection des couples relevant du seul périmètre de l'État. 

# Librairies
import pandas as pd

# Données sources
decp = pd.read_csv("data/decp/decp_augmente.csv", 
	sep = ";", 
	dtype={'idAcheteur': str}, 
	encoding="UTF-8")

# On ne conserve que les données provenant de l'Agence pour l'information financière de l'ÉTat (AIFE)
decp_aife = decp[decp['source'] == 'data.gouv.fr_aife']

# On ne conserve que les informations (vraiment) essentielles à ce stade, en excluant notamment la géolocalisation, etc.
keep_cols_work = ['type', 'natureObjetMarche', 'objetMarche',
		'codeCPV_Original', 'codeCPV', 'codeCPV_division', 'referenceCPV',
		'dateNotification', 'anneeNotification', 'moisNotification',
		'datePublicationDonnees', 'dureeMois', 'dureeMoisEstimee',
		'dureeMoisCalculee', 'montant', 'nombreTitulaireSurMarchePresume',
		'montantCalcule', 'formePrix', 'nature',
		'accord-cadrePresume', 'procedure', 'idAcheteur', 'sirenAcheteurValide',
		'nomAcheteur']
decp_work = decp_aife[keep_cols_work]

# On ne conserve que les colonnes nécessaires à l'identification de l'acheteur
keep_cols_acheteur = ['idAcheteur',
'nomAcheteur', 'libelleRegionAcheteur',
'libelleDepartementAcheteur',
'codePostalAcheteur', 'libelleCommuneAcheteur']
decp_acheteur = decp_aife[keep_cols_acheteur]

# Regroument par identifiant et nom des acheteurs
res = decp_acheteur.groupby(['idAcheteur', 'nomAcheteur']).all().sort_values('idAcheteur')

# Export en CSV
res.to_csv("data/decp-budget_clean/select_acheteurs_grouped.csv",
	sep = ";", 
	encoding="UTF-8")
