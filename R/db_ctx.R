library("RPostgreSQL")
source("R/config1.R")


pkg.globals <- new.env()
pkg.globals$mydb_conn <- NULL
pkg.globals$localis_connected <- FALSE

db.connect <- function (conf = NULL) {



  # overwrite default config
  if (!is.null(conf))
    dbconf <- conf;

  # connect to DB
  drv <- dbDriver("PostgreSQL")
 #e <- new.env(parent=pkg.globals)
  unlockBinding(sym="mydb_conn",env=pkg.globals)
  unlockBinding(sym="localis_connected",env=pkg.globals)
#print("Heyyy1")
  print(get("dbcof$port", envir = pkd.globals))
mydb_conn <<- dbConnect(drv, dbname = dbconf$dbname, host = dbconf$host, port = dbconf$port, user = dbconf$user, password = dbconf$password)
localis_connected <<- TRUE
assign("mydb_conn",mydb_conn,envir = pkg.globals)
assign("localis_connected",localis_connected,envir = pkg.globals)
print("Connected")
print( pkg.globals$mydb_conn)
print(pkg.globals$localis_connected)
  return (mydb_conn)
}





db.query <- function (SQL) {
  if (!pkg.globals$localis_connected) {
    db.connect()
 #   print(" I am here")
  }
#print("Value of db.connect")
#print(pkg.globals$mydb_conn)
print(SQL)
  df <- RPostgreSQL::dbGetQuery(pkg.globals$mydb_conn, SQL)
  return(df)
}

db.disconnect <- function () {
  dbDisconnect(pkg.globals$mydb_conn)
  assign("localis_connected",FALSE,envir = pkg.globals)
 # pkg.globals$localis_connected <- FALSE
}

db.transaction <- function () {
  dbBegin(pkg.globals$mydb_conn)
}

db.commit <- function () {
  dbCommit(pkg.globals$mydb_conn)
}

db.rollback <- function () {
  dbRollback(pkg.globals$mydb_conn)
}

db.write_df <- function (table, df) {
  dbWriteTable(pkg.globals$mydb_conn, table, value = df, append = TRUE, row.names = FALSE)
}

db.create_database <- function (conf = NULL) {
  # overwrite default config
  if (!is.null(conf))
    dbconf <- conf;

  # connect to DB
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, host = dbconf$host, port = dbconf$port, user = dbconf$user, password = dbconf$password)

  # create database
  RPostgreSQL::dbGetQuery(con, sprintf("CREATE DATABASE %s", dbconf$dbname))
  dbCommit(con)
  dbDisconnect(con)
}
