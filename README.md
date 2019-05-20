## Install INDRA

It is strongly recommended to create a [virtual environment](https://virtualenv.pypa.io/en/latest/) that encapsulates your INDRA installation. Running the following commands will create a new environment and install INDRA into it. Replace `/path/to/virtual/env` with your desired location. This can be, e.g., `~/.virtualenvs/indra`.

``` bash
virtualenv -p python3 /path/to/virtual/env
source /path/to/virtual/env/bin/activate
pip install indra
pip uninstall -y enum34
deactivate
```

## Install this package

This package can be installed directly from GitHub by running the following commands in R:

``` R
if( !require(devtools) ) install.packages("devtools")
devtools::install_github("ArtemSokolov/indRa")
```

## Usage

The INDRA module is exposed through `indra()` function. It allows for direct access to any part of the [INDRA API](https://indra.readthedocs.io/en/latest/).

``` R
library( reticulate )
library( indRa )

## If using virtualenv
use_virtualenv( "/path/to/virtual/env", required=TRUE )

## Access to INDRA is available through indra() function
indra()
# Module(indra)

## Reading a sentence with TRIPS
trips <- indra()$sources$trips
sentence <- 'MAP2K1 phosphorylates MAPK3 at Thr-202 and Tyr-204'
trips_processor <- trips$process_text( sentence )
trips_processor$statements
# [[1]]
# Phosphorylation(MAP2K1(), MAPK3(), T, 202)
# 
# [[2]]
# Phosphorylation(MAP2K1(), MAPK3(), Y, 204)
```

## Building interaction networks

The package provides additional functionality for constructing and manipulating interaction networks, based on statements retrieved from INDRA DB REST queries. A simple list of edges can be constructed through `IDBquery()`, which creates a data frame encapsulating the output of [`indra.sources.indra_db_rest.api.get_statements`](https://indra.readthedocs.io/en/latest/modules/sources/indra_db_rest/index.html#module-indra.sources.indra_db_rest.api) for all entities with HGNC mappings.

``` R
IDBquery( "SIK3" )
# # A tibble: 32 x 5
#    Hash               Activity        EvCnt Src   Trgt  
#    <chr>              <chr>           <int> <chr> <chr> 
#  1 7430532589474606   Phosphorylation     9 SIK3  PER2  
#  2 -21145377478765295 Phosphorylation     8 SIK3  HDAC4 
#  3 -260602555584320   Inhibition          4 SIK3  CRTC2 
#  4 12365252834703035  Activation          3 SIK3  STK11 
#  5 22779893853211724  Activation          3 SIK3  SIK3  
#  6 31422389291390976  Activation          3 SIK3  HDAC4 
#  7 -34515906559717663 DecreaseAmount      2 SIK3  CDKN1B
#  8 -2453043612469986  Inhibition          2 SIK3  HDAC4 
#  9 13139187518202040  Inhibition          2 SIK3  PER2  
# 10 22345317015989990  DecreaseAmount      2 SIK3  CDKN1A
# # … with 22 more rows

IDBquery( object="KLF4" )
# # A tibble: 621 x 5
#    Hash               Activity       EvCnt Src    Trgt 
#    <chr>              <chr>          <int> <chr>  <chr>
#  1 34237034834082983  Activation        19 MIR145 KLF4 
#  2 -1893896626253041  Acetylation       17 EP300  KLF4 
#  3 -4171272971594532  IncreaseAmount    15 KLF4   KLF4 
#  4 -2531422713809198  Activation        15 KLF4   KLF4 
#  5 1490195882280611   Activation        15 STAT3  KLF4 
#  6 17660102120847788  Activation        15 TP53   KLF4 
#  7 -23862745989616505 Inhibition        14 MIR145 KLF4 
#  8 -21174815692184579 DecreaseAmount    13 MIR7-1 KLF4 
#  9 23129435055012331  Activation        13 NANOG  KLF4 
# 10 -16399785507382445 DecreaseAmount    12 KLF4   KLF4 
# # … with 611 more rows
```
