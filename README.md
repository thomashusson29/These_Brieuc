# Analyse statistique — Thèse Brieuc

Ce dépôt contient le code R/Quarto, les rapports générés et les figures
agrégées de l’analyse statistique. Les données individuelles des patients ne
sont pas versionnées.

## Consulter les résultats

- [Rapport web principal](https://thomashusson29.github.io/These_Brieuc/)
- [Rapport du dernier recueil](https://thomashusson29.github.io/These_Brieuc/these_brieuc_last_recueil.html)
- [Figures PNG à 600 dpi](figures_png_hd/)
- [Galerie publique des 23 figures noir et blanc à 600 dpi](https://thomashusson29.github.io/These_Brieuc/figures-noir-blanc/)

## Organisation

- `these_brieuc.qmd` : source principale R/Quarto ;
- `these_brieuc_last_recueil.qmd` : analyse du dernier recueil ;
- `docs/` : fichiers publiés par GitHub Pages ;
- `figures_png_hd/` : 23 figures PNG à 600 dpi ;
- `docs/figures-noir-blanc/` : galerie et 23 exports monochromes à 600 dpi ;
- `scripts/export-figures-noir-blanc.R` : régénération et contrôle automatique des exports monochromes ;
- `version_codex/` : analyses complémentaires.

## Confidentialité

Les fichiers `recueil*.csv`, `recueil*.xlsx` et `.Rhistory` sont exclus par
`.gitignore`. Seuls du code, des statistiques agrégées et des documents de
synthèse doivent être publiés dans ce dépôt.
