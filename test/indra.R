library( tidyverse )
library( reticulate )

## Load relevant Python modules
use_virtualenv("./venv", TRUE)
indra <- import("indra")
idr <- indra$sources$indra_db_rest
hgnc <- indra$databases$hgnc_client

## Given an INDRA DB REST query object, retrieves the set of Source-Target links
## Returns type and evidence count for each link
getEdges <- function( indra_query )
{
    ## Identify the statements returned by the query
    s <- indra_query$statements

    ## Retrieve the type and strength of each statement
    nev <- map_int( s, indra_query$get_ev_count )
    cls <- map_chr( s, ~class(.x)[1] ) %>% str_split( "\\." ) %>% map_chr( 4 )

    ## Retrieve HGNC IDs of the subject and object in each statement
    ag <- map( s, ~.x$agent_list() )
    ag1 <- map_chr( ag, pluck, 1, "db_refs", "HGNC" )
    ag2 <- map( ag, pluck, 2, "db_refs", "HGNC" )

    ## Put everything into a common data frame
    ## Combine duplicate (Type, Src, Trgt) triplets by summing evidence counts
    ## Make HGNC IDs to gene symbols
    tibble( EvCnt = nev, Activity = cls, Src = ag1, Trgt = ag2 ) %>%
        filter( !map_lgl(Trgt, is.null) ) %>% unnest() %>%
        group_by( Activity, Src, Trgt ) %>% summarize_at( "EvCnt", sum ) %>%
        arrange( desc(EvCnt) ) %>% ungroup() %>%
        mutate_at( c("Src","Trgt"), map_chr, hgnc$get_hgnc_name )
}

## Performs an INDRA DB REST query with best_first=TRUE, ev_limit=1
## Passes the result through getEdges
IDBquery <- function( ... )
{
    f <- partial( idr$get_statements, best_first=TRUE, ev_limit=1L )
    f(...) %>% getEdges()
}

main <- function()
{
    ## Retrieve all edges for the three drug targets of interest
    IQ <- c("JAK2", "SIK3", "MET") %>% set_names() %>% map( IDBquery )

    ## Drop all links with evidence count below 2
    IQ <- map( IQ, filter, EvCnt > 1 )

    ## Identify common targets
    L <- bind_rows(IQ) %>% spread( Src, EvCnt )

    ## Targets common to JAK2 and MET, and those that differ
    L1 <- select( L, -SIK3 )
    L1 %>% na.omit() %>% arrange( desc(MET) )
    L1 %>% filter( is.na(MET), !is.na(JAK2) ) %>% arrange( desc(JAK2) )
    L1 %>% filter( !is.na(MET), is.na(JAK2) ) %>% arrange( desc(MET) )
}
