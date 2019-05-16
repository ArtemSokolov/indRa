# global reference to indra (will be initialized in .onLoad)
pyIndra <- NULL

.onLoad <- function(libname, pkgname) {
  # use superassignment to update global reference to indra
  pyIndra <<- reticulate::import("indra", delay_load = TRUE)
}
