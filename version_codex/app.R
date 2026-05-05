library(shiny)
library(dplyr)
library(readxl)
library(ggplot2)

# --- Chargement et Préparation des Données ---
load_data <- function() {
  data_path <- if (file.exists("recueil_bon.xlsx")) "recueil_bon.xlsx" else "../recueil_bon.xlsx"
  if (!file.exists(data_path)) stop("Fichier recueil_bon.xlsx introuvable.")
  
  df <- as.data.frame(read_excel(data_path), stringsAsFactors = FALSE)
  
  norm_result <- function(x) {
    x <- trimws(as.character(x))
    x[x %in% c("", "NA", "N/A", "NT")] <- NA
    x[x %in% c("Pos", "Positive", "positif", "Positif ")] <- "Positif"
    x[x %in% c("Neg", "Negative", "negatif", "négatif", "Negatif ")] <- "Negatif"
    x
  }

  result_vars <- c("Gold_Standard", "U1_E1", "U2a_E1", "U2b_E1", "U3_E1")
  for (v in result_vars) df[[v]] <- norm_result(df[[v]])

  df %>%
    mutate(Gold_Standard_main = ifelse(Gold_Standard == "Douteux", "Negatif", Gold_Standard)) %>%
    filter(Gold_Standard_main %in% c("Positif", "Negatif")) %>%
    mutate(n_pos = rowSums(across(c(U1_E1, U2a_E1, U2b_E1, U3_E1)) == "Positif", na.rm = TRUE))
}

# --- Fonctions Statistiques ---
# Utilisation de la logique "AU MOINS X TESTS" pour plus de stabilité clinique
calc_lr_cumulative <- function(df, n_selected) {
  total_pos <- sum(df$Gold_Standard_main == "Positif")
  total_neg <- sum(df$Gold_Standard_main == "Negatif")
  
  if (n_selected == 0) {
    # Pour 0, on garde le LR- (n_pos == 0)
    tp <- sum(df$n_pos == 0 & df$Gold_Standard_main == "Positif")
    fp <- sum(df$n_pos == 0 & df$Gold_Standard_main == "Negatif")
    se <- tp / total_pos
    sp <- (total_neg - fp) / total_neg
    lr <- (tp / total_pos) / (fp / total_neg)
    n_count <- tp + fp
  } else {
    # Pour 1+, 2+, 3+, 4+
    tp <- sum(df$n_pos >= n_selected & df$Gold_Standard_main == "Positif")
    fp <- sum(df$n_pos >= n_selected & df$Gold_Standard_main == "Negatif")
    
    se <- tp / total_pos
    sp <- (total_neg - fp) / total_neg
    
    # Éviter division par zéro
    if (fp == 0) {
      lr <- (tp / total_pos) / (0.5 / total_neg)
    } else {
      lr <- (tp / total_pos) / (fp / total_neg)
    }
    n_count <- tp + fp
  }
  
  return(list(lr = lr, n = n_count))
}

post_test_prob <- function(pre_prob, lr) {
  if (pre_prob >= 1) return(0.99)
  if (pre_prob <= 0) return(0.01)
  pre_odds <- pre_prob / (1 - pre_prob)
  post_odds <- pre_odds * lr
  post_prob <- post_odds / (1 + post_odds)
  return(post_prob)
}

# --- Interface Utilisateur ---
ui <- fluidPage(
  titlePanel("Aide au Diagnostic : Névralgie Cervico-Brachiale (NCB)"),
  
  sidebarLayout(
    sidebarPanel(
      h4("1. Suspicion Clinique"),
      sliderInput("pre_prob", "Probabilité pré-test (%)", 
                  min = 1, max = 99, value = 50, step = 5),
      helpText("Votre intuition AVANT les tests."),
      
      hr(),
      h4("2. Résultats des ULNT"),
      checkboxInput("u1", "ULNT 1 (Médian)", FALSE),
      checkboxInput("u2a", "ULNT 2a (Médian/Musculo-cutané)", FALSE),
      checkboxInput("u2b", "ULNT 2b (Radial)", FALSE),
      checkboxInput("u3", "ULNT 3 (Ulnaire)", FALSE),
      
      hr(),
      wellPanel(
        h5("Prévalence de la cohorte"),
        textOutput("cohort_prev")
      )
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Résultat", 
          br(),
          fluidRow(
            column(6, 
              wellPanel(
                h4("Impact du test"),
                uiOutput("prob_result_text")
              )
            ),
            column(6,
              plotOutput("fagan_plot", height = "300px")
            )
          ),
          hr(),
          h4("Interprétation Clinique"),
          uiOutput("clinical_advice"),
          br(),
          h4("Repères visuels"),
          div(style = "display: flex; gap: 10px; justify-content: space-around; background: white; padding: 15px; border-radius: 8px; border: 1px solid #ddd;",
              div(style="flex: 1; text-align:center;", 
                  p(strong("U1 (Médian)")),
                  div(style="height: 150px; display: flex; align-items: center; justify-content: center;",
                      img(src = "ulnt1.png", style = "max-height: 100%; max-width: 100%; object-fit: contain;")
                  )
              ),
              div(style="flex: 1; text-align:center;", 
                  p(strong("U2a (Médian)")),
                  div(style="height: 150px; display: flex; align-items: center; justify-content: center;",
                      img(src = "ulnt2a.png", style = "max-height: 100%; max-width: 100%; object-fit: contain;")
                  )
              ),
              div(style="flex: 1; text-align:center;", 
                  p(strong("U2b (Radial)")),
                  div(style="height: 150px; display: flex; align-items: center; justify-content: center;",
                      img(src = "ulnt2b.png", style = "max-height: 100%; max-width: 100%; object-fit: contain;")
                  )
              ),
              div(style="flex: 1; text-align:center;", 
                  p(strong("U3 (Ulnaire)")),
                  div(style="height: 150px; display: flex; align-items: center; justify-content: center;",
                      img(src = "ulnt3.png", style = "max-height: 100%; max-width: 100%; object-fit: contain;")
                  )
              )
          )
        ),
        tabPanel("Stats de la cohorte",
          br(),
          h4("Valeur diagnostique cumulative"),
          p("Probabilité de NCB si l'on a AU MOINS X tests positifs :"),
          tableOutput("stats_table"),
          hr(),
          h4("Distribution réelle"),
          tableOutput("raw_dist_table")
        )
      )
    )
  )
)

