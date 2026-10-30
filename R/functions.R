# Purpose: helper functions used by the analysis scripts.
# Needs: nothing when sourced (main.R sources this file first, so setup.R can
#   use the checks); dplyr and gt when the functions are called.
# Produces: the functions below. Each takes its inputs as arguments and reads
#   no global objects.

## ---- check-functions
# Stop if any of the files is missing, naming them.
check_files_exist <- function(paths) {
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0) {
    stop("Missing file(s): ", paste(missing, collapse = ", "),
         ". See README.md, Running the analysis.", call. = FALSE)
  }
  invisible(TRUE)
}

# Stop if any required name is absent, naming the missing ones and the source.
check_names_present <- function(present, required, source) {
  missing <- setdiff(required, present)
  if (length(missing) > 0) {
    stop(source, " lacks: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}

# Stop if a step changed the number of rows.
check_rows_unchanged <- function(before, after, step) {
  if (before != after) {
    stop(step, " changed the number of rows (", before, " to ", after, ").",
         call. = FALSE)
  }
  invisible(TRUE)
}

## ---- apply-record-corrections
# Apply the corrections listed for one source. Each correction names a record
# by its identifier and sets one field to a new value. A correction that
# matches no record, or more than one, stops the run, so a correction can
# never be applied silently to the wrong record or skipped. The messages name
# the source and field, never the identifier.
apply_record_corrections <- function(data, corrections, source_name, id_column) {
  corrections <- corrections[corrections$source == source_name, , drop = FALSE]
  if (nrow(corrections) == 0) {
    return(data)
  }
  if (anyNA(data[[id_column]])) {
    stop("Some records have no ", id_column,
         ", so corrections cannot be matched reliably.", call. = FALSE)
  }
  ids <- as.character(data[[id_column]])
  for (i in seq_len(nrow(corrections))) {
    field <- corrections$field[i]
    if (!field %in% names(data)) {
      stop("A correction for ", source_name, " names a field that does not exist: ",
           field, ".", call. = FALSE)
    }
    rows <- which(ids == corrections$record_id[i])
    if (length(rows) != 1) {
      stop("A correction to ", field, " in ", source_name, " matches ",
           length(rows), " records instead of 1.", call. = FALSE)
    }
    data[[field]][rows] <- corrections$corrected_value[i]
  }
  data
}

## ---- jitter-days
# Shift each day offset from day 0 by its own random whole number of days, from
# -max_days to max_days, all equally likely. A shift never moves a value to
# the other side of day 0 (decided 29 October 2026): values at or before day 0
# stay at or before it, and values after it stay after it, matching how the
# periods are assigned (post-intervention means after day 0). A value before
# day 0 is also never moved onto day 0 itself, where the timeline draws no
# line. A shift that would cross, or land a value from before day 0 on day 0,
# is applied in the opposite direction instead. Missing values stay missing.
# The seed is set only inside this function, so the shifts are the same on
# every run and nothing else in the session is affected.
jitter_days <- function(x, max_days, seed) {
  shifts <- withr::with_seed(
    seed,
    sample(seq(-max_days, max_days), length(x), replace = TRUE)
  )
  shifted <- x + shifts
  crossed <- !is.na(x) & (((x <= 0) != (shifted <= 0)) | (x < 0 & shifted == 0))
  shifted[crossed] <- x[crossed] - shifts[crossed]
  shifted
}

## ---- relabel-levels
# Turn a column into a factor whose levels keep the order they would have by
# default (sorted), with some levels shown under new names. `labels` is a
# named vector: names are the values as they appear in the data, values the
# names to show. Values not in the data are ignored. Used only for display.
relabel_levels <- function(x, labels = character()) {
  values <- sort(unique(x))
  shown <- as.character(values)
  matched <- shown %in% names(labels)
  shown[matched] <- labels[shown[matched]]
  factor(x, levels = values, labels = shown)
}

## ---- save-table
# Save a gtsummary or gt table as HTML in the given folder.
save_table <- function(table, name, dir) {
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  if (inherits(table, "gtsummary")) {
    table <- gtsummary::as_gt(table)
  }
  gt::gtsave(table, file.path(dir, paste0(name, ".html")))
  invisible(table)
}
