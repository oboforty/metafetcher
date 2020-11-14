library(httr)
library(stringi)

source("R/db_ctx.R")
source("R/utils.R")


create_kegg_record <- function () {
  kegg_attribs <- c(
    "exact_mass", "mol_weight",
    "comments", "formula", "names",

    "kegg_id", "chebi_id",  "lipidmaps_id",
    # pubchem ID is substance ID only in KEGG!
    #"pubchem_id",
    "ref_etc"
  )

  df <- data.frame(matrix(ncol = length(kegg_attribs), nrow = 1))
  colnames(df) <- kegg_attribs

  # for (attri in kegg_attribs_vec) {
  #   df[[attri]] <- list(vector(length=0))
  # }
  # vector fields: names
  df$names <- list(vector(length=0))

  return(df)
}


KeggHandler <- setRefClass(Class = "KeggHandler",
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
      # Queries a KEGG metabolite record and converts it to a common interface
      SQL <- "SELECT
        kegg_id,chebi_id,lipidmaps_id,
        names,formula,
        exact_mass,mol_weight,
        comments
        FROM kegg_data WHERE kegg_id = '%s'"
      df.kegg <- db.query(sprintf(SQL, db_id))

      if(length(df.kegg) == 0) {
        df.kegg <- .self$call_api(db_id)

        # if api response is still empty, then the record doesn't exist
        if(is.null(df.kegg) || length(df.kegg) == 0)
          return(NULL)

        # cache kegg record
        db.write_df("kegg_data", convert_df_to_db_array(df.kegg, c("names")))
      } else {
        # convert pg array strings to R vectors:
        df.kegg$names <- list(pg_str2vector(df.kegg$names[[1]]))
      }

      # convert to common interface:
      colnames(df.kegg)[colnames(df.kegg)=="exact_mass"]  <-"monoisotopic_mass"
      colnames(df.kegg)[colnames(df.kegg)=="mol_weight"]  <-"mass"

      return (df.kegg)
    },

    query_reverse = function(df.res) {
      chebi_id <- df.res$chebi_id[[1]]
      #pubchem_id <- df.res$pubchem_id[[1]]
      lipidmaps_id <- df.res$lipidmaps_id[[1]]

      # construct complex reverse query
      SQL <- "SELECT kegg_id FROM kegg_data WHERE"
      clauses <- character()

      # todo: itt: construct proper is empty!
      if (!is.empty(chebi_id))
        clauses <- c(clauses, sprintf("chebi_id = '%s'", chebi_id))
      #if (!is.empty(pubchem_id))
      #  clauses <- c(clauses, sprintf("pubchem_id = '%s'", pubchem_id))
      if (!is.empty(lipidmaps_id))
        clauses <- c(clauses, sprintf("lipidmaps_id = '%s'", lipidmaps_id))

      if (length(clauses) == 0)
        return(NULL)

      SQL <- paste(SQL, paste(clauses, collapse = " OR "))
      df.kegg <- db.query(SQL)

      if(length(df.kegg) == 0) {
        return(NULL)
      }

      return(df.kegg$chebi_id)
    },

    call_api = function(db_id) {
      'Calls KEGG api to retrieve record.'

      df.kegg <- create_kegg_record()

      url <- 'http://rest.kegg.jp/get/cpd:%s'
      v <- http_call_api(url, db_id)

      if (is.null(v))
        return(NULL)

      lines <- strsplit(v, "\n", fixed = TRUE, useBytes=TRUE)

      state <- NA

      for (line in lines[[1]]) {
        if (line == "///" || line == "") {
          next
        }

        parts <- strsplit(line, "\\s+")[[1]]

        if (parts[[1]] == "") {
          # remove first empty part in line:
          parts <- parts[-1]
        }

        if (!startsWith(line, "   ")) {
          # new label starts in line:
          state <- parts[[1]]
          parts <- parts[-1]
        }

        if ("ENTRY" == state)
          df.kegg$kegg_id <- parts[[1]]
        else if ("NAME" == state) {
          df.kegg$names[[1]] <- c(df.kegg$names[[1]], parts)
        }
        else if ("FORMULA" == state)
          df.kegg$formula[[1]] <- parts[[1]]
        else if ("EXACT_MASS" == state)
          df.kegg$exact_mass[[1]] <- parts[[1]]
        else if ("MOL_WEIGHT" == state)
          df.kegg$mol_weight[[1]] <- parts[[1]]
        else if ("DBLINKS" == state) {
          db_tag <- tolower(parts[[1]])
          db_tag <- substr(db_tag, 1, nchar(db_tag)-1)

          if (!endsWith(db_tag, "_id"))
            db_tag <- paste(c(db_tag, "_id"), collapse = "")

          if (!db_tag %in% c("kegg_id", "chebi_id", "lipidmaps_id")) # pubchem_id
            next

          # remove db_tag and parse the rest of line as db_id
          parts <- parts[-1]

          if (length(parts) == 1) {
            db_id <- parts[[1]]

            if (db_tag == 'chebi_id' && startsWith(db_id, 'CHEBI:'))
              db_id <- lstrip(db_id, "CHEBI:")

            # simply store
            df.kegg[[1, db_tag]] <- db_id
          } else {
            # todo: store in json string for refs
            # for (db_id in parts) {
            #   df.kegg[[db_tag]][[1]] <- c(df.kegg[[db_tag]][[1]], db_id)
            # }
          }
        }
      }

      return(df.kegg)
    }

  )
)
