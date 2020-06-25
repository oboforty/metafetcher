source("R/db_ctx.R")
source("R/utils.R")
source('R/discover.R')


fn_dbids <- '../tmp/tests/dbs.RDS'
fn_prog <- '../tmp/tests/resolve_i.RDS'

get_ids <- function (N) {
  ns <- N / 15

  if (file.exists(fn_dbids)) {
    df.dbids <- readRDS(fn_dbids)

    return(df.dbids)
  }

  db_ids <- character(length = 0)
  db_tags <- character(length = 0)


  offset <- round(runif(1, 2000, 50000))
  records <- db.query(sprintf("SELECT chebi_id FROM chebi_data WHERE chebi_id IS NOT NULL LIMIT %s OFFSET %s", ns*3, offset))
  db_ids <- c(db_ids, records$chebi_id)
  db_tags <- c(db_tags, rep(c("chebi_id"), ns*3))

  offset <- round(runif(1, 2000, 50000))
  records <- db.query(sprintf("SELECT pubchem_id FROM chebi_data WHERE pubchem_id IS NOT NULL LIMIT %s OFFSET %s", ns, offset))
  db_ids <- c(db_ids, records$pubchem_id)
  db_tags <- c(db_tags, rep(c("pubchem_id"), ns))

  records <- db.query(sprintf("SELECT kegg_id FROM chebi_data WHERE kegg_id IS NOT NULL LIMIT %s", ns))
  db_ids <- c(db_ids, records$kegg_id)
  db_tags <- c(db_tags, rep(c("kegg_id"), ns))



  offset <- round(runif(1, 2000, 80000))
  records <- db.query(sprintf("SELECT hmdb_id FROM hmdb_data WHERE hmdb_id IS NOT NULL LIMIT %s OFFSET %s", ns*3, offset))
  db_ids <- c(db_ids, records$hmdb_id)
  db_tags <- c(db_tags, rep(c("hmdb_id"), ns*3))

  offset <- round(runif(1, 2000, 10000))
  records <- db.query(sprintf("SELECT pubchem_id FROM hmdb_data WHERE pubchem_id IS NOT NULL LIMIT %s OFFSET %s", ns, offset))
  db_ids <- c(db_ids, records$pubchem_id)
  db_tags <- c(db_tags, rep(c("pubchem_id"), ns))

  records <- db.query(sprintf("SELECT kegg_id FROM hmdb_data WHERE kegg_id IS NOT NULL LIMIT %s", ns))
  db_ids <- c(db_ids, records$kegg_id)
  db_tags <- c(db_tags, rep(c("kegg_id"), ns))



  offset <- round(runif(1, 2000, 35000))
  records <- db.query(sprintf("SELECT lipidmaps_id FROM lipidmaps_data WHERE lipidmaps_id IS NOT NULL LIMIT %s OFFSET %s", ns*3, offset))
  db_ids <- c(db_ids, records$lipidmaps_id)
  db_tags <- c(db_tags, rep(c("lipidmaps_id"), ns*3))

  offset <- round(runif(1, 2000, 25000))
  records <- db.query(sprintf("SELECT pubchem_id FROM lipidmaps_data WHERE pubchem_id IS NOT NULL LIMIT %s OFFSET %s", ns, offset))
  db_ids <- c(db_ids, records$pubchem_id)
  db_tags <- c(db_tags, rep(c("pubchem_id"), ns))

  records <- db.query(sprintf("SELECT kegg_id FROM lipidmaps_data WHERE kegg_id IS NOT NULL LIMIT %s", ns))
  db_ids <- c(db_ids, records$kegg_id)
  db_tags <- c(db_tags, rep(c("kegg_id"), ns))


  # save
  df.dbids <- data.frame(db_tags, db_ids, stringsAsFactors = FALSE)
  saveRDS(df.dbids, fn_dbids)

  return(df.dbids)
}

get_last_progress <- function () {
  if (!file.exists(fn_prog)) {
    # create empty headers
    df.empty <- create_empty_record(0, attr.meta)
    write.table(df.empty, "../tmp/tests/resolve_dump.csv", row.names = FALSE, col.names=TRUE, sep="|", quote=TRUE)


    last_i <- 0
    saveRDS(last_i, fn_prog)
  } else {
    # iteration tracker
    last_i <- readRDS(fn_prog)
  }

  return(last_i)
}

save_progress <- function (i) {
  saveRDS(i, fn_prog)
}

build_csv <- function () {
  db_ids <- get_ids(7500)
  i <- get_last_progress()
  N <- 20
  L <- nrow(db_ids)

  resolve.options$suppress <<- TRUE
  resolve.options$open_connection <<- FALSE

  db.connect()

  start_time <- Sys.time()
  print(sprintf("Parsing %s records. Started at %s", L, start_time))

  while (i < L) {
    df.res <- create_empty_record(20, attr.meta)

    db_tag <- db_ids$db_tags[i:(i+N)]
    db_id <- db_ids$db_ids[i:(i+N)]

    # save db_id in dataframe
    for (j in 1:20) {
      df.res[[j, db_tag[j]]] <- db_id[j]
    }

    result <- resolve(df.res)
    df.out <- revert_df(result$df)

    write.table(df.out, "../tmp/tests/resolve_dump.csv", row.names = FALSE, col.names=FALSE, append = T, sep="|", quote=FALSE)

    print(sprintf("%s/%s...", i, L))
    i <- i + N

    save_progress(i)
  }

  db.disconnect()

  return(NULL)
}


build_csv()
