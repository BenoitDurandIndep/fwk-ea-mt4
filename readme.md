# FRAMEWORK MT4 TO DEV AND BACKTEST EA
J'ai fait ce projet pour facilement développer et backtester des Expert Advisors sous MetaTrader 4.
L'objectif était de pouvoir développer un EA complet (entrée/sorties, money management...) en quelques heures voire moins d'une heure pour un EA simple. De pouvoir faire des campagnes massives de backtest en faisant varier les conditions d'entrée sortie, gestion. De pouvoir analyser les résultats des backtests. 
Ce projet peut être utile pour tester toutes les stratégies proposées par les Youtubers et autres vendeurs de rêve.

Au final j'ai fait 6 EA, 180 campagnes de tests, soit 640k scenarii et 1.9M backtests. En utilisant un protocole de backtest propre (en 3 datasets) pour limiter l'overfitting je n'ai pas trouver d'algo faisant plus de 10% de perf par an de façon durable. 
Doonc autant faire du DCA sur un ETF world, c'est plus simple. Je suis passé à Python et au Machine Learning abandonnant MT4.

Ce projet a été initialement fait en français et partiellement traduit en anglais. Si vous êtes intéressés par le code n'hésitez pas à me contacter en cas de question, cf support section

## Repository File Structure
    FWK_EA_MT4
    ├── DB/          		# SQL scripts 
    ├── MQL4/       		# MQL4 code with the MT4's directory structure
        ├── Experts         # 2 EA as examples 
        ├── Include         # librairies of the framweork
        ├── Indicators      # some indicators I developped
        ├── Presets         # 1 preset by EA 
    ├── tester/       		
        ├── files/       	# 1 backtest campaign by EA

## How to install
Copy/Paste MQL4 directory into your MT4 directory (same structure).
If you want to use the DB part, create the database with the script DB/create_db_trading.sql. 

## How to use
** Création d'un EA **
La méthode la plus simple est de partir d'un des deux exemples mis à disposition dans MQL4/Experts
Swing_3_UT_Flex_v1.mq4 : EA pour le forex où il est possible de travailler avec 3 timeframe différents pour déterminer la tendace et trouver les points d'entrée/sortie
Swing_NNFX_Index.mq4 : EA pour indice (ex DAX) qui se base sur la méthode NNFX [Blog NNFX](https://nononsenseforex.com/)

L'adaptation entre les différents types de sous jacents est très facile

Il est recommandé de calculer les indicateurs en passant par la fonction getIndicatorFromParam de MQL4/Include/APIIndicators.mqh (91 fonctions codées). Vous pouvez compléter ce fichier (par copier/coller d'un appel existant)

N'hésitez pas à me contacter si vous avez des questions.

** Backtest par campagne **
Si vous souhaitez faire des campagnes de backtest, par exemple tester 5000 paramétrages d'un coup pour un EA, je vous conseille de passer par la partie base de données pour générer les campagnes de bactest en .csv à mettre en  entrée du module de backtest de MT4 et pour insérer les résultats dans la base afin d'analyser les données.


## Support / Contributing

## Some tips
MT4 est très utilisé par les brokers CFD chypriotes. Si c'est une bonne plateforme pour ces brokers ce n'est pas forcément bon signe pour les utilisateurs. Il est très facile de développer des choses dans cet outil et il est plus ouvert que d'autres plateformes mais la partie backtest n'est pas terrible du tout. De mauvais backtests mènent à des pertes et donc des gains pour le broker CFD.
Je conseille d'utiliser 3 setup de l'outil 1 dev offline, 1 test online sur demo, 1 prod sur reel
Pour le dev offline, il ne doit jamais être connecté au broker et ne sert qu'à faire les devs et les backtests massifs. 
Utilisez vos propres fichiers de données. J'utilise QuantDataManager pour récupérer les historiques de données.

## License
GPL-3.0 license [License](https://github.com/BenoitDurandIndep/Fwk_EA_MT4/blob/main/LICENSE)