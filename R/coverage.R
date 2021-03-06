source("R/db_ctx.R")
source("R/utils.R")
source('R/discover.R')



# list of attributes to check the score for
# attr_to_check <- c(names(db_handlers),
#     "inchi", "inchikey", "smiles"
# )
attr_to_check <- names(db_handlers)


do_consistency_test <- function (db, n,attempts,offset) {
  result=NULL
  temp=NULL
  connection=db.connect()
  for(j in 1:attempts)
  {
    print("This is the step i am in now:")
    print(j)
  db_tag <- paste(c(db,'_id'),collapse="")

    records <- db.query(sprintf("SELECT %s FROM %s_data LIMIT %s OFFSET %s", db_tag, db, n,as.integer(runif(1, min=10, max=offset))))

  resolve.options$suppress <- TRUE
  resolve.options$open_connection <- FALSE

  i <- 0
  start_time <- Sys.time()


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

  fileConn<-file("coverage.txt")
  writeLines(c(
  sprintf("Total attributes:", score_total),
  "----------------",
sprintf("Resolved attributes: %s (%s %%)", score_resolved, round(score_resolved/score_total*100)),
sprintf("Ambigous attributes: %s (%s %%)", score_unresolved, round(score_unresolved/score_total*100)),
sprintf("Missing attributes: %s (%s %%)", score_missing, round(score_missing/score_total*100))
 ),fileConn)

 temp=append(as.numeric(round(score_resolved/score_total*100)),as.numeric(round(score_unresolved/score_total*100)))
temp=append(temp,as.numeric(round(score_missing/score_total*100)))
  #print("hello i am in coverage test")

 #fileConn<-file("coverage.txt")

  #writeLines(c("hi","hello"),fileConn)
  close(fileConn)
  print("Hellooo sara")





result=rbind(result,temp)
temp=NULL
print(connection)
kill_db_connections(drv = RPostgreSQL::PostgreSQL())
##dbDisconnect(connection)
##Sys.sleep(10)
  }
 # db.disconnect()
  kill_db_connections(drv = RPostgreSQL::PostgreSQL())
  colnames(result)=c("Resolved attributes","Ambigous attributes","Missing attributes")
  rownames(result)=NULL
return(result)
  }

#do_consistency_test("chebi", 20)


