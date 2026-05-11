import re

with open("these_brieuc.qmd", "r") as f:
    text = f.read()

# Find the start of the sensitivity analysis
idx = text.find('## Analyses de sensibilité : "Gold Standard fort"')
if idx != -1:
    base_text = text[:idx]
else:
    base_text = text

new_section = """## Analyses de sensibilité : "Gold Standard fort"

Cette section présente les performances diagnostiques des tests en utilisant un critère de jugement plus strict pour les cas positifs. Le "Gold Standard fort" est défini par la positivité conjointe du Gold Standard principal (Examen clinique + IRM) **et** d'une infiltration thérapeutique positive.

Afin d'explorer cet impact de manière exhaustive, nous présentons deux approches pour la définition du groupe "Négatif".

### Approche 1 : Négatifs = Négatifs initiaux

Dans cette première approche, nous conservons uniquement les vrais "Négatifs" tels que définis par le Gold Standard principal. Les patients ayant un Gold Standard principal positif mais sans infiltration thérapeutique confirmant le diagnostic sont **exclus**.
Cette analyse porte sur un effectif réduit de **42 patients** (18 cas positifs "forts" et 24 cas négatifs initiaux).

```{r}
#| label: strong-gs-a1-prep
#| echo: false

df_a1 <- df %>%
  mutate(GS_strong = case_when(
    Gold_Standard_main == "Positif" & Resultat_Inf == "Positif" ~ "Positif",
    Gold_Standard_main == "Negatif" ~ "Negatif",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(GS_strong))

get_perf_strong <- function(test_val, gs_val) {
  tab <- table(factor(test_val, levels=c("Positif", "Negatif")), 
               factor(gs_val, levels=c("Positif", "Negatif")))
  
  tp <- tab[1,1]; fp <- tab[1,2]; fn <- tab[2,1]; tn <- tab[2,2]
  
  se_res <- binom.test(tp, tp + fn)
  sp_res <- binom.test(tn, tn + fp)
  vpp_res <- binom.test(tp, tp + fp)
  vpn_res <- binom.test(tn, tn + fn)
  
  se <- tp / (tp + fn)
  sp <- tn / (tn + fp)
  lr_p <- if(sp < 1) se / (1 - sp) else Inf
  lr_n <- if(sp > 0) (1 - se) / sp else Inf
  
  data.frame(
    Se = as.numeric(se_res$estimate), Se_low = se_res$conf.int[1], Se_high = se_res$conf.int[2],
    Sp = as.numeric(sp_res$estimate), Sp_low = sp_res$conf.int[1], Sp_high = sp_res$conf.int[2],
    VPP = as.numeric(vpp_res$estimate), VPP_low = vpp_res$conf.int[1], VPP_high = vpp_res$conf.int[2],
    VPN = as.numeric(vpn_res$estimate), VPN_low = vpn_res$conf.int[1], VPN_high = vpn_res$conf.int[2],
    LRp = lr_p, LRn = lr_n
  )
}

format_table_strong <- function(d) {
  rownames(d) <- NULL
  d %>%
    mutate(
      `Se [IC95%]` = paste0(round(Se, 3), " [", round(Se_low, 3), " ; ", round(Se_high, 3), "]"),
      `Sp [IC95%]` = paste0(round(Sp, 3), " [", round(Sp_low, 3), " ; ", round(Sp_high, 3), "]"),
      `VPP [IC95%]` = paste0(round(VPP, 3), " [", round(VPP_low, 3), " ; ", round(VPP_high, 3), "]"),
      `VPN [IC95%]` = paste0(round(VPN, 3), " [", round(VPN_low, 3), " ; ", round(VPN_high, 3), "]"),
      `LR+` = round(as.numeric(LRp), 2),
      `LR-` = round(as.numeric(LRn), 2)
    ) %>%
    select(1, `Se [IC95%]`, `Sp [IC95%]`, `VPP [IC95%]`, `VPN [IC95%]`, `LR+`, `LR-`)
}

# 1. Tests individuels
perf_u1_a1 <- get_perf_strong(df_a1$U1_E1, df_a1$GS_strong)
perf_u2a_a1 <- get_perf_strong(df_a1$U2a_E1, df_a1$GS_strong)
perf_u2b_a1 <- get_perf_strong(df_a1$U2b_E1, df_a1$GS_strong)
perf_u3_a1 <- get_perf_strong(df_a1$U3_E1, df_a1$GS_strong)

df_perf_indiv_a1 <- rbind(
  data.frame(Test = "ULNT1", perf_u1_a1),
  data.frame(Test = "ULNT2a", perf_u2a_a1),
  data.frame(Test = "ULNT2b", perf_u2b_a1),
  data.frame(Test = "ULNT3", perf_u3_a1)
)

# 2. Combinaisons
comb_list_filtered <- combination_tests[sapply(combination_tests, length) >= 2]
df_perf_comb_a1 <- do.call(rbind, lapply(comb_list_filtered, function(cols) {
  test_label <- paste(unname(test_labels[cols]), collapse = " + ")
  res_comb <- apply(sapply(cols, function(cc) df_a1[[cc]] == "Positif"), 1, all)
  res_comb_str <- ifelse(res_comb, "Positif", "Negatif")
  perf <- get_perf_strong(res_comb_str, df_a1$GS_strong)
  data.frame(Combinaison = test_label, perf)
}))

# 3. Score
df_a1$score <- df_a1$U1_E1_positif + df_a1$U2a_E1_positif + df_a1$U2b_E1_positif + df_a1$U3_E1_positif
df_perf_score_a1 <- do.call(rbind, lapply(1:4, function(s) {
  res_score <- ifelse(df_a1$score >= s, "Positif", "Negatif")
  perf <- get_perf_strong(res_score, df_a1$GS_strong)
  data.frame(Seuil = paste0("Score >= ", s), perf)
}))

tbl_indiv_a1 <- format_table_strong(df_perf_indiv_a1)
tbl_comb_a1 <- format_table_strong(df_perf_comb_a1)
tbl_score_a1 <- format_table_strong(df_perf_score_a1)
```

#### Performances des tests et comparaisons (Approche 1)

Dans cette approche, le groupe des "Négatifs" n'a pas changé par rapport à l'analyse principale. Ainsi, **la spécificité reste strictement identique**. Seule la sensibilité est modifiée (et généralement améliorée, car on se concentre sur les cas pathologiques les plus certains).

```{r}
#| label: tbl-strong-a1-indiv
#| tbl-cap: "Approche 1 - Performances diagnostiques test par test"
kable(tbl_indiv_a1, booktabs = TRUE, align = "c", row.names = FALSE) %>%
  kable_styling(latex_options = c("hold_position", "scale_down"), font_size = 8)
```

```{r}
#| label: tbl-comp-a1-sensi
#| tbl-cap: "Approche 1 - Comparaison de la sensibilité : GS principal vs GS fort"
comp_sensi_a1 <- data.frame(
  Test = c("ULNT1", "ULNT2a", "ULNT2b", "ULNT3"),
  `Se GS princ.` = c(u1_performance$Se_IC95, u2a_performance$Se_IC95, u2b_performance_summary$Se, u3_performance_summary$Se),
  `Se GS fort` = tbl_indiv_a1$`Se [IC95%]`,
  check.names = FALSE
)
kable(comp_sensi_a1, booktabs = TRUE, align = "c", row.names = FALSE) %>%
  kable_styling(latex_options = "hold_position", full_width = FALSE)
```

```{r}
#| label: tbl-strong-a1-comb
#| tbl-cap: "Approche 1 - Performances diagnostiques des combinaisons conjonctives"
kable(tbl_comb_a1, booktabs = TRUE, align = "c", row.names = FALSE) %>%
  kable_styling(latex_options = c("hold_position", "repeat_header", "scale_down"), font_size = 7)
```

```{r}
#| label: tbl-comp-a1-comb
#| tbl-cap: "Approche 1 - Comparaison des combinaisons (Sensibilité) : GS princ. vs GS fort"
comp_comb_a1 <- data.frame(
  Combinaison = tbl_comb_a1$Combinaison,
  `Se GS princ.` = combination_all_round$`Se [IC95%]`[match(tbl_comb_a1$Combinaison, combination_all_round$Combinaison)],
  `Se GS fort` = tbl_comb_a1$`Se [IC95%]`,
  check.names = FALSE
)
kable(comp_comb_a1, booktabs = TRUE, align = "c", row.names = FALSE) %>%
  kable_styling(latex_options = c("hold_position", "scale_down"), font_size = 7)
```

```{r}
#| label: tbl-strong-a1-score
#| tbl-cap: "Approche 1 - Performances diagnostiques du score global"
kable(tbl_score_a1, booktabs = TRUE, align = "c", row.names = FALSE) %>%
  kable_styling(latex_options = c("hold_position", "scale_down"), font_size = 8)
```

```{r}
#| label: tbl-comp-a1-score
#| tbl-cap: "Approche 1 - Comparaison du Score Global (Sensibilité) : GS princ. vs GS fort"
comp_score_a1 <- data.frame(
  Seuil = c("Score >= 1", "Score >= 2", "Score >= 3", "Score >= 4"),
  `Se GS princ.` = score_summary_table$`Se [IC95%]`,
  `Se GS fort` = tbl_score_a1$`Se [IC95%]`,
  check.names = FALSE
)
kable(comp_score_a1, booktabs = TRUE, align = "c", row.names = FALSE) %>%
  kable_styling(latex_options = c("hold_position", "scale_down"), font_size = 8)
```

\newpage

### Approche 2 : Négatifs = Tous les autres patients

Dans cette seconde approche, **tous les patients** n'ayant pas un Gold Standard fort positif sont assignés au groupe **Négatif**. Ce groupe inclut désormais les vrais négatifs initiaux, mais également les patients avec un examen/IRM positif qui n'ont pas eu d'infiltration ou dont l'infiltration n'a pas soulagé la douleur.
Cette analyse porte sur l'ensemble de la cohorte (**N = 69**), avec 18 cas positifs "forts" et 51 cas négatifs.

```{r}
#| label: strong-gs-a2-prep
#| echo: false

df_a2 <- df %>%
  mutate(GS_strong = ifelse(Gold_Standard_main == "Positif" & Resultat_Inf == "Positif", "Positif", "Negatif"))

# 1. Tests individuels
perf_u1_a2 <- get_perf_strong(df_a2$U1_E1, df_a2$GS_strong)
perf_u2a_a2 <- get_perf_strong(df_a2$U2a_E1, df_a2$GS_strong)
perf_u2b_a2 <- get_perf_strong(df_a2$U2b_E1, df_a2$GS_strong)
perf_u3_a2 <- get_perf_strong(df_a2$U3_E1, df_a2$GS_strong)

df_perf_indiv_a2 <- rbind(
  data.frame(Test = "ULNT1", perf_u1_a2),
  data.frame(Test = "ULNT2a", perf_u2a_a2),
  data.frame(Test = "ULNT2b", perf_u2b_a2),
  data.frame(Test = "ULNT3", perf_u3_a2)
)

# 2. Combinaisons
df_perf_comb_a2 <- do.call(rbind, lapply(comb_list_filtered, function(cols) {
  test_label <- paste(unname(test_labels[cols]), collapse = " + ")
  res_comb <- apply(sapply(cols, function(cc) df_a2[[cc]] == "Positif"), 1, all)
  res_comb_str <- ifelse(res_comb, "Positif", "Negatif")
  perf <- get_perf_strong(res_comb_str, df_a2$GS_strong)
  data.frame(Combinaison = test_label, perf)
}))

# 3. Score
df_a2$score <- df_a2$U1_E1_positif + df_a2$U2a_E1_positif + df_a2$U2b_E1_positif + df_a2$U3_E1_positif
df_perf_score_a2 <- do.call(rbind, lapply(1:4, function(s) {
  res_score <- ifelse(df_a2$score >= s, "Positif", "Negatif")
  perf <- get_perf_strong(res_score, df_a2$GS_strong)
  data.frame(Seuil = paste0("Score >= ", s), perf)
}))

tbl_indiv_a2 <- format_table_strong(df_perf_indiv_a2)
tbl_comb_a2 <- format_table_strong(df_perf_comb_a2)
tbl_score_a2 <- format_table_strong(df_perf_score_a2)
```

#### Performances des tests et comparaisons (Approche 2)

Dans cette approche, la modification du groupe de contrôle a un impact important. La sensibilité évaluée reste la même que dans l'approche 1 (puisque les cas positifs sont les mêmes), mais **la spécificité chute drastiquement**.
En effet, le groupe "Négatif" inclut désormais de nombreux vrais malades cliniques (GS principal positif) qui rendent les tests positifs (Vrais Positifs cliniques), mais qui sont ici comptés artificiellement comme des Faux Positifs car ils n'ont pas eu d'infiltration. **La comparaison de la spécificité a donc un intérêt clinique très limité ici.**

```{r}
#| label: tbl-strong-a2-indiv
#| tbl-cap: "Approche 2 - Performances diagnostiques test par test"
kable(tbl_indiv_a2, booktabs = TRUE, align = "c", row.names = FALSE) %>%
  kable_styling(latex_options = c("hold_position", "scale_down"), font_size = 8)
```

```{r}
#| label: tbl-comp-a2-spe
#| tbl-cap: "Approche 2 - Comparaison de la spécificité (Baisse due aux vrais malades reclassés)"
comp_spe_a2 <- data.frame(
  Test = c("ULNT1", "ULNT2a", "ULNT2b", "ULNT3"),
  `Sp GS princ.` = c(u1_performance$Sp_IC95, u2a_performance$Sp_IC95, u2b_performance_summary$Sp, u3_performance_summary$Sp),
  `Sp GS fort` = tbl_indiv_a2$`Sp [IC95%]`,
  check.names = FALSE
)
kable(comp_spe_a2, booktabs = TRUE, align = "c", row.names = FALSE) %>%
  kable_styling(latex_options = "hold_position", full_width = FALSE)
```

```{r}
#| label: tbl-strong-a2-comb
#| tbl-cap: "Approche 2 - Performances diagnostiques des combinaisons conjonctives"
kable(tbl_comb_a2, booktabs = TRUE, align = "c", row.names = FALSE) %>%
  kable_styling(latex_options = c("hold_position", "repeat_header", "scale_down"), font_size = 7)
```

```{r}
#| label: tbl-comp-a2-comb
#| tbl-cap: "Approche 2 - Comparaison des combinaisons (Se & Sp) : GS princ. vs GS fort"
comp_comb_a2 <- data.frame(
  Combinaison = tbl_comb_a2$Combinaison,
  `Se GS princ.` = combination_all_round$`Se [IC95%]`[match(tbl_comb_a2$Combinaison, combination_all_round$Combinaison)],
  `Se GS fort` = tbl_comb_a2$`Se [IC95%]`,
  `Sp GS princ.` = combination_all_round$`Sp [IC95%]`[match(tbl_comb_a2$Combinaison, combination_all_round$Combinaison)],
  `Sp GS fort` = tbl_comb_a2$`Sp [IC95%]`,
  check.names = FALSE
)
kable(comp_comb_a2, booktabs = TRUE, align = "c", row.names = FALSE) %>%
  kable_styling(latex_options = c("hold_position", "scale_down"), font_size = 7)
```

```{r}
#| label: tbl-strong-a2-score
#| tbl-cap: "Approche 2 - Performances diagnostiques du score global"
kable(tbl_score_a2, booktabs = TRUE, align = "c", row.names = FALSE) %>%
  kable_styling(latex_options = c("hold_position", "scale_down"), font_size = 8)
```

```{r}
#| label: tbl-comp-a2-score
#| tbl-cap: "Approche 2 - Comparaison du Score Global (Se & Sp) : GS princ. vs GS fort"
comp_score_a2 <- data.frame(
  Seuil = c("Score >= 1", "Score >= 2", "Score >= 3", "Score >= 4"),
  `Se GS princ.` = score_summary_table$`Se [IC95%]`,
  `Se GS fort` = tbl_score_a2$`Se [IC95%]`,
  `Sp GS princ.` = score_summary_table$`Sp [IC95%]`,
  `Sp GS fort` = tbl_score_a2$`Sp [IC95%]`,
  check.names = FALSE
)
kable(comp_score_a2, booktabs = TRUE, align = "c", row.names = FALSE) %>%
  kable_styling(latex_options = c("hold_position", "scale_down"), font_size = 8)
```

\newpage
"""

with open("these_brieuc.qmd", "w") as f:
    f.write(base_text + new_section)
