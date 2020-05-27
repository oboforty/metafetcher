

install<- function (filepath)

{print("INSTALL 2")

  source("R/bulkinserts/hmdb.R")
  source("R/bulkinserts/chebi.R")
  source("R/bulkinserts/lipidmaps.R")

bulk_insert_hmdb(paste(filepath,"/hmdb_metabolites.xml",sep = ""))


bulk_insert_chebi(paste(filepath,"/ChEBI_complete.sdf",sep = ""))


bulk_insert_lipidmaps(paste(filepath,"/lipidmaps.sdf",sep = ""))
}

#hello
#hi
#hi
