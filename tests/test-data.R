# Regression checks on the generated data for the Great Lakes Ice Cover indicator.
#
#   Rscript tests/test-data.R
#
# The checks below are shape-independent: they hold whatever the reshape in
# R/build_data.R turns each figure into. Value snapshots, which pin the actual
# numbers so a data update fails loudly instead of passing silently, are the
# TODO at the bottom.

setwd(here::here())
source("R/utils/write_stable.R")

# Keeps the dictionary check readable when a meta.yml field is absent altogether.
`%||%` <- function(a, b) if (is.null(a)) b else a

failures <- character()
check <- function(label, ok) {
  ok <- isTRUE(ok)
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- c(failures, label)
  invisible(ok)
}

rd <- function(f) {
  readr::read_csv(file.path("data", f),
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), progress = FALSE)
}

meta <- yaml::read_yaml("data/meta.yml")

cat("\nData dictionary\n")
check("meta.yml documents 2 dataset(s)", length(meta$datasets) == 2L)
check("meta.yml has no timestamp",
      !any(grepl("\\d{4}-\\d{2}-\\d{2}T|Sys\\.time|generated_at",
                 readLines("data/meta.yml", warn = FALSE))))

for (ds in meta$datasets) {
  df   <- rd(ds$file)
  cols <- vapply(ds$columns, function(x) x$name, character(1))
  check(sprintf("%s: meta.yml lists the columns the file actually has", ds$file),
        identical(cols, names(df)))
  check(sprintf("%s: meta.yml row count matches the file", ds$file),
        identical(as.integer(ds$rows), nrow(df)))
  check(sprintf("%s: every column has a type and a description", ds$file),
        all(vapply(ds$columns, function(x) nzchar(x$type %||% "") && nzchar(x$description %||% ""), logical(1))))
  check(sprintf("%s: source file is still present and unchanged", ds$file),
        identical(file_sha256(file.path("data-raw", ds$source_file)), ds$source_sha256))
  check(sprintf("%s: no blank rows", ds$file), nrow(df) > 0L)
}

cat("\nFile hygiene\n")
for (f in list.files("data", pattern = "[.](csv|yml)$", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

cat("\nValue snapshots\n")
# Pinned to EPA's April 2021 files. A data update fails here and names what moved.
row_is <- function(df, i, year, lake, value) {
  identical(unname(unlist(df[i, c("year", "lake", "value")])), c(year, lake, value))
}
num_range <- function(df) range(as.numeric(df$value))

mx <- rd("great_lakes_ice_max_cover.csv")
check("max cover: 288 rows (48 years x 6 series)", nrow(mx) == 288L)
check("max cover: first row 1973 Erie 95.7", row_is(mx, 1, "1973", "Erie", "95.7"))
check("max cover: last row 2020 All Lakes 19.5", row_is(mx, nrow(mx), "2020", "All Lakes", "19.5"))
check("max cover: years 1973-2020", identical(range(as.integer(mx$year)), c(1973L, 2020L)))
check("max cover: min 1.9 (Ontario 2012)", identical(num_range(mx)[1], 1.9) &&
        row_is(mx, which.min(as.numeric(mx$value)), "2012", "Ontario", "1.9"))
check("max cover: max 100", identical(num_range(mx)[2], 100))

du <- rd("great_lakes_ice_duration.csv")
check("duration: 240 rows (48 years x 5 lakes)", nrow(du) == 240L)
check("duration: first row 1973 Erie 67", row_is(du, 1, "1973", "Erie", "67"))
check("duration: last row 2020 Superior 54", row_is(du, nrow(du), "2020", "Superior", "54"))
check("duration: years 1973-2020", identical(range(as.integer(du$year)), c(1973L, 2020L)))
check("duration: min 0", identical(num_range(du)[1], 0))
check("duration: max 153", identical(num_range(du)[2], 153))

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
