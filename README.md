# metafetcher

## Usage
Install the dump files script first!

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

### Resolve based on a single database ID:
```R
resp <- resolve_single_id('HMDB', 'HMDB0001005')

df.out <- resp$df
```


## Installation

### I. Install Postgres database
1) Install PostgresSQL database if you haven't got it already
Remember the username / password that you provided!

2) Go to RStudio and open the **R/config.R** file.

3) Set the values of **dbconf** to the appropriate connection (username, password, database name)

4) If you haven't created a database yet, the install script will create it for you 

### II. (Optional) Download the database dump files 

We recommend downloading manually the database dump files. You can find them here:

  https://hmdb.ca/system/downloads/current/hmdb_metabolites.zip

  ftp://ftp.ebi.ac.uk/pub/databases/chebi/SDF/ChEBI_complete.sdf.gz
  
  https://www.lipidmaps.org/data/structure/download.php
  
Please uncompress them all, and put them in a directory.

### III. Set up filepaths in Config.R
Edit **R/config.R** so that the **fileconf**'s values point to the appropriate downloaded files.

### IV. Run the install script!
1) Go to your RStudio and open the **R/install.R** file.

2) (optional) If you have provided default relative paths In the menu, go to: 
**Session > Set Working Directory > To Project Directory**
If you provided absolute paths, then the script will find the dump files nonetheless.

3) Run the file. It will save the progress of installation after each database is completely inserted into the database. Rerunning the script will continue at the last step.

note 1) If you want to restart the whole process, simply delete the **install.RDS** file in the project directory.

note 2) After the install script has succeeded, re-running it will wipe your existing database!

note 3) For Pubchem and KEGG the script will not download their dump files. Instead it accesses their API endpoints.
