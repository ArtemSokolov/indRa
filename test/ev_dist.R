library( tidyverse )
library( reticulate )

use_virtualenv("./venv", TRUE)
indra <- import("indra")
idr <- indra$sources$indra_db_rest

iq <- idr$get_statements( subject="TYK2", best_first=TRUE )
v1 <- map_int( iq$statements, iq$get_ev_count )
## int [1:389] 83 72 32 24 22 21 17 14 14 11 ...
##              ... 1 1 1 1 1 1 1 1 1 1 1 1 1 1

iq <- idr$get_statements( subject="SIK3", best_first=TRUE )
v2 <- map_int( iq$statements, iq$get_ev_count )
## int [1:85] 9 8 4 4 3 3 3 3 2 2 ...
##              ... 1 1 1 1 1 1 1 1 1

iq <- idr$get_statements( subject="MET", best_first=TRUE )
v3 <- map_int( iq$statements, iq$get_ev_count )
## int [1:993] 167 117 102 72 70 61 53 52 45 40 ...
##              ... 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
