print("INSTALL 2")

source("R/bulkinserts/hmdb.R")
source("R/bulkinserts/chebi.R")
source("R/bulkinserts/lipidmaps.R")



bulk_insert_hmdb("../tmp/hmdb_metabolites.xml")


bulk_insert_chebi("../tmp/ChEBI_complete.sdf")


bulk_insert_lipidmaps("../tmp/lipidmaps.sdf")

#hello
#hi
