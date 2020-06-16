library(httr)
library(stringr)

null2na <- function(v) {
  if (is.null(v))
    return(NA)
  else
    return(v)
}

is.empty <- function(v) {
  # + is.null(v)
  return(length(v) == 0 || is.na(v) || v == "" || v == "\n")
}

lstrip <- function(sr, sub) {
  return(substring(sr, nchar(sub)+1, nchar(sr)))
}

join_sql_arr <- function(v) {
  v <- str_replace_all(str_replace_all(v, "'", ''), '"', '')

  return(paste0('{"', paste(v, collapse = '","'), '"}'))
}

pg_vector2str <- function (m) {
  # todo: later
}

pg_str2vector <- function (x) {
  # return found groups of "anystring"
  pattern <- "\"(.+?)\""
  m <- str_match_all(x, pattern)[[1]][,2]

  # if there was no match, then the x string itself is already a word
  if (length(m) == 0)
    return(substr(x, 2, nchar(x)-1))

  # find single words in the rest of the unmatched string
  pattern2 <- "[a-zA-Z0-9_-]+"
  m <- c(m, str_match_all(paste(str_split(x, pattern)[[1]], collapse=""), pattern2)[[1]])

  return(m)
}

convert_df_to_db_array <- function (df, cvectors) {
  # Convert dataframe vector cells to postgres lists
  for (attr in cvectors) {
    v <- df[[1, attr]]

    if (length(v) > 0) {
      df[[attr]] <- c(join_sql_arr(unique(v)))
    } else {
      df[[attr]] <- c(NA)
    }
  }

  return(df)
}

mod <- function(x,m) {
  t1<-floor(x/m)
  return(x-t1*m)
}

create_empty_record <- function (n=1, cnames, cvectors=NULL) {
  df <- data.frame(matrix(ncol = length(cnames), nrow = n))
  colnames(df) <- cnames

  if (!is.null(cvectors)) {
    # convert custom attributes to support bigger cardinality
    for (attr_vec in cvectors) {
      df[[attr_vec]] <- list(vector(length=0))
    }
  }

  return(df)
}

transform_df <- function (df) {
  L <- nrow(df)
  attrs <- names(df)
  df2 <- data.frame(matrix(ncol = length(attrs), nrow = L))
  colnames(df2) <- attrs

  for (attr in attrs) {
    df2[[attr]] <- list(vector(length=0))
  }

  # replace empty string "" to NA in the first row
  df[1][df[1] == ""] <- NA

  # create a dataframe of lists (which contain vectors to store multiple alternative values)
  idx <- !is.na(df)
  df2[idx] <- as.character(df[idx])


  return(df2)
}

revert_df <- function (df) {
  for (attr in names(df)) {
    df[[attr]] <- unlist(lapply(df[[attr]], join_sql_arr))
  }

  return(df)
}

http_call_api <- function (url, db_id) {
  out <- tryCatch({
    r <- GET(sprintf(url,db_id), timeout(resolve.options$http_timeout))

    if (r$status != 200)
      return (NULL)
    return(content(r))
  },
  error=function(cond) {
    print(sprintf("HTTP timeout: %s %s", url, db_id))
    return(NULL)
  })

  if (is.null(out))
    return(NULL)
  return(out)
}

id_to_url <- function (db_id, db_tag = NULL) {
  if (is.null(db_tag)) {
    if (substr(db_id, 1, 4) == 'HMDB')
      db_tag <- 'hmdb_id'
    else if (startsWith(db_id, 'CHEBI:'))
      db_tag <- 'chebi_id'
    else if (substr(db_id, 1, 1) == 'C')
      db_tag <- 'kegg_id'
  }

  if (is.null(db_tag))
    return("")

  if (db_tag == 'hmdb_id')
    url <- "https://hmdb.ca/metabolites/%s"
  else if (db_tag == 'chebi_id')
    url <- "https://www.ebi.ac.uk/chebi/searchId.do;?chebiId=%s"
  else if (db_tag == 'kegg_id')
    url <- "https://www.genome.jp/dbget-bin/www_bget?cpd:%s"
  else if (db_tag == 'pubchem_id')
    url <- "https://pubchem.ncbi.nlm.nih.gov/compound/%s"
  else if (db_tag == 'lipidmaps_id')
    url <- "https://www.lipidmaps.org/data/LMSDRecord.php?LMID=%s"

  return(sprintf(url, db_id))
}
