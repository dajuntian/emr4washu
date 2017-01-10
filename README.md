# emr4washu

## Overview
The R package of emr4washu wraps up some of the frequent codes into R package, so we can minimize the copy and paste code. By standadizing the user interface (input, output), it would be easier to pipeline the data flow. The real world healthcare data are dirty, but don't panic. There is always hope. 

The purpose was not to replace any existing tools, rather than a supplemental too whenever necessary.

## Installation (Curently NOT working)
```{r, eval = FALSE}
install.packages("devtools")
devtools::install_github("dajuntian/emr4washu")
library(emr4washu)
```
## If the above  fails, it's probably because I haven't updated the sysdata. You should contact me for the source file, then install through
```{r, eval = FALSE}
#path_to_file looks like "C:/Download/emr4washu0090.tar.gz"
install.packages(path_to_file, repos = NULL, type="source") 
```


## Post-Installation
[download jdbc driver](http://www-01.ibm.com/support/docview.wss?uid=swg21363866). If you already have the IBM client installed, it is usually found at C:\Program Files\IBM\SQLLIB\java\db2jcc4.jar.

[download jre](http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html) and install with the default options
## Example
```{r, eval = FALSE}
conn <- connect_db("C:/mydocument/db2jcc4.jar", # path to the jdbc driver
                              "db.company.org", # the host name
                              10000, # the port number
                              'dbname', # the database name  
                              'abc1234', # username
                              .rs.askForPassword("Enter password:")) #password
charlson(conn, 
         "abc1234.cohort", # the input table containing one column:visit no
         "abc1234.cohort_w_charlson", # the output table name
        ) 
        
lab(conn, 
    "abc1234.cohort", # the input table containing one column:visit no
    "abc1234.cohort_w_lab", # the output table name
    )
RJDBC::dbDisconnect(conn)

#commit the sql file to conn, and generate output as resultset_#
#right now the sql file should not contain any comments
commit_sql(conn, "Z:/EMR/bearhunt.sql") 
commit_sql(conn, "select * from session.ca", file_flag = F)
```
