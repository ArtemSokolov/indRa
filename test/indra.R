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

main1 <- function()
{
    ## Retrieve all edges for the three drug targets of interest
    IQ <- c("JAK2", "SIK3", "MET") %>% set_names() %>% map( IDBquery )

    ## Put everything into a common dataframe
    L <- bind_rows(IQ) %>% group_by( Activity, Src, Trgt ) %>%
        summarize_at( "EvCnt", sum ) %>% ungroup() %>% spread( Src, EvCnt )
}
