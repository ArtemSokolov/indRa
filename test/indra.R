library( tidyverse )
library( reticulate )

use_virtualenv("./venv", TRUE)
indra <- import("indra")
idr <- indra$sources$indra_db_rest
hgnc <- indra$databases$hgnc_client

## Given an INDRA DB REST query object, retrieves the set of Source-Target links
## Returns type and evidence count for each link
getEdges <- function( indra_query )
{
    s <- indra_query$statements

    nev <- map_int( s, indra_query$get_ev_count )
    cls <- map_chr( s, ~class(.x)[1] ) %>% str_split( "\\." ) %>% map_chr( 4 )

    ag <- map( s, ~.x$agent_list() )
    ag1 <- map_chr( ag, pluck, 1, "db_refs", "HGNC" )
    ag2 <- map( ag, pluck, 2, "db_refs", "HGNC" )

    tibble( EvCnt = nev, Activity = cls, Src = ag1, Trgt = ag2 ) %>%
        filter( !map_lgl(Trgt, is.null) ) %>% unnest() %>%
        group_by( Activity, Src, Trgt ) %>% summarize_at( "EvCnt", sum ) %>%
        arrange( desc(EvCnt) ) %>% ungroup() %>%
        mutate_at( c("Src","Trgt"), map_chr, hgnc$get_hgnc_name )
}


main <- function()
{
    f <- function(s) idr$get_statements( subject=s, best_first=TRUE, ev_limit=1L )
    iqq <- c("JAK2", "SIK3", "MET") %>% set_names() %>% map(f)
    XX <- map( iqq, getEdges )
}
