  tab <- table(factor(test_val, levels=c("Positif", "Negatif")), 
               factor(gs_val, levels=c("Positif", "Negatif")))
  
  tp <- tab[1,1]; fp <- tab[1,2]; fn <- tab[2,1]; tn <- tab[2,2]
  
  se_res <- binom.test(tp, tp + fn)
  sp_res <- binom.test(tn, tn + fp)
  vpp_res <- binom.test(tp, tp + fp)
  vpn_res <- binom.test(tn, tn + fn)
  
  # Calcul des LR avec sécurité pour division par zéro
  se <- tp / (tp + fn)
  sp <- tn / (tn + fp)
  lr_p <- if(sp < 1) se / (1 - sp) else Inf
  lr_n <- if(sp > 0) (1 - se) / sp else Inf
  
  data.frame(
    Se = as.numeric(se_res$estimate),
    Se_low = se_res$conf.int[1],
    Se_high = se_res$conf.int[2],
    Sp = as.numeric(sp_res$estimate),
    Sp_low = sp_res$conf.int[1],
    Sp_high = sp_res$conf.int[2],
    VPP = as.numeric(vpp_res$estimate),
    VPP_low = vpp_res$conf.int[1],
    VPP_high = vpp_res$conf.int[2],
    VPN = as.numeric(vpn_res$estimate),
    VPN_low = vpn_res$conf.int[1],
    VPN_high = vpn_res$conf.int[2],
    LRp = lr_p,
    LRn = lr_n
  )
}

# 1. Tests individuels
perf_u1 <- get_perf_strong(df_strong$U1_E1, df_strong$GS_strong)
perf_u2a <- get_perf_strong(df_strong$U2a_E1, df_strong$GS_strong)
perf_u2b <- get_perf_strong(df_strong$U2b_E1, df_strong$GS_strong)
perf_u3 <- get_perf_strong(df_strong$U3_E1, df_strong$GS_strong)

df_perf_indiv <- rbind(
  data.frame(Test = "ULNT1", perf_u1),
  data.frame(Test = "ULNT2a", perf_u2a),
  data.frame(Test = "ULNT2b", perf_u2b),
  data.frame(Test = "ULNT3", perf_u3)
)

# 2. Toutes les combinaisons conjonctives
# On filtre pour ne garder que celles à 2, 3 ou 4 tests pour la lisibilité
comb_list_filtered <- combination_tests[sapply(combination_tests, length) >= 2]

df_perf_comb <- do.call(rbind, lapply(comb_list_filtered, function(cols) {
  test_label <- paste(unname(test_labels[cols]), collapse = " + ")
  res_comb <- apply(sapply(cols, function(cc) df_strong[[cc]] == "Positif"), 1, all)
  res_comb_str <- ifelse(res_comb, "Positif", "Negatif")
  perf <- get_perf_strong(res_comb_str, df_strong$GS_strong)
  data.frame(Combinaison = test_label, perf)
}))

# 3. Score global
df_strong$score <- df_strong$U1_E1_positif + df_strong$U2a_E1_positif + df_strong$U2b_E1_positif + df_strong$U3_E1_positif

df_perf_score <- do.call(rbind, lapply(1:4, function(s) {
  res_score <- ifelse(df_strong$score >= s, "Positif", "Negatif")
  perf <- get_perf_strong(res_score, df_strong$GS_strong)
  data.frame(Seuil = paste0("Score >= ", s), perf)
}))

# Mise en forme pour tableaux
format_table_strong <- function(d) {
  rownames(d) <- NULL
  d %>%
    mutate(
      `Se [IC95]` = paste0(round(Se, 3), " [", round(Se_low, 3), " ; ", round(Se_high, 3), "]"),
      `Sp [IC95]` = paste0(round(Sp, 3), " [", round(Sp_low, 3), " ; ", round(Sp_high, 3), "]"),
      `VPP [IC95]` = paste0(round(VPP, 3), " [", round(VPP_low, 3), " ; ", round(VPP_high, 3), "]"),
      `VPN [IC95]` = paste0(round(VPN, 3), " [", round(VPN_low, 3), " ; ", round(VPN_high, 3), "]"),
      `LR+` = round(as.numeric(LRp), 2),
      `LR-` = round(as.numeric(LRn), 2)
    ) %>%
    select(1, `Se [IC95]`, `Sp [IC95]`, `VPP [IC95]`, `VPN [IC95]`, `LR+`, `LR-`)
}

table_indiv_strong <- format_table_strong(df_perf_indiv)
table_comb_strong <- format_table_strong(df_perf_comb)
table_score_strong <- format_table_strong(df_perf_score)
```

Cette analyse porte sur un effectif de `r nrow(df_strong)` patients (18 cas positifs "forts" et 24 cas négatifs).

### Performances test par test (GS fort)

```{r}
#| label: tbl-strong-indiv
#| tbl-cap: "Performances diagnostiques test par test (Gold Standard fort)"
kable(table_indiv_strong, booktabs = TRUE, align = "c", row.names = FALSE) %>%
  kable_styling(latex_options = c("hold_position", "scale_down"), font_size = 8)
```

### Performances de toutes les combinaisons conjonctives (GS fort)

```{r}
#| label: tbl-strong-comb
#| tbl-cap: "Performances diagnostiques des combinaisons conjonctives (Gold Standard fort)"
kable(table_comb_strong, booktabs = TRUE, align = "c", row.names = FALSE) %>%
  kable_styling(latex_options = c("hold_position", "repeat_header", "scale_down"), font_size = 7)
```

### Performances du score global (GS fort)

```{r}
#| label: tbl-strong-score
#| tbl-cap: "Performances diagnostiques du score global (Gold Standard fort)"
kable(table_score_strong, booktabs = TRUE, align = "c", row.names = FALSE) %>%
  kable_styling(latex_options = c("hold_position", "scale_down"), font_size = 8)
```

\newpage

### Comparaison des performances si GS fort vs GS principal

#### Sensibilité

Cette comparaison permet d'observer si le resserrement du critère de jugement (ne considérer comme vrais malades que ceux ayant une infiltration positive) modifie la capacité de détection des tests.
