install_databases <- function () {
  source("R/bulkinserts/hmdb.R")
  source("R/bulkinserts/chebi.R")
  source("R/bulkinserts/lipidmaps.R")
  source("R/bulkinserts/secondaries.R")

  print("Checking Postgres install...")

  # todo: custom connection string
  result <- tryCatch({
    db.connect()
  }, error = function(e) {
    print("Please install Postgres and create a database.")

    print("If you have done so, check your database connection setup in config.R:")

    source("R/config.R")

    print(sprintf("  username: '%s'  password: '%s'", dbconf$user, dbconf$passwort))
    print(sprintf("  host: '%s'  port: '%s'", dbconf$host, dbconf$port))
    print(sprintf("  database: '%s'", dbconf$dbname))

    stop(sprintf("DB error received: %s", e))


    # todo: create DB?
    #print("Creating database...")
    return(NULL)
  })


  # Check last progress
  fn_installprog <- 'install.RDS'
  if (file.exists(fn_installprog)) {
    last_step <- readRDS(fn_installprog)

    print(sprintf("Continuing at step '%s'", last_step))
  } else {
    last_step <- 1
    saveRDS(last_step, fn_installprog)
  }

  if (last_step != 1) {
    print(sprintf("Continuing at step #%s", last_step))
  }

  # STEP 1: install HMDB
  if (last_step == 1) {
    bulk_insert_hmdb(fileconf$hmdb_dump_file)

    last_step <- last_step + 1
    saveRDS(last_step, fn_installprog)
  }

  # STEP 2: install CHEBI
  if (last_step == 2) {
    bulk_insert_chebi(fileconf$chebi_dump_file)

    last_step <- last_step + 1
    saveRDS(last_step, fn_installprog)
  }

  # STEP 3: install Lipidmaps
  if (last_step == 3) {
   bulk_insert_lipidmaps(fileconf$lipidmaps_dump_file)

    last_step <- last_step + 1
     saveRDS(last_step, fn_installprog)
  }

  # STEP 4: install secondary tables
  if (last_step == 4) {
    bulk_insert_secondary_ids()

    last_step <- last_step + 1
    saveRDS(last_step, fn_installprog)
  }

  # STEP 5: wrap up
  if (last_step == 5) {
    db.disconnect()
    file.remove(fn_installprog)

    print("Install completed!")
  }
}

#install_databases()
