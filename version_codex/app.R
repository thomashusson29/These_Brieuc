library(shiny)
library(dplyr)
library(ggplot2)

load_data <- function() {
  data_path <- if (file.exists("recueil_bon_avec_sexe.csv")) {
    "recueil_bon_avec_sexe.csv"
  } else {
    "../recueil_bon_avec_sexe.csv"
  }
  if (!file.exists(data_path)) stop("Fichier recueil_bon_avec_sexe.csv introuvable.")

  df <- read.csv(data_path, stringsAsFactors = FALSE, check.names = FALSE)
  names(df) <- trimws(gsub("^\ufeff", "", names(df)))
  names(df)[names(df) == "Gold Standard"] <- "Gold_Standard"
  names(df)[names(df) == "U1 E1"] <- "U1_E1"
  names(df)[names(df) == "U2a E1"] <- "U2a_E1"
  names(df)[names(df) == "U2b E1"] <- "U2b_E1"
  names(df)[names(df) == "U3 E1"] <- "U3_E1"

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

format_percent <- function(x, digits = 1) {
  paste0(format(round(100 * x, digits), nsmall = digits, trim = TRUE), "%")
}

score_summary <- function(df) {
  bind_rows(lapply(0:4, function(score) {
    sub <- df %>% filter(n_pos == score)
    n <- nrow(sub)
    n_ncb <- sum(sub$Gold_Standard_main == "Positif")

    if (n == 0) {
      return(data.frame(score = score, n = 0, n_ncb = 0, prob = NA_real_, low = NA_real_, high = NA_real_))
    }

    ci <- binom.test(n_ncb, n)$conf.int
    data.frame(
      score = score,
      n = n,
      n_ncb = n_ncb,
      prob = n_ncb / n,
      low = ci[1],
      high = ci[2]
    )
  }))
}

interpret_score <- function(score, n, prob) {
  if (n == 0) return("Aucun patient comparable dans la cohorte.")

  if (score == 0) {
    return("Aucun ULNT positif: dans cette cohorte, ce profil rend la NCB peu probable.")
  }
  if (score == 1) {
    return("Un seul ULNT positif: résultat peu discriminant, à interpréter avec le reste de l'examen clinique.")
  }
  if (score %in% c(2, 3)) {
    return("Deux ou trois ULNT positifs: dans cette cohorte, ce profil est fortement associé à une NCB.")
  }

  "Quatre ULNT positifs: résultat positif diffus. Dans cette cohorte, ce score n'augmente pas la probabilité plus que 2 ou 3 tests positifs; interprétation prudente."
}

ui <- fluidPage(
  titlePanel("Aide au diagnostic de NCB par score ULNT"),
  sidebarLayout(
    sidebarPanel(
      h4("Résultats des ULNT"),
      checkboxInput("u1", "ULNT 1 (médian)", FALSE),
      checkboxInput("u2a", "ULNT 2a (médian / musculo-cutané)", FALSE),
      checkboxInput("u2b", "ULNT 2b (radial)", FALSE),
      checkboxInput("u3", "ULNT 3 (ulnaire)", FALSE)
    ),
    mainPanel(
      h3("Résultat"),
      uiOutput("score_result"),
      plotOutput("score_plot", height = "300px"),
      h3("Interprétation clinique"),
      uiOutput("clinical_message"),
      h3("Repères visuels des tests"),
      div(
        style = "display: flex; gap: 10px; justify-content: space-around; background: white; padding: 15px; border-radius: 8px; border: 1px solid #ddd;",
        div(style = "flex: 1; text-align: center;",
            p(strong("U1")),
            div(style = "height: 150px; display: flex; align-items: center; justify-content: center;",
                img(src = "ulnt1.png", style = "max-height: 100%; max-width: 100%; object-fit: contain;"))),
        div(style = "flex: 1; text-align: center;",
            p(strong("U2a")),
            div(style = "height: 150px; display: flex; align-items: center; justify-content: center;",
                img(src = "ulnt2a.png", style = "max-height: 100%; max-width: 100%; object-fit: contain;"))),
        div(style = "flex: 1; text-align: center;",
            p(strong("U2b")),
            div(style = "height: 150px; display: flex; align-items: center; justify-content: center;",
                img(src = "ulnt2b.png", style = "max-height: 100%; max-width: 100%; object-fit: contain;"))),
        div(style = "flex: 1; text-align: center;",
            p(strong("U3")),
            div(style = "height: 150px; display: flex; align-items: center; justify-content: center;",
                img(src = "ulnt3.png", style = "max-height: 100%; max-width: 100%; object-fit: contain;")))
      ),
      hr(),
      h3("Données de la cohorte"),
      tableOutput("score_table")
    )
  )
)

server <- function(input, output, session) {
  df <- load_data()
  summaries <- score_summary(df)

  selected_score <- reactive({
    sum(c(input$u1, input$u2a, input$u2b, input$u3))
  })

  selected_summary <- reactive({
    summaries %>% filter(score == selected_score())
  })

  output$score_result <- renderUI({
    s <- selected_summary()
    weak <- s$n < 10
    background <- if (weak) "#fde2e2" else "#f5f5f5"

    div(
      style = paste0("background-color: ", background, "; border: 1px solid #cccccc; border-radius: 4px; padding: 12px;"),
      h4(paste0("Score ULNT: ", s$score, "/4 tests positifs")),
      if (s$n == 0) {
        p(strong("Aucune estimation possible."))
      } else {
        tagList(
          h3(style = "margin-top: 0;", paste0("NCB observée: ", format_percent(s$prob))),
          p(paste0("IC95%: [", format_percent(s$low), " ; ", format_percent(s$high), "]")),
          p(paste0("Patients comparables: ", s$n)),
          p(paste0("NCB observées: ", s$n_ncb, "/", s$n))
        )
      }
    )
  })

  output$clinical_message <- renderUI({
    s <- selected_summary()
    color <- case_when(
      s$score == 0 ~ "#2e7d32",
      s$score %in% c(2, 3) ~ "#b71c1c",
      TRUE ~ "#ef6c00"
    )

    div(
      style = paste0("padding: 15px; border-left: 5px solid ", color, "; background-color: #f9f9f9;"),
      p(style = paste0("color: ", color, "; font-size: 1.15em; font-weight: bold; margin-bottom: 0;"),
        interpret_score(s$score, s$n, s$prob))
    )
  })

  output$score_plot <- renderPlot({
    plot_df <- summaries %>%
      mutate(
        selected = score == selected_score(),
        score_label = factor(paste0(score, "/4"), levels = paste0(0:4, "/4"))
      )

    ggplot(plot_df, aes(x = score_label, y = prob)) +
      geom_col(aes(fill = selected), width = 0.65) +
      geom_errorbar(aes(ymin = low, ymax = high), width = 0.18, linewidth = 0.8) +
      geom_text(aes(label = paste0(n_ncb, "/", n)), vjust = -0.7, size = 4) +
      scale_y_continuous(
        limits = c(0, 1.05),
        breaks = seq(0, 1, 0.25),
        labels = function(x) paste0(round(100 * x), "%")
      ) +
      scale_fill_manual(values = c(`TRUE` = "lightcoral", `FALSE` = "grey75")) +
      labs(x = "Nombre de tests positifs", y = "NCB observée dans la cohorte") +
      theme_minimal(base_size = 14) +
      theme(legend.position = "none")
  })

  output$score_table <- renderTable({
    summaries %>%
      transmute(
        `Tests positifs` = paste0(score, "/4"),
        `Patients comparables` = n,
        `NCB observées` = paste0(n_ncb, "/", n),
        `NCB observée` = format_percent(prob),
        `IC95%` = paste0("[", format_percent(low), " ; ", format_percent(high), "]")
      )
  }, striped = TRUE, bordered = TRUE, spacing = "s")
}

shinyApp(ui, server)
