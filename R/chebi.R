source("R/db_ctx.R")
source("R/utils.R")


ChebiHandler <- setRefClass(Class = "ChebiHandler",
  fields = list(
    name = "character",
    sql_select = "character"
  ),
  methods = list(
    initialize=function(...) {
      callSuper(...)
        # Initialise fields here (place holder)...
        .self

      .self$sql_select = "pubchem_id, chebi_id, kegg_id, hmdb_id, lipidmaps_id,
        smiles, inchi, inchikey, formula, names,
        mass, monoisotopic_mass"
    },

    query_metabolite = function(db_id) {
      # Queries a ChEBI metabolite record and converts it to a common interface
      SQL <- "SELECT %s FROM chebi_data WHERE chebi_id = '%s'"
      df.chebi <- db.query(sprintf(SQL, .self$sql_select, db_id))

      if(length(df.chebi) == 0) {
        return(NULL)
      }

      # convert to common interface:
      df.chebi$names <- list(pg_str2vector(df.chebi$names[[1]]))

      return (df.chebi)
    },

    query_reverse = function(df.res) {
      hmdb_id <- df.res$hmdb_id[[1]]
      pubchem_id <- df.res$pubchem_id[[1]]
      kegg_id <- df.res$kegg_id[[1]]
      lipidmaps_id <- df.res$lipidmaps_id[[1]]

      # construct complex reverse query
      SQL <- "SELECT chebi_id FROM chebi_data WHERE"
      clauses <- character()

      if (!is.empty(hmdb_id))
        clauses <- c(clauses, sprintf("hmdb_id = '%s'", hmdb_id))
      if (!is.empty(pubchem_id))
        clauses <- c(clauses, sprintf("pubchem_id = '%s'", pubchem_id))
      if (!is.empty(kegg_id))
        clauses <- c(clauses, sprintf("kegg_id = '%s'", kegg_id))
      if (!is.empty(lipidmaps_id))
        clauses <- c(clauses, sprintf("lipidmaps_id = '%s'", lipidmaps_id))

      if (length(clauses) == 0)
        return(NULL)

      SQL <- paste(SQL, paste(clauses, collapse = " OR "))
      df.chebi <- db.query(SQL)

      if(length(df.chebi) == 0) {
        return(NULL)
      }

      return(df.chebi$chebi_id)
    }
  )
)
