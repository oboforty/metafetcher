library(XML)
library(iterators)
require("RPostgreSQL")

# String buffer size
BL <- 1000
# Commit buffer size
BDFL <- 100

# the script commits to database after reaching this many bytes in the buffer
#COMMIT_SIZE <- 200*1024*1024


# todo: ITT: fix

create_empty_dfvec <- function (N) {
  df_vect <- list(
    hmdb_id = character(N),
    description = character(N),
    names = character(N),
    iupac_name = character(N),
    iupac_trad_name = character(N),
    formula = character(N),
    smiles = character(N),
    inchi = character(N),
    inchikey = character(N),
    cas_id = character(N),
    drugbank_id = character(N),
    drugbank_metabolite_id = character(N),
    chemspider_id = character(N),
    kegg_id = character(N),
    metlin_id = character(N),
    pubchem_id = character(N),
    chebi_id = character(N),
    avg_mol_weight = numeric(N),
    monoisotopic_mol_weight = numeric(N),
    state = character(N),
    biofluid_locations = character(N),
    tissue_locations = character(N),
    taxonomy = character(N),
    ontology = character(N),
    proteins = character(N),
    diseases = character(N),
    synthesis_reference = character(N)
  )

  return(df_vect)
}

remigrate <- function (conn) {
  dbGetQuery(conn, "CREATE TABLE hmdb_data (
	names ARRAY,
	iupac_name TEXT,
	iupac_trad_name TEXT,
	formula TEXT,
	smiles TEXT,
	inchi TEXT,
	inchikey TEXT,
	hmdb_id VARCHAR(11) NOT NULL,
	description TEXT,
	cas_id VARCHAR(10),
	drugbank_id VARCHAR(32),
	drugbank_metabolite_id VARCHAR(32),
	chemspider_id VARCHAR(32),
	kegg_id VARCHAR(32),
	metlin_id VARCHAR(32),
	pubchem_id VARCHAR(32),
	chebi_id VARCHAR(32),
	avg_mol_weight FLOAT,
	monoisotopic_mol_weight FLOAT,
	state VARCHAR(32),
	biofluid_locations ARRAY,
	tissue_locations ARRAY,
	taxonomy TEXT,
	ontology TEXT,
	proteins TEXT,
	diseases TEXT,
	synthesis_reference TEXT,

	PRIMARY KEY (hmdb_id)
  )")

}

