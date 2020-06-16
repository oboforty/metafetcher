require("RPostgreSQL")

db_conn <- NULL
is_connected <- FALSE

db.connect <- function () {
  # connect to DB
  drv <- dbDriver("PostgreSQL")
  db_conn <<- dbConnect(drv, dbname = "metafetcher", host = "localhost", port = 5432, user = "postgres", password = "postgres")
  is_connected <<- TRUE

  return (db_conn)
}

db.query <- function (SQL) {
  if (!is_connected) {
    db.connect()
  }

  df <- dbGetQuery(db_conn, SQL)
  return(df)
}


db.disconnect <- function () {
  dbDisconnect(db_conn)

  is_connected <<- FALSE
}

db.transaction <- function () {
  dbBegin(db_conn)
}

db.commit <- function () {
  dbCommit(db_conn)
}

db.rollback <- function () {
  dbRollback(db_conn)
}

db.write_df <- function (table, df) {
  dbWriteTable(db_conn, table, value = df, append = TRUE, row.names = FALSE)
}
