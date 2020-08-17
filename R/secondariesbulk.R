source("R/db_ctx.R")
#source("R/migrate.R")


bulk_insert_secondary_ids <- function(filepath) {
    print("Creating secondary id table...")


    db.query("DROP TABLE IF EXISTS secondary_id")

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
}