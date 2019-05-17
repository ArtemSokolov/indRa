## Install INDRA

```
virtualenv -p python3 /path/to/virtual/env
source /path/to/virtual/env/bin/activate
pip install indra
pip uninstall -y enum34
deactivate
```

## Install this package

``` R
if( !require(devtools) ) install.packages("devtools")
devtools::install_github("ArtemSokolov/indRa")
```

## Usage

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
