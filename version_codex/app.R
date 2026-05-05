library(shiny)
library(dplyr)

find_data_path <- function() {
  candidates <- c(
    "../recueil_bon.csv",
    "recueil_bon.csv",
    file.path(dirname(normalizePath(sys.frame(1)$ofile %||% ".", mustWork = FALSE)), "../recueil_bon.csv")
  )
  candidates <- unique(candidates)
  path <- candidates[file.exists(candidates)][1]
  if (is.na(path)) {
    stop("Impossible de trouver recueil_bon.csv.")
  }
  path
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

norm_result <- function(x) {
  x <- trimws(as.character(x))
  x[x %in% c("", "NA", "N/A", "NT")] <- NA
  x[x %in% c("Pos", "Positive", "positif", "Positif ")] <- "Positif"
  x[x %in% c("Neg", "Negative", "negatif", "négatif", "Negatif ")] <- "Negatif"
  x
}

metric_ci <- function(num, den) {
  if (is.na(den) || den == 0) {
    return(c(est = NA_real_, low = NA_real_, high = NA_real_))
  }

  bt <- binom.test(num, den)
  c(est = num / den, low = bt$conf.int[1], high = bt$conf.int[2])
}

format_percent <- function(x, digits = 1) {
  ifelse(is.na(x), NA_character_, paste0(format(round(100 * x, digits), nsmall = digits, trim = TRUE), "%"))
}

format_ci_percent <- function(low, high, digits = 1) {
  ifelse(
    is.na(low) | is.na(high),
    NA_character_,
    paste0("[", format_percent(low, digits), " ; ", format_percent(high, digits), "]")
  )
}

load_data <- function() {
  df <- read.csv(find_data_path(), stringsAsFactors = FALSE, check.names = FALSE)
  result_vars <- c("Gold_Standard", "U1_E1", "U2a_E1", "U2b_E1", "U3_E1")

  for (v in result_vars) {
    df[[v]] <- norm_result(df[[v]])
  }

  df %>%
    mutate(
      Gold_Standard_main = ifelse(Gold_Standard == "Douteux", "Negatif", Gold_Standard)
    ) %>%
    filter(Gold_Standard_main %in% c("Positif", "Negatif"))
}

selected_results <- function(input) {
  c(
    U1 = input$u1,
    U2a = input$u2a,
    U2b = input$u2b,
    U3 = input$u3
  )
}

ui <- fluidPage(
  titlePanel("Probabilité de NCB selon les ULNT"),
  sidebarLayout(
    sidebarPanel(
      selectInput("u1", "U1", choices = c("Positif", "Negatif"), selected = "Positif"),
      selectInput("u2a", "U2a", choices = c("Positif", "Negatif"), selected = "Positif"),
      selectInput("u2b", "U2b", choices = c("Positif", "Negatif"), selected = "Positif"),
      selectInput("u3", "U3", choices = c("Positif", "Negatif"), selected = "Negatif")
    ),
    mainPanel(
      h3("Résultat"),
      uiOutput("probability_box"),
      plotOutput("probability_plot", height = "180px"),
      h3("Note méthodologique"),
      p("La probabilité est calculée selon le nombre total de tests positifs, sans différencier quel test est positif."),
      p("Les gold standards douteux sont recodés négatifs, comme dans l’analyse principale du rapport."),
      br(),
      h3("Repères visuels des tests"),
      div(
        style = "display: flex; gap: 12px; align-items: flex-start; justify-content: space-between;",
        div(
          style = "width: 24%; text-align: center;",
          div(style = "font-weight: bold; margin-bottom: 6px;", "U1"),
          div(
            style = "height: 190px; display: flex; align-items: center; justify-content: center;",
            img(src = "ulnt1.png", style = "width: 100%; max-height: 180px; object-fit: contain;")
          )
        ),
        div(
          style = "width: 24%; text-align: center;",
          div(style = "font-weight: bold; margin-bottom: 6px;", "U2a"),
          div(
            style = "height: 190px; display: flex; align-items: center; justify-content: center;",
            img(src = "ulnt2a.png", style = "width: 100%; max-height: 180px; object-fit: contain;")
          )
        ),
        div(
          style = "width: 24%; text-align: center;",
          div(style = "font-weight: bold; margin-bottom: 6px;", "U2b"),
          div(
            style = "height: 190px; display: flex; align-items: center; justify-content: center;",
            img(src = "ulnt2b.png", style = "width: 100%; max-height: 180px; object-fit: contain;")
          )
        ),
        div(
          style = "width: 24%; text-align: center;",
          div(style = "font-weight: bold; margin-bottom: 6px;", "U3"),
          div(
            style = "height: 190px; display: flex; align-items: center; justify-content: center;",
            img(src = "ulnt3.png", style = "width: 100%; max-height: 180px; object-fit: contain;")
          )
        )
      )
    )
  )
)

combo_result <- function(df, results) {
  selected_n_pos <- sum(results == "Positif")
  df <- df %>%
    mutate(n_pos = rowSums(across(c(U1_E1, U2a_E1, U2b_E1, U3_E1)) == "Positif", na.rm = FALSE))

  combo <- df %>%
    filter(n_pos == selected_n_pos)

  n_combo <- nrow(combo)

  if (n_combo == 0) {
    return(list(n = 0, n_ncb = 0, n_pos = selected_n_pos, ci = metric_ci(NA_real_, NA_real_)))
  }

  n_ncb <- sum(combo$Gold_Standard_main == "Positif")
  list(n = n_combo, n_ncb = n_ncb, n_pos = selected_n_pos, ci = metric_ci(n_ncb, n_combo))
}

server <- function(input, output, session) {
  df <- load_data()

  output$probability_box <- renderUI({
    results <- selected_results(input)
    res <- combo_result(df, results)
    background <- if (res$n > 0 && res$n < 10) "#fde2e2" else "#f5f5f5"

    tags$pre(
      id = "probability",
      class = "shiny-text-output",
      style = paste0(
        "background-color: ", background, "; ",
        "border: 1px solid #cccccc; ",
        "border-radius: 4px; ",
        "padding: 10px;"
      )
    )
  })

  output$probability <- renderPrint({
    results <- selected_results(input)
    res <- combo_result(df, results)

    if (res$n == 0) {
      cat("Aucun patient ne correspond à ce nombre de tests positifs.\n")
      cat("Probabilité non estimable.\n")
      return(invisible(NULL))
    }

    cat("Nombre de tests positifs:", res$n_pos, "/4\n")
    cat("Probabilité de NCB:", format_percent(unname(res$ci["est"])), "\n")
    cat("IC95%:", format_ci_percent(unname(res$ci["low"]), unname(res$ci["high"])), "\n")
    cat("Patients comparables dans la cohorte:", res$n, "\n")
    cat("NCB observées:", paste0(res$n_ncb, "/", res$n), "\n")

    if (res$n < 10) {
      cat("\n")
      cat("Effectif faible: estimation descriptive à interpréter avec prudence.\n")
    }
  })

  output$probability_plot <- renderPlot({
    results <- selected_results(input)
    res <- combo_result(df, results)

    par(mar = c(4, 2, 2, 2))
    plot(
      NA,
      xlim = c(0, 100),
      ylim = c(0, 1),
      xlab = "Probabilité de NCB",
      ylab = "",
      yaxt = "n",
      bty = "n",
      main = ""
    )
    axis(1, at = seq(0, 100, 25), labels = paste0(seq(0, 100, 25), "%"))
    segments(0, 0.5, 100, 0.5, col = "grey75", lwd = 8, lend = "round")

    if (res$n == 0) {
      text(50, 0.7, "Probabilité non estimable", cex = 1.1)
      return(invisible(NULL))
    }

    est <- 100 * unname(res$ci["est"])
    low <- 100 * unname(res$ci["low"])
    high <- 100 * unname(res$ci["high"])
    result_color <- if (res$n < 10) "lightcoral" else "#08519c"
    ci_color <- if (res$n < 10) "lightcoral" else "#9ecae1"

    segments(low, 0.5, high, 0.5, col = ci_color, lwd = 7, lend = "butt")
    segments(low, 0.38, low, 0.62, col = result_color, lwd = 2)
    segments(high, 0.38, high, 0.62, col = result_color, lwd = 2)
    points(est, 0.5, pch = 19, cex = 2.2, col = result_color)
    text(est, 0.74, format_percent(unname(res$ci["est"])), cex = 1.1, col = result_color)
    text(low, 0.28, format_percent(unname(res$ci["low"])), cex = 0.9, col = result_color)
    text(high, 0.28, format_percent(unname(res$ci["high"])), cex = 0.9, col = result_color)
    text(50, 0.12, "barre = IC95%", cex = 0.85, col = "grey35")
  })
}

shinyApp(ui, server)
