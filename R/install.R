install_databases <- function () {
 # source("R/hmdbbulk.R")
#  source("R/hebibulk.R")
 # source("R/lipidmapsbulk.R")
#  source("R/secondariesbulk.R")
#  source("R/config1.R")


  dbconf=NULL
  fileconf=NULL

  dbconf$host <- config::get("host")
  dbconf$port<-as.numeric(config::get("port"))
  dbconf$dbname<-config::get("dbname")
  dbconf$user<-config::get("user")
  dbconf$password<-config::get("password")
 fileconf$hmdb_dump_file <- config::get("hmdbDumpFile")
 fileconf$chebi_dump_file<-config::get("chebiDumpFile")
 fileconf$lipidmaps_dump_file<-config::get("lipidmapsDumpFile")


  print("Checking Postgres install...")

  # todo: custom connection string
  result <- tryCatch({
    db.connect()
  }, error = function(e) {
    print("Please install Postgres and create a database.")

    print("If you have done so, check your database connection setup in config.R:")

    #source("R/config1.R")


    print(sprintf("  username: '%s'  password: '%s'", dbconf$user, dbconf$password))
    print(sprintf("  host: '%s'  port: '%s'", dbconf$host, dbconf$port))
    print(sprintf("  database: '%s'", dbconf$dbname))

   # stop(sprintf("DB error received: %s", e))


    # todo: create DB?
    print("Creating database...")
    db.create_database(dbconf)
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
    print(fileconf$hmdb_dump_file)
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
    SQL="CREATE TABLE kegg_data (
	kegg_id VARCHAR(20) NOT NULL,
	names TEXT[],
	exact_mass FLOAT,
	mol_weight FLOAT,
	comments TEXT,
	formula VARCHAR(256),
	chebi_id VARCHAR(20),
	lipidmaps_id VARCHAR(20),
	pubchem_id VARCHAR(20),
	ref_etc TEXT,
	PRIMARY KEY (kegg_id)
)"

    db.query(SQL)
    SQL="CREATE TABLE pubchem_data (
	pubchem_id VARCHAR(20) NOT NULL,
	names TEXT[],
	mass FLOAT,
	weight FLOAT,
	monoisotopic_mass FLOAT,
	logp FLOAT,
	smiles TEXT[],
	inchi TEXT,
	inchikey VARCHAR(27),
	formula VARCHAR(256),
	chebi_id VARCHAR(20),
	kegg_id VARCHAR(20),
	hmdb_id VARCHAR(20),
	chemspider_id VARCHAR(20),
	ref_etc TEXT,
	PRIMARY KEY (pubchem_id)
)"

    db.query(SQL)
      db.commit()
    db.disconnect()
    file.remove(fn_installprog)

    print("Install completed!")
  }
}

# install_databases()
write_config=function(host,port,db_name,user,password,path)
{
  #fileConn<-file("config1.R")
  # cat("dbconf <- list(","\n",
  #     "host =","\"",host,"\"",",","\n",
  #     "dbname =","\"",db_name,"\"",",","\n",
  #     "user =","\"",user,"\"",",","\n",
  #     "password =","\"",password,"\"","\n",
  #     ")","\n",
  #     "fileconf <- list(","\n",
  #     "hmdb_dump_file=","\"",path,"hmdb_metabolites.xml","\"",",","\n",
  #     "chebi_dump_file=","\"",path,"chebi_dump_file.xml","\"",",","\n",
  #     "lipidmaps_dump_file=","\"",path,"LMSD_20191002.sdf","\"","\n",
  #     ")","\n",file=fileConn,sep="")
  # close(fileConn)
  #readLines(fileConn, n = -1)
  #close(fileConn)
  fileConn<-file("config.YML")
  config <- config::get()
  config$trials
  config$dataset



 unlockBinding(sym="dbconf",env=pkg.globals)
  unlockBinding(sym="fileconf",env=pkg.globals)
  print("Heyyy1")

  #-----
   dbconf$host<-host
  dbconf$dbname<-db_name

  dbconf$port<-port
  dbconf$user<-user
  dbconf$password<-password
  dbconf$path<-path
  #
   assign("dbconf",dbconf,envir = pkg.globals)

  #-----here-----


 assign("localis_connected",localis_connected,envir = pkg.globals)
devtools::load_all()
}
