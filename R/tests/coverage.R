source("R/db_ctx.R")
source("R/utils.R")
source('R/discover.R')


# list of attributes to check the score for
# attr_to_check <- c(names(db_handlers),
#     "inchi", "inchikey", "smiles"
# )
attr_to_check <- names(db_handlers)


do_consistency_test <- function (db, n) {
  db_tag <- paste(c(db,'_id'),collapse="")
  records <- db.query(sprintf("SELECT %s FROM %s_data LIMIT %s OFFSET 6000", db_tag, db, n))

  resolve.options$suppress <<- TRUE
  resolve.options$open_connection <<- FALSE

  i <- 0
  start_time <- Sys.time()
  db.connect()

  score_missing <- 0
  score_resolved <- 0
  score_unresolved <- 0
  score_total <- 0

  for (db_id in records[[db_tag]]) {
    df.res <- resolve_single_id(db_tag, db_id)$df
    i <- i + 1

    # check how many
    for (attr in attr_to_check) {
      v <- df.res[[attr]][[1]]

      score_total <- score_total + 1
      if (is.empty(v))
        score_missing <- score_missing + 1
      else {
        if (length(v) == 1) score_resolved <- score_resolved + 1
        else score_unresolved <- score_unresolved + 1
      }
    }


    if (mod(i, 10) == 0)
      print(sprintf("#%s...", i))
  }

  db.disconnect()

  print(sprintf("Total attributes:", score_total))
  print("----------------")
  print(sprintf("Resolved attributes: %s (%s %%)", score_resolved, round(score_resolved/score_total*100)))
  print(sprintf("Ambigous attributes: %s (%s %%)", score_unresolved, round(score_unresolved/score_total*100)))
  print(sprintf("Missing attributes: %s (%s %%)", score_missing, round(score_missing/score_total*100)))
}

do_consistency_test("chebi", 20)


