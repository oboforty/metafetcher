source("R/db_ctx.R")
source("R/utils.R")


LipidmapsHandler <- setRefClass(Class = "LipidmapsHandler",
  fields = list(
    name = "character"
  ),
  methods = list(
    initialize=function(...) {
      callSuper(...)
        # Initialise fields here (place holder)...
        .self
    },

    query_metabolite = function(db_id) {
      # Queries a ChEBI metabolite record and converts it to a common interface
      SQL <- "SELECT
        pubchem_id, chebi_id, kegg_id, hmdb_id, lipidmaps_id,
        smiles, inchi, inchikey, formula, names,
        mass
        FROM lipidmaps_data WHERE lipidmaps_id = '%s'"
      df.lipidmaps <- db.query(sprintf(SQL, db_id))

      if(length(df.lipidmaps) == 0)
        return(NULL)

      # convert pg array strings to R vectors:
      df.lipidmaps$names <- list(pg_str2vector(df.lipidmaps$names[[1]]))

      return (df.lipidmaps)
    },

    query_reverse = function(df.res) {
      pubchem_id <- df.res$pubchem_id[[1]]
      chebi_id <- df.res$chebi_id[[1]]
      kegg_id <- df.res$kegg_id[[1]]
      hmdb_id <- df.res$hmdb_id[[1]]

      # construct complex reverse query
      SQL <- "SELECT lipidmaps_id FROM lipidmaps_data WHERE"
      clauses <- character()

      if (!is.empty(pubchem_id))
        clauses <- c(clauses, sprintf("pubchem_id = '%s'", pubchem_id))
      if (!is.empty(chebi_id))
        clauses <- c(clauses, sprintf("chebi_id = '%s'", chebi_id))
      if (!is.empty(hmdb_id))
        clauses <- c(clauses, sprintf("hmdb_id = '%s'", hmdb_id))
      if (!is.empty(kegg_id))
        clauses <- c(clauses, sprintf("kegg_id = '%s'", kegg_id))

      if (length(clauses) == 0)
        return(NULL)

      SQL <- paste(SQL, paste(clauses, collapse = " OR "))
      df.lipidmaps <- db.query(SQL)

      if(length(df.lipidmaps) == 0) {
        return(NULL)
      }

      return(df.lipidmaps$chebi_id)
    }
  )
)
