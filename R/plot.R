#' Plot network paths
#'
#' Plotting of paths discovered by graph search algorithms
#'
#' @param ... One or more Path data frames, as returned by, e.g., dijkstra()
#' @return A ggplot2 object for additional manipulation
#' @importFrom magrittr %>%
#' @export
plotPaths <- function(...)
{
    PW <- dplyr::bind_rows(...) %>% dplyr::distinct() %>%
        dplyr::select( Src, Trgt, dplyr::everything() )
    G <- igraph::graph_from_data_frame( PW )

    ggplot2::ggplot( G, ggplot2::aes(x=x, y=y, xend=xend, yend=yend), arrow.gap=0.05 ) +
        ggplot2::theme_void() + ggplot2::coord_cartesian( clip="off" ) +
            ggnetwork::geom_edges( size=1, ggplot2::aes(color=Activity),
                                  arrow = arrow(length=unit(6,"pt"), type="closed") ) +
            ggnetwork::geom_nodes( size=10, color="white" ) +
            ggnetwork::geom_edgetext( ggplot2::aes(label=EvCnt) ) +
            ggnetwork::geom_nodetext( ggplot2::aes(label=vertex.names), fontface="bold" ) +
            ggplot2::theme( legend.justification="bottom",
                           plot.margin=grid::unit(c(0,1,0,1),"cm") )
}