parse_xml_iter <- function(filepath) {
  start_time <- Sys.time()

  n_parsed <- 0

  # read file line by line
  con <- file(filepath, "r")
  it <- ireadLines(con)

  # ignore first two lines
  nextElem(it)
  nextElem(it)

  # buffer for the XML parsing
  i <- 1
  buffer <- character(BL)
  xml <- ""

  # data frame buffer for the DB
  j <- 1
  vec_df <- create_empty_dfvec(BDFL)

  buffer_size <- 0

  # empty error file
  er_con <- file('../tmp/errors/hmdb_error_xml.txt', "w")
  close(er_con)

  # connect to DB
  drv <- dbDriver("PostgreSQL")
  db_conn <- dbConnect(drv, dbname = "../..", host = "localhost", port = 5432, user = "postgres", password = "postgres")

  remigrate(db_conn)

  repeat {
    i <- i + 1
    line <- nextElem(it)
    buffer[i] <- line

    if (i >= BL) {
      # empty buffer
      xml <- paste(xml, paste(buffer, collapse=''))
      i <- 1
    }
    else if (line == "</metabolite>") {
      xmlend <- paste(buffer[1:i-1], collapse='')
      xml <- paste(xml, xmlend, collapse='')

      i <- 1

      # parse xml
      tryCatch({
        x <- xmlToList(xmlParse(xml))
      }, error = function(e) {
        print(paste("Error in XML. ", i))

        er_con <- file('../tmp/errors/hmdb_error_xml.txt', "a")
        write(xml, er_con)
        close(er_con)


        # todo: itt: dump file
      })

      # add entry to DF:
      vec_df$hmdb_id[j] <- null2na(x$accession)
      vec_df$description[j] <- null2na(x$description)

      vec_df$names[j] <- NA
      vec_df$iupac_name[j] <- null2na(x$iupac_name)
      vec_df$iupac_trad_name[j] <- null2na(x$traditional_iupac)
      vec_df$formula[j] <- null2na(x$chemical_formula)
      vec_df$smiles[j] <- null2na(x$smiles)
      vec_df$inchi[j] <- null2na(x$inchi)
      vec_df$inchikey[j] <- null2na(x$inchikey)

      vec_df$cas_id[j] <- null2na(x$cas_id)
      vec_df$drugbank_id[j] <- null2na(x$drugbank_id)
      vec_df$drugbank_metabolite_id[j] <- null2na(x$drugbank_metabolite_id)
      vec_df$chemspider_id[j] <- null2na(x$chemspider_id)
      vec_df$kegg_id[j] <- null2na(x$kegg_id)
      vec_df$metlin_id[j] <- null2na(x$metlin_id)
      vec_df$pubchem_id[j] <- null2na(x$pubchem_id)
      vec_df$chebi_id[j] <- null2na(x$chebi_id)
      vec_df$avg_mol_weight[j] <- null2na(x$average_molecular_weight)
      vec_df$monoisotopic_mol_weight[j] <- null2na(x$monisotopic_molecular_weight)
      vec_df$state[j] <- null2na(x$state)
      # [f['biofluid'] for f in x$biofluid_locations [])]
      vec_df$biofluid_locations[j] <- NA
      # [f['tissue'] for f in x$tissue_locations [])]
      vec_df$tissue_locations[j] <- NA

      vec_df$taxonomy[j] <- toJSON(x$taxonomy)
      vec_df$ontology[j] <- toJSON(x$ontology)
      vec_df$proteins[j] <- toJSON(x$protein_associations)
      vec_df$diseases[j] <- toJSON(x$diseases)


      vec_df$synthesis_reference[j] <- null2na(x$synthesis_reference)


      # keep DF buffer
      j <- j + 1
      buffer_size <- buffer_size + nchar(xml)

      #if (j >= BDFL || buffer_size >= COMMIT_SIZE) {
      if (j >= BDFL) {
        # save DB buffer as dataframe
        df <- data.frame(
          hmdb_id=vec_df$hmdb_id,description=vec_df$description,names=vec_df$names,iupac_name=vec_df$iupac_name,iupac_trad_name=vec_df$iupac_trad_name,formula=vec_df$formula,smiles=vec_df$smiles,inchi=vec_df$inchi,inchikey=vec_df$inchikey,cas_id=vec_df$cas_id,drugbank_id=vec_df$drugbank_id,drugbank_metabolite_id=vec_df$drugbank_metabolite_id,chemspider_id=vec_df$chemspider_id,kegg_id=vec_df$kegg_id,metlin_id=vec_df$metlin_id,pubchem_id=vec_df$pubchem_id,chebi_id=vec_df$chebi_id,avg_mol_weight=vec_df$avg_mol_weight,monoisotopic_mol_weight=vec_df$monoisotopic_mol_weight,state=vec_df$state,biofluid_locations=vec_df$biofluid_locations,tissue_locations=vec_df$tissue_locations,taxonomy=vec_df$taxonomy,ontology=vec_df$ontology,proteins=vec_df$proteins,diseases=vec_df$diseases,synthesis_reference=vec_df$synthesis_reference
        )
        #dbWriteTable(db_conn, "hmdb_data", value = head(df, j), append = TRUE, row.names = FALSE)
        dbWriteTable(db_conn, "hmdb_data", value = df, append = TRUE, row.names = FALSE)

        now <- Sys.time()
        log <- paste("Inserting to DB... ", j, " ", round(now - start_time, 2), " seconds")
        print(log)

        # reset db buffers
        df_vect <- create_empty_dfvec(BDFL)
        j <- 1
        buffer_size <- 0

        # try to fight memory issues
        gc()
      }

      # clear buffer
      n_parsed <- n_parsed + 1
      xml <- ""
    }
  }

  print("Closing DB & File")
  close(con)
  dbDisconnect(db_conn)


  end_time <- Sys.time()
}

hmdb <- function(fake = FALSE) {
  return(list(
    download_all = function() {
      filepath <- "../tmp/hmdb_metabolites.xml"

      if (!fake) {
        # todo: download that large xml
      }

      # parse file iteratively (line by line)
      parse_xml_iter(filepath)
    },

    parse = function() {
      print("fake_metabolite hmdb")
    },

    download = function() {
      print("download hmdb")
    },

    fake = function() {
      print("fake hmdb")
    },

    query = function() {
      print("query hmdb")
    }
  ))
}
