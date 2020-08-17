# MetaFetcheR

An R package designed to link metabolites' IDs from different Metabolome databases with eachother in a step to resolve ambiguity and standardize metabolites representation and annotation.
Currently the package supports resolving IDs for the following databases:
  - Human Metabolome Database (HMDB)
  - Chemical Entities of Biological Interest (ChEBI)
  - PubChem
  - Kyoto Encyclopedia of Genes and Genomes (KEGG)
  - Lipidomics Gateway (LipidMaps)
  
 For any questions or issues please use the Issues in github or contact Rajmund Casombordi or Sara Younes.

##  Installation
Install the dump files script first!
 
 - Install postgressql on your system
 - Install devtools in R 
 - In R write 
 ```R
library(devtools)
devtools::load_all()
install_github("komorowskilab/metafetcher")
```

### I. (Optional) Download the database dump files 

We recommend downloading manually the database dump files. You can find them here:

  https://hmdb.ca/system/downloads/current/hmdb_metabolites.zip

  ftp://ftp.ebi.ac.uk/pub/databases/chebi/SDF/ChEBI_complete.sdf.gz
  
  https://www.lipidmaps.org/data/structure/download.php
    
Please uncompress them all, and put them in a directory tmp.

### II. Inserting the data in the local database

1- This step is optional there is already a default config file however if you want to set your own configuration call function write_config() to set the configuration of the local database cache 
```R
write_config(host,port,db_name,user,password,path_of_tmp_folder)
```
2- call function install_database() for creating the tables and inserting the data from the tmp folder preferably put it in your R project directory

```R
install_database()
```
### Resolve based on a CSV script:

***discovery.csv:***
```csv
hmdb_id,chebi_id,kegg_id,pubchem_id,lipidmaps_id,names,inchi,inchikey,smiles,formula,mass,monoisotopic_mass
HMDB0006112,,,,,,,,,,,
,8337,,,,,,,,,,
HMDB0001005,,,,,,,,,,,
HMDB0001008,,,,,,,,,,,
```

***example1.R:***
```R
df.res <- read.csv("discovery.csv", stringsAsFactors=FALSE)
resp <- resolve_metabolites(df.res)

df.out <- resp$df
```

***output:***
The resulting *df.out* is a dataframe where the missing cell values have been extended by the program. For example, in each row the **hmdb_id** value(s) refer to the same metabolite as the value(s) in **pubchem_id**, and so on... 


### Resolve based on a single database ID:
```R
resp <- resolve_single_id('HMDB', 'HMDB0001005')

df.out <- resp$df
```

### Notes
note 1)running install_database() will save the progress of installation when the package is done with creating and inserting data in each table Rerunning install_database() afterwards will continue at the last step.

note 2) If you want to restart the whole process, simply delete the **install.RDS** file in the project directory.

note 3) After the install script has succeeded, re-running it will wipe your existing database!

note 3) For Pubchem and KEGG the script will not download their dump files. Instead it accesses their API endpoints.

## Vignette 
For how to use the package please visit (https://komorowskilab.github.io/MetaFetcheR/)

## Authors
- Rajmund Casombordi 
  @oboforty
- Sara Yones sara.younes@icm.uu.se 
 @SaraYones
- Klev Diamanti 
 @klevdiamanti

