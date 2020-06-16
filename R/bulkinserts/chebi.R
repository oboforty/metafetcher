library(iterators)
source("R/db_ctx.R")
source("R/utils.R")
source("R/migrate.R")


bulk_insert_chebi <- function(filepath) {
  mapping.chebi <- list(
    'ChEBI ID' = 'chebi_id',

    'ChEBI Name' = 'names',
    'IUPAC Name' = 'names',

    'Formulae' = 'formula',
    'InChI' = 'inchi',
    'InChIKey' = 'inchikey',
    'SMILES' = 'smiles',

    'Definition' = 'description',
    'PubChem Database Links' = 'pubchem_id',
    'Pubchem Database Links' = 'pubchem_id',
    'KEGG COMPOUND Database Links' = 'kegg_id',
    'HMDB Database Links' = 'hmdb_id',
    'LIPID MAPS instance Database Links' = 'lipidmaps_id',
    'CAS Registry Numbers' = 'cas_id',

    #'Star' = 'quality',
    'Charge' = 'charge',
    'Mass' = 'mass',
    'Monoisotopic Mass' = 'monoisotopic_mass'
  )

  # data frame buffer for the DB
  attr.chebi <- unique(unlist(mapping.chebi))
  # todo: cardinality: chebi_id_alt, ??maybe formulas??,
  mcard.chebi <- c("names")
  df.chebi <- create_empty_record(1, attr.chebi, mcard.chebi)


  # connect to DB
  db.connect()
  remigrate_chebi(db_conn)
  db.transaction()

  # read file line by line
  f_con <- file(filepath, "r")
  it <- ireadLines(f_con)

  j <- 1
  state <- "something"
  start_time <- Sys.time()
  print(sprintf("(%s) Inserting ChEBI to DB...", start_time))

  repeat {
    line <- try(nextElem(it))
    if (class(line) == "try-error")
      break

    if (startsWith(line, "$$$$")) {
      # metabolite parsing has ended, save to DB
      # transform vectors to postgres ARRAY input strings
      db.write_df("chebi_data", convert_df_to_db_array(df.chebi, mcard.chebi))

      # iterate on parsed records counter
      j <- j + 1
      df.chebi <- create_empty_record(1, attr.chebi, mcard.chebi)

      if (mod(j, 500) == 0) {
        # commit every once in a while
        print(sprintf("#%s (DT: %s)", j, round(Sys.time() - start_time, 2)))

        db.commit()
        db.transaction()
      }
    } else if (is.empty(line)) {
      next
    } else if (startsWith(line, ">")) {
      # new state
      state <- substr(line, 4, nchar(line)-1)
    } else {
      attr <- mapping.chebi[[state]]

      if (!is.null(attr)) {
        if (attr == 'names') {
          df.chebi[[1, attr]] <- c(df.chebi[[1, attr]], line)
          next
        }

        if (attr == 'inchi')
          line <- lstrip(line, "InChI=")
        else if (attr == 'chebi_id')
          line <- lstrip(line, "CHEBI:")
        else if (attr == 'pubchem_id')
          if (startsWith(line, "SID:"))
            next
          else if(startsWith(line,"CID:"))
            line <- lstrip(line, "CID: ")

        df.chebi[[1, attr]] <- line
      }
    }
  }

  # finish up
  print("Closing DB & File")
  close(f_con)
  db.commit()
  db.disconnect()

  print(sprintf("Done inserting %s records! DT: %s", j, round(as.numeric(Sys.time() - start_time),2)))
}

