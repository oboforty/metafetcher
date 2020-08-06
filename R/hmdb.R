source("R/db_ctx.R")
source("R/utils.R")


HmdbHandler <- setRefClass(Class = "HmdbHandler",
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
      # treat obvious cases of secondary HMDB id:
      if (nchar(db_id) == 9) {
        db_id <- sprintf('HMDB00%s',substr(db_id, 5, nchar(db_id)))
      }

      # Queries an HMDB metabolite record and converts it to a common interface
      SQL <- "SELECT
        pubchem_id, chebi_id, kegg_id, hmdb_id, metlin_id,
        smiles, inchi, inchikey, formula, names,
        avg_mol_weight as mass, monoisotopic_mol_weight as monoisotopic_mass
        FROM hmdb_data WHERE hmdb_id = '%s'"
      df.hmdb <- db.query(sprintf(SQL, db_id))

      if(length(df.hmdb) == 0) {
        return(NULL)
      }

      # convert pg array strings to R vectors:
      df.hmdb$names <- list(pg_str2vector(df.hmdb$names[[1]]))

      return (df.hmdb)
    },

    query_reverse = function(df.res) {
      chebi_id <- df.res$chebi_id[[1]]
      pubchem_id <- df.res$pubchem_id[[1]]
      kegg_id <- df.res$kegg_id[[1]]

      # construct complex reverse query
      SQL <- "SELECT hmdb_id FROM hmdb_data WHERE"
      clauses <- character()

      if (!is.empty(chebi_id))
        clauses <- c(clauses, sprintf("chebi_id = '%s'", chebi_id))
      if (!is.empty(pubchem_id))
        clauses <- c(clauses, sprintf("pubchem_id = '%s'", pubchem_id))
      if (!is.empty(kegg_id))
        clauses <- c(clauses, sprintf("kegg_id = '%s'", kegg_id))

      if (length(clauses) == 0)
        return(NULL)

      SQL <- paste(SQL, paste(clauses, collapse = " OR "))
      df.hmdb <- db.query(SQL)

      if(length(df.hmdb) == 0) {
        return(NULL)
      }

      return(df.hmdb$chebi_id)
    }
  )
)