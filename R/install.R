install_databases <- function () {
  source("R/hmdbbulk.R")
  source("R/hebibulk.R")
  source("R/lipidmapsbulk.R")
  source("R/secondariesbulk.R")
  source("R/config1.R")




  print("Checking Postgres install...")

  # todo: custom connection string
  result <- tryCatch({
    db.connect()
  }, error = function(e) {
    print("Please install Postgres and create a database.")

    print("If you have done so, check your database connection setup in config.R:")

    source("R/config1.R")

    print(sprintf("  username: '%s'  password: '%s'", dbconf$user, dbconf$password))
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
   # bulk_insert_secondary_ids()

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
write_config=function(host,port,db_name,user,password,path)
{
  # fileConn<-file("R/config1.R")
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
  pkg.globals <- new.env()
  pkg.globals$dbconf <- NULL
  pkg.globals$fileconf<- NULL

  unlockBinding(sym="dbconf",env=pkg.globals)
  unlockBinding(sym="fileconf",env=pkg.globals)
  #print("Heyyy1")
  assign("dbconf",dbconf,envir = pkg.globals)
  dbconf$host<<-host
  dbconf$dbname<<-db_name
  dbconf$port<<-port
  dbconf$user<<-user
  dbconf$password<<-password
  dbconf$path<<-path

 # assign("localis_connected",localis_connected,envir = pkg.globals)
#devtools::load_all()
}
