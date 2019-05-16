# global reference to indra (will be initialized in .onLoad)
indra <- NULL

.onLoad <- function(libname, pkgname) {
  # use superassignment to update global reference to indra
  indra <<- reticulate::import("indra", delay_load = TRUE)
}