# --- Serveur ---
server <- function(input, output, session) {
  df <- load_data()
  
  rv_stats <- reactive({
    n_pos <- sum(c(input$u1, input$u2a, input$u2b, input$u3))
    res <- calc_lr_cumulative(df, n_pos)
    post_p <- post_test_prob(input$pre_prob / 100, res$lr)
    list(n_pos = n_pos, lr = res$lr, post_p = post_p, n = res$n)
  })
  
  output$cohort_prev <- renderText({
    prev <- mean(df$Gold_Standard_main == "Positif")
    paste0(round(prev * 100, 1), "%")
  })
  
  output$prob_result_text <- renderUI({
    s <- rv_stats()
    tagList(
      p("Nombre de tests positifs : ", strong(paste0(s$n_pos, "/4"))),
      p("Probabilité initiale : ", strong(paste0(input$pre_prob, "%"))),
      h3(style = "color: #2c3e50;", 
         "Probabilité finale : ", 
         span(style = "color: #e74c3c; font-weight: bold;", 
              paste0(round(s$post_p * 100, 1), "%"))),
      p(em(paste0("Le test multiplie vos chances par ", round(s$lr, 2))))
    )
  })
  
  output$clinical_advice <- renderUI({
    s <- rv_stats()
    pre_p <- input$pre_prob / 100
    post_p <- s$post_p
    prob_diff <- post_p - pre_p
    
    # 1. Qualité intrinsèque du test (LR)
    test_strength <- case_when(
      s$lr < 0.2  ~ "très performant pour exclure",
      s$lr < 0.6  ~ "modérément performant pour exclure",
      s$lr > 5    ~ "très performant pour confirmer",
      s$lr > 2    ~ "modérément performant pour confirmer",
      TRUE        ~ "peu contributif dans ce cas précis"
    )
    
    # 2. Impact réel sur le patient (Différence de probabilité)
    impact_text <- case_when(
      abs(prob_diff) < 0.08 ~ "ne modifie quasiment pas",
      abs(prob_diff) < 0.20 ~ "modifie légèrement",
      TRUE                  ~ "change significativement"
    )
    
    # 3. Conclusion diagnostique
    status_text <- case_when(
      post_p > 0.90 ~ "la NCB est quasi certaine.",
      post_p > 0.70 ~ "la NCB est très probable.",
      post_p > 0.30 ~ "le diagnostic est incertain (zone de doute).",
      post_p > 0.10 ~ "la NCB est peu probable.",
      TRUE          ~ "la NCB est quasiment exclue."
    )
    
    # Couleur de l'alerte
    color <- case_when(
      post_p > 0.70 ~ "#c0392b",
      post_p < 0.30 ~ "#27ae60",
      TRUE          ~ "#f39c12"
    )

    div(style = paste0("padding: 15px; border-left: 5px solid ", color, "; background-color: #f9f9f9;"),
        p(style = "margin-bottom: 5px;",
          "Bien que ce test soit ", strong(test_strength), ", son résultat ", strong(impact_text), " votre suspicion initiale."),
        p(style = paste0("color: ", color, "; font-size: 1.2em; font-weight: bold;"),
          "Au final, ", status_text),
        
        if(s$n_pos == 4) p(tags$i(style="color: #8e44ad; font-size: 0.9em;", "Note : Le score de 4/4 est ici moins spécifique que le 3/4, attention à une possible sensibilisation centrale.")),
        
        tags$small(style="color: #7f8c8d;", 
                   paste0("Analyse basée sur un score de ", if(s$n_pos==0) "0" else paste0(s$n_pos, " ou plus"), "."))
    )
  })
  
  output$fagan_plot <- renderPlot({
    s <- rv_stats()
    df_p <- data.frame(
      Temps = factor(c("Initial", "Final"), levels = c("Initial", "Final")),
      Prob = c(input$pre_prob/100, s$post_p)
    )
    ggplot(df_p, aes(x=Temps, y=Prob, fill=Temps)) +
      geom_col(width=0.5) +
      geom_text(aes(label=paste0(round(Prob*100), "%")), vjust=-0.5, size=6) +
      scale_y_continuous(limits=c(0, 1.1), labels=scales::percent) +
      scale_fill_manual(values=c("Initial"="#bdc3c7", "Final"="#e74c3c")) +
      theme_minimal() + labs(x="", y="") + theme(legend.position="none")
  })
  
  output$stats_table <- renderTable({
    data.frame(Tests_Positifs = paste0(0:4, "+")) %>%
      rowwise() %>%
      mutate(
        LR = calc_lr_cumulative(df, as.numeric(gsub("\\+", "", Tests_Positifs)))$lr
      )
  })
  
  output$raw_dist_table <- renderTable({
    df %>%
      group_by(n_pos) %>%
      summarise(Total = n(), NCB_Pos = sum(Gold_Standard_main == "Positif")) %>%
      rename("Score Exact" = n_pos)
  })
}

shinyApp(ui, server)
