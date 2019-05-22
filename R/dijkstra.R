## IDBquery() for a given gene with additional post-processing:
## 1. Remove immediate cycles (Source == Target)
## 2. Resolve multiple outgoing edges to keep the highest EvCnt
## 3. Remove edges to already-expanded nodes
## 4. Remove edges with fewer than min_ev evidence counts
expandNode <- function( g, vExpanded=c(), min_ev=1 )
{
    IDBquery(g) %>% dplyr::select( -Hash ) %>%
        dplyr::filter( Src != Trgt,
                      !(Trgt %in% vExpanded),
                      EvCnt >= min_ev ) %>%
            dplyr::group_by( Trgt ) %>%
            dplyr::top_n( 1, EvCnt ) %>%
            dplyr::ungroup()
}

## Append edges of an expanded node to a given path
## N - expanded node, as returned by expandNode()
## fscore - scoring function
## Prev - previous path (usually path to N)
expandPath <- function( N, fscore, Prev=NULL )
{
    N %>% dplyr::mutate( Gene=Trgt ) %>% tidyr::nest( -Gene, .key="Path" ) %>%
        dplyr::mutate_at( "Path", purrr::map, purrr::partial(dplyr::bind_rows, Prev) ) %>%
            dplyr::mutate( Score = purrr::map_dbl(Path, ~fscore(.x$EvCnt)) ) %>%
            dplyr::arrange( dplyr::desc(Score) )
}

## Compares two sets of paths and selects the better one for each gene
path_join <- function(P1, P2)
{
    ## Handle degenerate cases
    if( is.null(P1) ) return(P2)
    if( is.null(P2) ) return(P1)

    ## For each gene, select the path that has higher score
    dplyr::full_join(P1, P2, by="Gene", suffix=c("1","2") ) %>%
        dplyr::mutate( Sel = purrr::map2_int(Score1, Score2, purrr::lift_vd(which.max)) ) %>%
            dplyr::mutate( Path = ifelse(Sel==1, Path1, Path2),
                          Score = ifelse(Sel==1, Score1, Score2) ) %>%
            dplyr::select( Gene, Path, Score )
}

#' Dijkstra's algorithm for connecting a source to one or more targets
#'
#' Runs Dijkstra's graph search algorithm using the provided path scoring function
#'
#' @param src Source gene
#' @param trgts Vector of target genes
#' @param fscore Scoring function that accepts a vector of evidence counts
#' @param blacklist Vector of genes that should NOT be expanded
#' @param max_nodes Maximum number of nodes to expand (Default: 100)
#' @param min_ev Minimum evidence count to consider
#' @return A set of paths from src to each element of trgts
#' @importFrom magrittr %>%
#' @export
dijkstra <- function( src, trgts, fscore=lpgm, blacklist=c(), max_nodes=100, min_ev=3 )
{
    ## Argument verification
    if( src %in% trgts )
        stop( "Source node should differ from targets" )

    ## Initialize intermediate variables
    g <- src     ## Gene to expand next
    vxp <- c()   ## Vector of expanded node names
    P <- NULL    ## Path to each gene encountered so far
    R <- NULL    ## Path to the current node of interest
    
    for( i in 1:max_nodes )
    {
        ## Expand the next node
        cat( "Expanding", g, "...\n" )
        N <- expandNode( g, vxp, min_ev )
        vxp <- c(vxp, g)

        ## Compute the corresponding path expansion
        NP <- expandPath( N, fscore, R )
        
        ## Update the current paths with the new expansion
        P <- path_join( P, NP )

        ## Report progress
        cat( "Found paths to:", intersect(trgts, P$Gene), "\n" )

        ## Do we now have a path to all target nodes?
        if( all(trgts %in% P$Gene) )
            return( dplyr::filter(P, Gene %in% trgts) )

        ## Identify the next node to expand:
        ## - Exclude all nodes already expanded
        ## - Select a remaining node with the largest score
        P1 <- P %>% dplyr::filter( !(Gene %in% vxp), !(Gene %in% blacklist) ) %>%
            dplyr::arrange( desc(Score) ) %>% dplyr::top_n( 1, Score )
        g <- P1$Gene
        R <- P1$Path[[1]]
    }

    ## Return a partial solution
    dplyr::filter( P, Gene %in% trgts )
}
