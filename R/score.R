#' Length-penalized geometric mean
#'
#' Computes geometric mean of edge weights and offsets it by path length
#'
#' @param v Vector of edge weights
#' @return Path score
#' @export
lpgm <- function( v )
{
    mean(log(v)) - log(length(v))
}

#' Strongly-penalized geometric mean
#'
#' Geometric mean of edge weights with a strong penalty for path length
#'
#' @param v Vector of edge weights
#' @return Path score
#' @export
spgm <- function( v )
{
    mean(log(v)) - length(v)
}
