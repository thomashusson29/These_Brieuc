# Figures PNG ultra haute définition

Ce dossier contient les 23 figures du rapport actuel, exportées depuis les
sources PDF vectorielles produites par le code R dans
`these_brieuc_files/figure-pdf/`.

- Résolution d'export : 3000 dpi
- Format : PNG
- Cadrage : identique au PDF source
- Proportions : conservées
- Échelle physique : conservée (conversion directe des points PDF à 3000 dpi)
- Redimensionnement ou recadrage après export : aucun

Les dimensions en pixels sont déterminées directement par la taille de page du
PDF source : `pixels = points / 72 × 3000`.

L'export est reproductible avec le script R suivant :

```sh
Rscript scripts/export_figures_png_3000dpi.R
```

Le script utilise `pdftools::pdf_convert()`, vérifie les dimensions de chaque
PNG et remplace les anciens exports seulement lorsque les 23 conversions ont
réussi.
