pkg.globals <- new.env()

pkg.globals$dbconf <- NULL
pkg.globals$fileconf<- NULL

dbconf <- list(
host ="localhost",
port=5432,
dbname ="metafetcher",
user ="postgres",
password ="postgres"
)
fileconf <- list(
hmdb_dump_file="/Users/saryo614/Desktop/tmp/hmdb_metabolites.xml",
chebi_dump_file="/Users/saryo614/Desktop/tmp/chebi_dump_file.xml",
lipidmaps_dump_file="/Users/saryo614/Desktop/tmp/LMSD_20191002.sdf"
)

