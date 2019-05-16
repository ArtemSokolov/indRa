library( tidyverse )
library( reticulate )

## Load relevant Python modules
use_virtualenv("./venv", TRUE)
indra <- import("indra")

wrangle_beliefs <- function()
{
    pybi <- import_builtins()
    pkl <- import("pickle", convert=FALSE)
    p <- pkl$load( pybi$open( "data/belief_dict_20190428.pkl", "rb" ) )
    indra_belief_dict <- unlist(p)
    ## save( indra_belief_dict, "file.RData" )
}

## Given an INDRA DB REST query object, retrieves the set of Source-Target links
## Returns type and evidence count for each link
getEdges <- function( indra_query )
{
    hgnc <- indra$databases$hgnc_client
    
    ## Identify the statements returned by the query
    s <- indra_query$statements

    ## Retrieve the hash of each statement
    h <- map( s, r_to_py, convert=FALSE ) %>% map( ~.x$get_hash() ) %>% map_chr( as.character )
    
    ## Retrieve the type and strength of each statement
    nev <- map_int( s, indra_query$get_ev_count )
    cls <- map_chr( s, ~class(.x)[1] ) %>% str_split( "\\." ) %>% map_chr( 4 )

    ## Retrieve HGNC IDs of the subject and object in each statement
    ag <- map( s, ~.x$agent_list() )
    ag1 <- map_chr( ag, pluck, 1, "db_refs", "HGNC" )
    ag2 <- map( ag, pluck, 2, "db_refs", "HGNC" )

    ## Put everything into a common data frame
    ## Convert HGNC IDs to gene symbols
    tibble( Hash = h, Activity = cls, Src = ag1, Trgt = ag2, EvCnt = nev ) %>%
        filter( !map_lgl(Trgt, is.null) ) %>% unnest() %>%
        mutate_at( c("Src","Trgt"), map_chr, hgnc$get_hgnc_name )
}

## Performs an INDRA DB REST query with best_first=TRUE, ev_limit=1
## Passes the result through getEdges
IDBquery <- function( ... )
{
    idr <- indra$sources$indra_db_rest
    f <- partial( idr$get_statements, best_first=TRUE, ev_limit=1L )
    f(...) %>% getEdges()
}

main1 <- function()
{
    ## Retrieve all edges for the three drug targets of interest
    IQ <- c("JAK2", "SIK3", "MET") %>% set_names() %>% map( IDBquery )

    ## Put everything into a common dataframe
    L <- bind_rows(IQ) %>% group_by( Activity, Src, Trgt ) %>%
        summarize_at( "EvCnt", sum ) %>% ungroup() %>% spread( Src, EvCnt )
}
