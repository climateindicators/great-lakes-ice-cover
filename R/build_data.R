# Build tidy long-format data for the Great Lakes Ice Cover indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published figure CSVs in data-raw/ and writes data/*.csv plus
# data/meta.yml. Rerunning with unchanged inputs produces byte-identical output.
# Nothing here touches the network.
#
# Generated as a stub by the build-indicator skill. Each figure below has a
# `todo_reshape()` call standing where its reshape belongs. Replace that line,
# then delete the todo_reshape() helper once no call to it remains.
#
# TO UPDATE THE DATA: drop replacement CSVs into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

suppressPackageStartupMessages({
  library(dplyr)
})

root <- here::here()
source(file.path(root, "R/utils/epa_csv.R"))
source(file.path(root, "R/utils/write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Pivot one wide Year-by-lake table to long format: one row per year and lake,
# in source row order, then source column order. Blank cells are dropped.
pivot_lakes <- function(df, lakes) {
  df |>
    dplyr::mutate(.row = dplyr::row_number()) |>
    dplyr::select(.row, year = Year, dplyr::all_of(lakes)) |>
    tidyr::pivot_longer(dplyr::all_of(lakes), names_to = "lake", values_to = "value") |>
    dplyr::filter(trimws(value) != "") |>
    dplyr::arrange(.row, match(lake, lakes)) |>
    dplyr::select(year, lake, value)
}

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "Great Lakes Ice Cover",
  slug                    = "great-lakes-ice-cover",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-great-lakes-ice-cover/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/sites/default/files/2021-04/documents/great-lakes-ice_td.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# ---- Figure 1: Maximum Ice-Covered Area in the Great Lakes, 1973–2020 ----

f1_path <- file.path(raw_dir, "great-lakes-ice_fig-1.csv")
f1_meta <- read_epa_preamble(f1_path)
f1_raw  <- read_epa_csv(f1_path)

# Lake names are kept exactly as EPA's headers print them; "All Lakes" is the
# basin-wide total EPA plots alongside the five lakes.
F1_LAKES <- c("Erie", "Huron", "Michigan", "Ontario", "Superior", "All Lakes")

assert_headers(
  f1_raw,
  id_cols          = "Year",
  expected_headers = F1_LAKES,
  what             = "great-lakes-ice_fig-1.csv"
)

f1 <- pivot_lakes(f1_raw, F1_LAKES)
assert_conservation(f1_raw, F1_LAKES, nrow(f1), "great-lakes-ice_fig-1.csv")

write_csv_stable(f1, file.path(out_dir, "great_lakes_ice_max_cover.csv"))

# ---- Figure 2: Duration of Ice Cover in the Great Lakes, 1973–2020 ----

f2_path <- file.path(raw_dir, "great-lakes-ice_fig-2.csv")
f2_meta <- read_epa_preamble(f2_path)
f2_raw  <- read_epa_csv(f2_path)

F2_LAKES <- c("Erie", "Huron", "Michigan", "Ontario", "Superior")

assert_headers(
  f2_raw,
  id_cols          = "Year",
  expected_headers = F2_LAKES,
  what             = "great-lakes-ice_fig-2.csv"
)

f2 <- pivot_lakes(f2_raw, F2_LAKES)
assert_conservation(f2_raw, F2_LAKES, nrow(f2), "great-lakes-ice_fig-2.csv")

write_csv_stable(f2, file.path(out_dir, "great_lakes_ice_duration.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

# Columns are documented by hand; the column list is checked against the data
# frame so the dictionary cannot drift from the file.
describe <- function(df, cols) {
  stopifnot(identical(vapply(cols, function(x) x$name, character(1)), names(df)))
  cols
}

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "great_lakes_ice_max_cover.csv",
      figure          = "Figure 1",
      figure_title    = f1_meta$title,
      source_file     = "great-lakes-ice_fig-1.csv",
      source_sha256   = file_sha256(f1_path),
      source_encoding = "UTF-8-BOM",
      data_source     = f1_meta$data_source,
      web_update      = f1_meta$web_update,
      unit            = f1_meta$units,
      rows            = nrow(f1),
      columns         = describe(f1, list(
        col("year", "integer", "Year as EPA labels it."),
        col("lake", "string", "Lake name as EPA's header prints it (Erie, Huron, Michigan, Ontario, Superior), or All Lakes for the five combined."),
        col("value", "number", "Maximum percent ice cover that year, as published.")
      ))
    ),
    list(
      file            = "great_lakes_ice_duration.csv",
      figure          = "Figure 2",
      figure_title    = f2_meta$title,
      source_file     = "great-lakes-ice_fig-2.csv",
      source_sha256   = file_sha256(f2_path),
      source_encoding = "UTF-8-BOM",
      data_source     = f2_meta$data_source,
      web_update      = f2_meta$web_update,
      unit            = f2_meta$units,
      rows            = nrow(f2),
      columns         = describe(f2, list(
        col("year", "integer", "Year as EPA labels it."),
        col("lake", "string", "Lake name as EPA's header prints it (Erie, Huron, Michigan, Ontario, Superior)."),
        col("value", "integer", "Number of days that year with more than 5% ice cover, as published.")
      ))
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- list.files(out_dir, pattern = "[.](csv|yml)$", full.names = TRUE)
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-34s %8d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
