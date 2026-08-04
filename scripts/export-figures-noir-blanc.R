#!/usr/bin/env Rscript

# Régénère les 23 figures finales en noir et blanc à 600 dpi.
# Les données patients restent locales et ne sont jamais copiées dans docs/.

project_dir <- normalizePath(getwd(), mustWork = TRUE)
source_qmd <- file.path(project_dir, "these_brieuc_last_recueil.qmd")
build_dir <- file.path(project_dir, ".figures_png_bw_export")
public_dir <- file.path(project_dir, "docs", "figures-noir-blanc")
temporary_html <- ".figures_png_bw.html"

if (!file.exists(source_qmd)) {
    stop("Lancer ce script depuis la racine du dépôt.", call. = FALSE)
}
if (Sys.which("quarto") == "") {
    stop("Quarto est requis pour régénérer les figures.", call. = FALSE)
}
if (!requireNamespace("magick", quietly = TRUE)) {
    stop("Le package R 'magick' est requis pour contrôler les exports.", call. = FALSE)
}

source_files <- c(
    "age-distribution-1.png",
    "bmi-distribution-1.png",
    "côté-distribution-1.png",
    "fig-gs-positive-level-1.png",
    "fig-gs-positive-score-1.png",
    "fig-kappa-interobserver-1.png",
    "fig-level-performance-individual-1.png",
    "global-contingency-plot-1.png",
    "global-performance-combined-plot-1.png",
    "global-performance-plots-1.png",
    "infiltrations-distribution-1.png",
    "level-grouped-plot-1.png",
    "niveau-distribution-1.png",
    "resultat-infiltrations-distribution-1.png",
    "results-by-level-count-1.png",
    "results-by-level-rate-1.png",
    "results-by-level-test-metric-plot-1.png",
    "score-contribution-se-plot-1.png",
    "score-contribution-sp-plot-1.png",
    "score-roc-curve-1.png",
    "score-thresholds-plot-1.png",
    "sexe-distribution-1.png",
    "tabac-distribution-1.png"
)

public_files <- sub("côté", "cote", source_files, fixed = TRUE)

if (dir.exists(build_dir)) {
    unlink(build_dir, recursive = TRUE)
}
dir.create(build_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(public_dir, recursive = TRUE, showWarnings = FALSE)

old_env <- Sys.getenv(c("FIGURES_MONOCHROME", "FIGURES_MONOCHROME_DIR"), unset = NA)
on.exit({
    for (name in names(old_env)) {
        if (is.na(old_env[[name]])) {
            Sys.unsetenv(name)
        } else {
            do.call(Sys.setenv, setNames(list(old_env[[name]]), name))
        }
    }
}, add = TRUE)

Sys.setenv(
    FIGURES_MONOCHROME = "1",
    FIGURES_MONOCHROME_DIR = paste0(build_dir, .Platform$file.sep)
)

status <- system2(
    "quarto",
    c(
        "render",
        shQuote(source_qmd),
        "--to", "auto-dark-html",
        "--output", temporary_html
    )
)
if (!identical(status, 0L)) {
    stop("Le rendu Quarto noir et blanc a échoué.", call. = FALSE)
}

missing <- source_files[!file.exists(file.path(build_dir, source_files))]
if (length(missing)) {
    stop("Figures manquantes : ", paste(missing, collapse = ", "), call. = FALSE)
}

copied <- file.copy(
    from = file.path(build_dir, source_files),
    to = file.path(public_dir, public_files),
    overwrite = TRUE
)
if (!all(copied)) {
    stop("Impossible de copier toutes les figures dans docs/.", call. = FALSE)
}

inspect_png <- function(path) {
    image <- magick::image_read(path)
    info <- magick::image_info(image)
    density <- strsplit(as.character(info$density[[1]]), "x", fixed = TRUE)[[1]]
    # PNG stocke la densité en pixels par mètre : 600 dpi devient 236 px/cm
    # après l'arrondi du format. On restitue donc la valeur nominale à 10 dpi.
    dpi <- round(as.numeric(density[[1]]) * 2.54, digits = -1)

    sample <- magick::image_resize(image, "200x200!")
    pixels <- magick::image_data(sample, channels = "rgb")
    channel_delta <- max(
        abs(as.integer(pixels[1, , ]) - as.integer(pixels[2, , ])),
        abs(as.integer(pixels[1, , ]) - as.integer(pixels[3, , ]))
    )

    data.frame(
        fichier = basename(path),
        largeur_px = info$width,
        hauteur_px = info$height,
        dpi = dpi,
        noir_et_blanc = channel_delta == 0,
        taille_octets = file.info(path)$size,
        stringsAsFactors = FALSE
    )
}

manifest <- do.call(rbind, lapply(file.path(public_dir, public_files), inspect_png))
if (any(manifest$dpi != 600)) {
    stop("Au moins une figure n'est pas exportée à 600 dpi.", call. = FALSE)
}
if (!all(manifest$noir_et_blanc)) {
    stop("Au moins une figure contient encore des pixels colorés.", call. = FALSE)
}

utils::write.csv(
    manifest,
    file.path(public_dir, "manifest.csv"),
    row.names = FALSE,
    fileEncoding = "UTF-8"
)

message(
    nrow(manifest),
    " figures noir et blanc exportées à 600 dpi dans ",
    public_dir
)
