# exemple 1
L’analyse principale a comparé les médecins intéressés à devenir MCS à ceux non intéressés. Les variables catégorielles ont été décrites en effectifs et pourcentages et comparées par test du χ² de Pearson, avec recours au test exact de Fisher lorsque les effectifs attendus étaient < 5 ; les échelles ordinales ont été traitées comme catégorielles. Les variables continues ont été décrites en médiane et intervalle interquartile. Des dichotomisations préspécifiées ont été appliquées lorsque pertinent (par exemple âge < 50 ans, durée d’installation < 10 ans). Les pourcentages ont été calculés sur les observations non manquantes (exclusion au cas par cas). Les tests étaient bilatéraux, avec un seuil de significativité de 0,05, sans ajustement pour comparaisons multiples. Une régression logistique pénalisée de Firth a ensuite estimé les associations ajustées sur un nombre restreint de covariables présélectionnées à partir des analyses univariées ; les résultats sont rapportés en odds ratios avec leurs intervalles de confiance à 95 % et p-values. Les analyses ont été réalisées avec R, version 4.5.1 (R Foundation for Statistical Computing, Vienne, Autriche).

# exemple 2
L’appariement des patientes a été réalisé via des identifiants partiels (âge et commune de
résidence), puis validé manuellement. Seules les paires complètes ont été retenues pour l’analyse
principale. Le critère de jugement principal est le score global, recalculé à partir des réponses à
l’aide d’une clé de correction et d’un barème prédéfinis : les points des 8 questions sont sommés
(total /40), puis divisés par 2 pour obtenir une note sur 20. Pour les questions à réponses
multiples, un point est attribué à chaque proposition correcte selon le barème ; aucune pénalité
n’est appliquée en cas de réponses supplémentaires non attendues. Les scores par question (en
points, de 0 au maximum de la question) et le gain individuel (Q2 − Q1) ont également été
calculés ; pour comparer des questions de barèmes différents, les gains ont aussi été exprimés
en pourcentage du barème.
Les variables quantitatives sont décrites par moyenne ± écart-type (et médiane [IQR] lorsque
pertinent) et les variables qualitatives par effectif et pourcentage. L’effet global de l’intervention
sur le score global a été évalué en comparant Q1 et Q2 au sein des mêmes participantes, à
l’aide d’un test t apparié (Student), dans le sens “après > avant”, en appliquant une procédure
4
de bootstrap (1000 réplications) pour s’affranchir de l’hypothèse de normalité des données. La
pertinence clinique a été décrite en (i) comparant le gain moyen au seuil de 3 points et (ii)
calculant la proportion de participantes atteignant un gain >= 3 points (avec intervalle de
confiance binomial). Un test de signe (binomial) a également été utilisé pour comparer la
fréquence des améliorations (gain > 0) à celle des diminutions (gain < 0), en ignorant les
égalités. Enfin, une analyse exploratoire a estimé la probabilité d’un gain >= 3 points en
fonction du score initial, de l’âge (approché en années) et de la langue du questionnaire (français
vs créole), via une régression logistique multivariable.
Des analyses exploratoires ont étudié l’hétérogénéité des scores initiaux et des gains selon la
tranche d’âge (tests de Kruskal–Wallis et modèle linéaire ajusté sur le score initial). Enfin,
des analyses par question ont comparé les scores avant/après (tests appariés) et décrit les
distributions de scores en points (proportions avec intervalles de confiance de Wilson), avec des
tests de McNemar par niveau de score (p < 0,05). Ces analyses “par question” sont présentées
à titre exploratoire, sans correction de multiplicité. Toutes les analyses ont été conduites sous
R 4.5.2, avec un seuil de significativité de 5% (alpha = 0,05) et des intervalles de confiance à
95%