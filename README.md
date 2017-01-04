# emr4washu

## Overview
emr4washu wraps up some of my secret recipes into R package, so we can cook more efficiently. The goal is we don't need to wash the dirty dishes anymore.

## Installation
```{r, eval = FALSE}
install.packages("devtools")
devtools::install_github("dajuntian/emr4washu")
library(emr4washu)
```
## Post-Installation
[download jdbc driver](http://www-01.ibm.com/support/docview.wss?uid=swg21363866). If you already have the IBM client installed, it is usually found at C:\Program Files\IBM\SQLLIB\java\db2jcc4.jar.

[download jre](http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html) and install with the default options
## Example
```{r, eval = FALSE}
conn <- connect_db("C:/mydocument/db2jcc4.jar", # path to the jdbc driver
                              "db.company.org", # the host name
                              12000, # the port number
                              'dbname', # the database name  
                              'user', # username
                              .rs.askForPassword("Enter password:")) #password
charlson(conn, 
         "user.cohort", # the table name containing one column:visit no
         "user.cohort_w_charlson", # output table name
         5 # optional, time looking back, 1 or 5 years
        ) 
        
lab(conn, 
    "user.cohort", # the table name containing one column:visit no
    "user.cohort_w_lab", # output table name
    )
dbDisconnect(conn)
```
