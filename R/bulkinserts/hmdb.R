library(XML)
source("R/db_ctx.R")
source("R/utils.R")
source("R/migrate.R")


bulk_insert_hmdb <- function(filepath) {
  mapping.hmdb <- list(
    'accession' = 'hmdb_id',
    'secondary_accessions.accession' = 'hmdb_id_alt',

    'name' = 'names',
    'iupac_name' = 'names',
    'traditional_iupac' = 'names',
    'synonyms.synonym' = 'names',

    # todo: description is larger, extend text + cs_description
    #'description' = 'description',

    'average_molecular_weight' = 'avg_mol_weight',
    'monisotopic_molecular_weight' = 'monoisotopic_mol_weight',
    'state' = 'state',
    'chemical_formula' = 'formula',
    'smiles' = 'smiles',
    'inchi' = 'inchi',
    'inchikey' = 'inchikey',
    'chemspider_id' = 'chemspider_id',
    'kegg_id' = 'kegg_id',
    'metlin_id' = 'metlin_id',
    'pubchem_compound_id' = 'pubchem_id',
    'chebi_id' = 'chebi_id'
  )

  # data frame buffer for the DB
  attr.hmdb <- unique(unlist(mapping.hmdb))
  mcard.hmdb <- c("names", "hmdb_id_alt")

  state <- list(
    tag_path = character(length=0),
    i = 0,
    df = create_empty_record(1, attr.hmdb, mcard.hmdb),
    mult_card = FALSE
  )

  start_time <- Sys.time()

  # connect to DB
  remigrate_hmdb(db.connect())
  db.transaction()

  print(sprintf("(%s) Inserting HMDB to DB...", start_time))

  # Iterative XML parsing. this iterates on each xml tag individually
  # And we store the appropriate values to our dataframe.
  xmlEventParse(
    file = filepath,
    handlers = list(
      startElement = function(name, attrs, .state) {
        # todo: pubchem doesn't work or is not present

        if (name == "metabolite") {
          # new metabolite XML

          return(list(
            tag_path = character(length=0),
            i = .state$i + 1,
            df = create_empty_record(1, attr.hmdb, mcard.hmdb),
            mult_card = FALSE
          ))
        } else {
          # keep track of xml hierarchy of this element
          .state$tag_path <- c(.state$tag_path, name)
          .state$mult_card <- name %in% mcard.hmdb
        }

        return(.state)
      },
      text = function(text, .state) {
        tag_state <- paste(.state$tag_path, collapse=".")
        attr <- mapping.hmdb[[tag_state]]

        if (!is.null(attr)) {
          if (.state$mult_card) {
            # multiple cardinality
            df.hmdb[[1, attr]] <<- c(df.hmdb[[1, attr]], text)
          } else {
            if (attr == 'inchi')
              text <- lstrip(text, "InChI=")

            .state$df[[1, attr]] <- text
          }
        }
        # debug
        #print(sprintf("%s => %s", tag_state, text))

        return(.state)
      },
      endElement = function (name, .state) {
        if (name == "metabolite") {
          # end of metabolite, save to DB
          db.write_df("hmdb_data", convert_df_to_db_array(.state$df, mcard.hmdb))

          if (mod(.state$i, 500) == 0) {
            print(sprintf("#%s (DT: %s)", .state$i, round(Sys.time() - start_time, 2)))

            # on buffer full commit & reset DB buffer
            db.commit()
            db.transaction()
          }
        } else {
          # keep track of xml hierarchy of this element
          .state$tag_path = .state$tag_path[-length(.state$tag_path)]
        }

        return(.state)
      }
    ),
    addContext = FALSE,
    useTagName = FALSE,
    ignoreBlanks = TRUE,
    trim = TRUE,
    state = state
  )

  # disconnect from DB
  print("Closing DB")
  db.commit()
  db.disconnect()

  print(sprintf("Done inserting %s records! DT: %s", .state$i, round(as.numeric(Sys.time() - start_time),2)))
}

