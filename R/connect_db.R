#' Connect to db2
#' 
#' This function allows to connect to db2 database
#' @param driver the path to the jdbc driver
#' @param host The host name of the database.
#' @param port the port number of the database
#' @param dbname the name of the database
#' @param user the user name to log in
#' @param pw the password for the user
#' @export
#' @examples 
#' connect_db(host = "", port = "", user = "", pw = "")


connect_db <- function(driver, host, port, dbname, user, pw){
  jcc = RJDBC::JDBC("com.ibm.db2.jcc.DB2Driver",
                    driver)
  print(paste0("jdbc:db2://", host, ":", port, "/", "dbname"))
  conn = RJDBC::dbConnect(jcc,
                   paste0("jdbc:db2://", host, ":", port, "/", dbname),
                   user = user,
                   password = pw)
  return(conn)
}



