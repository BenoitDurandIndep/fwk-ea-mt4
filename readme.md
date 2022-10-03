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

## How to use

## Support / Contributing

## Some tips
MT4 est très utilsiés par les brokers CFD chypriotes. Si c'est une bonne plateforme pour ces brokers ce n'est pas forcément bon signe pour les utilisateurs. Il est très facile de développer des choses dans cet outil et il est plus ouvert que d'autres platefoemes mais la partie backtest n'est pas terrible du tout.
Je conseille d'utiliser 3 setup de l'outil 1 dev offline, 1 test online sur demo, 1 prod sur reel
Pour le dev offline, il ne doit jamais être connecté au borcker et ne sert qu'à faire les devs et les backtests massives. 
Utilisez vos propres fichiers de données. J'utilise QuantDataManager pour récupérer les données.

## License