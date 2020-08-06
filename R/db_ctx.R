require("RPostgreSQL")
source("R/config.R")

mydb_conn <- NULL
localis_connected <- FALSE


db.connect <- function (conf = NULL) {
  # overwrite default config
  if (!is.null(conf))
    dbconf <- conf;

  # connect to DB
  drv <- dbDriver("PostgreSQL")
  mydb_conn <- dbConnect(drv, dbname = dbconf$dbname, host = dbconf$host, port = dbconf$port, user = dbconf$user, password = dbconf$password)
  localis_connected <- TRUE

  return (mydb_conn)
}

db.query <- function (SQL) {
  if (!localis_connected) {
    db.connect()
  }

  df <- dbGetQuery(db_conn, SQL)
  return(df)
}

db.disconnect <- function () {
  dbDisconnect(db_conn)

  localis_connected <- FALSE
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

db.create_database <- function (conf = NULL) {
  # overwrite default config
  if (!is.null(conf))
    dbconf <- conf;

  # connect to DB
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, host = dbconf$host, port = dbconf$port, user = dbconf$user, password = dbconf$password)

  # create database
  dbGetQuery(con, sprintf("CREATE DATABASE %s", dbconf$dbname))
  dbCommit(con)
  dbDisconnect(con)
}
