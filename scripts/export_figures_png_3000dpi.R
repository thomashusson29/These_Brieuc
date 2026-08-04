#!/usr/bin/env Rscript

# Exporte les figures PDF vectorielles du rapport en PNG 3000 dpi.
# La taille physique des pages PDF est conservée : seuls le nombre de pixels
# et la résolution augmentent.

EXPORT_DPI <- 3000L
SOURCE_DIR <- "these_brieuc_files/figure-pdf"
OUTPUT_DIR <- "figures_png_hd"

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1L) {
  stop("Impossible de déterminer le chemin du script.", call. = FALSE)
}

script_path <- normalizePath(sub("^--file=", "", script_arg), mustWork = TRUE)
repository_dir <- dirname(dirname(script_path))
source_dir <- file.path(repository_dir, SOURCE_DIR)
output_dir <- file.path(repository_dir, OUTPUT_DIR)

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop(
    "Le package R 'pdftools' est requis. Installez-le avec ",
    "install.packages(\"pdftools\").",
    call. = FALSE
  )
}

if (!dir.exists(source_dir)) {
  stop("Dossier source introuvable : ", source_dir, call. = FALSE)
}

pdf_files <- sort(list.files(source_dir, pattern = "\\.pdf$", full.names = TRUE))
if (length(pdf_files) == 0L) {
  stop("Aucune figure PDF trouvée dans : ", source_dir, call. = FALSE)
}

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
staging_dir <- tempfile(pattern = ".figures_png_3000dpi-", tmpdir = repository_dir)
dir.create(staging_dir)
on.exit(unlink(staging_dir, recursive = TRUE, force = TRUE), add = TRUE)

read_png_dimensions <- function(path) {
  header <- readBin(path, what = "raw", n = 24L)
  if (length(header) < 24L || !identical(header[1:8], as.raw(c(137, 80, 78, 71, 13, 10, 26, 10)))) {
    stop("PNG invalide : ", path, call. = FALSE)
  }

  uint32_be <- function(bytes) {
    sum(as.numeric(bytes) * 256^(3:0))
  }

  c(
    width = uint32_be(header[17:20]),
    height = uint32_be(header[21:24])
  )
}

manifest <- vector("list", length(pdf_files))

for (index in seq_along(pdf_files)) {
  pdf_path <- pdf_files[[index]]
  stem <- tools::file_path_sans_ext(basename(pdf_path))
  png_path <- file.path(staging_dir, paste0(stem, ".png"))

  page_size <- pdftools::pdf_pagesize(pdf_path)
  if (nrow(page_size) != 1L) {
    stop("La source doit contenir exactement une page : ", pdf_path, call. = FALSE)
  }

  message(sprintf("[%02d/%02d] %s", index, length(pdf_files), basename(pdf_path)))
  suppressWarnings(
    pdftools::pdf_convert(
      pdf = pdf_path,
      format = "png",
      pages = 1L,
      filenames = png_path,
      dpi = EXPORT_DPI,
      antialias = TRUE,
      verbose = FALSE
    )
  )

  actual <- read_png_dimensions(png_path)
  expected <- round(c(page_size$width, page_size$height) * EXPORT_DPI / 72)

  if (!identical(unname(actual), unname(expected))) {
    stop(
      "Dimensions inattendues pour ", basename(png_path), " : ",
      paste(actual, collapse = " x "), " px au lieu de ",
      paste(expected, collapse = " x "), " px.",
      call. = FALSE
    )
  }

  manifest[[index]] <- data.frame(
    figure = basename(png_path),
    width_px = actual[["width"]],
    height_px = actual[["height"]],
    dpi = EXPORT_DPI,
    stringsAsFactors = FALSE
  )

  rm(page_size, actual, expected)
  invisible(gc())
}

staged_png <- sort(list.files(staging_dir, pattern = "\\.png$", full.names = TRUE))
copied <- file.copy(staged_png, output_dir, overwrite = TRUE, copy.mode = TRUE)
if (!all(copied)) {
  stop("Échec de la copie d'au moins une figure vers : ", output_dir, call. = FALSE)
}

manifest <- do.call(rbind, manifest)
message("")
message(nrow(manifest), " figures exportées en PNG à ", EXPORT_DPI, " dpi.")
message("Dossier : ", output_dir)
print(manifest, row.names = FALSE)
