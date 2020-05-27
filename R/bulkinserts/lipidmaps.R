library(iterators)
source("R/db_ctx.R")
source("R/utils.R")
source("R/migrate.R")


bulk_insert_lipidmaps <- function(filepath) {
  mapping.lipidmaps <- list(
      'NAME' = 'names',
      'SYSTEMATIC_NAME' = 'names',
      'SYNONYMS' = 'names',
      'ABBREVIATION' = 'names',

      'LM_ID' = 'lipidmaps_id',
      'CATEGORY' = 'category',
      'MAIN_CLASS' = 'main_class',
      'SUB_CLASS' = 'sub_class',
      'CLASS_LEVEL4' = 'lvl4_class',
      'EXACT_MASS' = 'mass',
      'SMILES' = 'smiles',
      'INCHI' = 'inchi',
      'INCHI_KEY' = 'inchikey',
      'FORMULA' = 'formula',
      'KEGG_ID' = 'kegg_id',
      'HMDB_ID' = 'hmdb_id',
      'CHEBI_ID' = 'chebi_id',
      'PUBCHEM_CID' = 'pubchem_id',
      'LIPIDBANK_ID' = 'lipidbank_id'
  )

  # data frame buffer for the DB
  attr.lm <- unique(unlist(mapping.lipidmaps))
  mcard.lm <- c("names")
  df.lipidmaps <- create_empty_record(1, attr.lm, mcard.lm)

  # connect to DB
  db.connect()
  remigrate_lipidmaps(db_conn)
  db.transaction()

  # read file line by line
  f_con <- file(filepath, "r")
  it <- ireadLines(f_con)

  j <- 1
  state <- "something"
  start_time <- Sys.time()
  print(sprintf("(%s) Inserting LipidMaps to DB...", start_time))

  repeat {
    line <- try(nextElem(it))
    if (class(line) == "try-error")
      break

    if (startsWith(line, "$$$$")) {
      # metabolite parsing has ended, save to DB
      # transform vectors to postgres ARRAY input strings
      db.write_df("lipidmaps_data", convert_df_to_db_array(df.lipidmaps, mcard.lm))

      # iterate on parsed records counter
      j <- j + 1
      df.lipidmaps <- create_empty_record(1, attr.lm, mcard.lm)

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
      attr <- mapping.lipidmaps[[state]]

      if (!is.null(attr)) {
        if (attr == 'names') {
          # multiple cardinality
          df.lipidmaps[[1, attr]] <- c(df.lipidmaps[[1, attr]], line)
          next
        }

        if (attr == 'inchi')
          line <- lstrip(line, "InChI=")

        df.lipidmaps[[1, attr]] <- line
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

