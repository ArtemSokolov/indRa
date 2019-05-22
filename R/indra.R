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
    iq <- reticulate::r_to_py( indra_query )

    ## Handle degenerate case
    if( length(iq$statements) < 1 )
        return( tibble::tibble(Hash = character(), Activity = character(),
                               EvCnt = character(), Src = character(),
                               Trgt = character()) )
    
    ## Retrieves HGNC ID of the i^th agent in statement s
    agentHGNC <- function( s, i )
    {
        ## Python indexing is 0-based
        ag <- s$agent_list()[i-1]
        if( ag == reticulate::r_to_py(NULL) ) return(NULL)
        reticulate::py_to_r( ag$db_refs["HGNC"] )
    }
    
    ## Retrieves information for the i^th statements in a query
    ithStatement <- function( i )
    {
        s <- iq$statements[i-1]	# Python indexing is 0-based
        list(
            Hash = as.character(s$get_hash()),
            Activity = stringr::str_split( class(s)[1], "\\." )[[1]][4],
            EvCnt = reticulate::py_to_r( iq$get_ev_count(s) ),
            Src = agentHGNC(s, 1), Trgt = agentHGNC(s, 2)
        )
    }

    ## Parse statements returned by the query
    ## Remove statements that didn't map to HUGO
    ss <- purrr::map( 1:length(iq$statements), ithStatement ) %>%
        purrr::discard( with, is.null(Trgt) | is.null(Src) )

    ## Put everything into a common data frame
    ## Convert HGNC IDs to gene symbols
    dplyr::bind_rows(ss) %>%
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

