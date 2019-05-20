#' Exposes the python module to R through reticulate
#'
#' @export
indra <- function() {pyIndra}

#' Characterize edges retrieved by an INDRA DB REST query
#' 
#' Given an INDRA DB REST query object, retrieves the set of Source-Target edges
#' 
#' @param indra_query Query object returned by indra.source.indra_db_rest.get_statements()
#' @return Data frame of edge properties
#' @importFrom magrittr %>%
#' @export
queryEdges <- function( indra_query )
{
    hgnc <- pyIndra$databases$hgnc_client
    
    ## Identify the statements returned by the query
    s <- indra_query$statements

    ## Retrieve the hash of each statement
    h <- purrr::map( s, reticulate::r_to_py, convert=FALSE ) %>%
        purrr::map( ~.x$get_hash() ) %>% purrr::map_chr( as.character )
    
    ## Retrieve the type and strength of each statement
    nev <- purrr::map_int( s, indra_query$get_ev_count )
    cls <- purrr::map_chr( s, ~class(.x)[1] ) %>%
        stringr::str_split( "\\." ) %>% purrr::map_chr( 4 )

    ## Retrieve HGNC IDs of the subject and object in each statement
    ag <- purrr::map( s, ~.x$agent_list() )
    ag1 <- purrr::map( ag, purrr::pluck, 1, "db_refs", "HGNC" )
    ag2 <- purrr::map( ag, purrr::pluck, 2, "db_refs", "HGNC" )

    ## Put everything into a common data frame
    ## Convert HGNC IDs to gene symbols
    tibble::tibble( Hash = h, Activity = cls, Src = ag1, Trgt = ag2, EvCnt = nev ) %>%
        dplyr::filter( !purrr::map_lgl(Src, is.null), !purrr::map_lgl(Trgt, is.null) ) %>%
            tidyr::unnest() %>%
            dplyr::mutate_at( c("Src","Trgt"), purrr::map_chr, hgnc$get_hgnc_name )
}

#' INDRA DB REST query
#' 
#' Performs an INDRA DB REST query with best_first=TRUE, ev_limit=1
#' Passes the result through queryEdges()
#' 
#' @param ... parameters to pass to indra.sources.indra_db_rest.get_statements()
#' @return Data frame of edge properties
#' @importFrom magrittr %>%
#' @export
IDBquery <- function( ... )
{
    idr <- pyIndra$sources$indra_db_rest
    f <- purrr::partial( idr$get_statements, best_first=TRUE, ev_limit=1L )
    f(...) %>% queryEdges()
}

