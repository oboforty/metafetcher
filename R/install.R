install_databases <- function () {
  source("R/bulkinserts/hmdb.R")
  source("R/bulkinserts/chebi.R")
  source("R/bulkinserts/lipidmaps.R")

  print("Checking Postgres install...")

  # todo: custom connection string
  result <- tryCatch({
    db.connect()

    return(1)
  }, error = function(e) {
    return(-1)
  })

  if (result == -1) {
    print("Please install Postgres and create a database.")

    # todo: create DB?
    #print("Creating database...")
    return(NULL)
  }

  last_step <- 1
  fn_installprog <- '../tmp/install.RDS'

  if (file.exists(fn_installprog)) {
    last_step <- readRDS(fn_installprog)

    print(sprintf("Continuing at step '%s'", last_step))

  }

  # todo: continue at step

  print("Checking existing tables...")
  if (last_step == 1) {
    # ??
    last_step <- last_step + 1
    saveRDS(last_step, fn_installprog)
  }

  if (last_step == 2) {
    bulk_insert_hmdb(paste(filepath,"/hmdb_metabolites.xml",sep = ""))

    last_step <- last_step + 1
    saveRDS(last_step, fn_installprog)
  }

  if (last_step == 3) {
    bulk_insert_chebi(paste(filepath,"/ChEBI_complete.sdf",sep = ""))

    last_step <- last_step + 1
    saveRDS(last_step, fn_installprog)
  }

  if (last_step == 4) {
    bulk_insert_lipidmaps(paste(filepath,"/lipidmaps.sdf",sep = ""))

    last_step <- last_step + 1
    saveRDS(last_step, fn_installprog)
  }

  if (last_step == 5) {
    print("Creating secondary id table...")

    db.query("CREATE TABLE IF NOT EXISTS secondary_id (
      db_tag VARCHAR(12) NOT NULL,
      secondary_id VARCHAR(20) NOT NULL,
      primary_id VARCHAR(20),
      PRIMARY KEY (db_tag, secondary_id)
    )")

    db.query("INSERT INTO secondary_id
      SELECT 'chebi_id' as db_tag, unnest(chebi_id_alt) as secondary_id, chebi_id as primary_id
      FROM chebi_data
    ")

    db.query("INSERT INTO secondary_id
      SELECT 'hmdb_id' as db_tag, unnest(hmdb_id_alt) as secondary_id, hmdb_id as primary_id
      FROM hmdb_data
    ")

    last_step <- last_step + 1
    saveRDS(last_step, fn_installprog)
  }
}

install_databases()
