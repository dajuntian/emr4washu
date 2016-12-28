# emr4washu

## Overview
emr4washu wraps up some of my recipes into R package, so we can cook more efficiently. The goal is we don't need to wash the dirty dishes anymore.

## Installation
```{r, eval = FALSE}
install.packages("devtools")
devtools::install_github("dajuntian/emr4washu")
```
## Post-Installation
[download jdbc driver](http://www-01.ibm.com/support/docview.wss?uid=swg21363866). If you already have the IBM client installed, it is usually found at C:\Program Files\IBM\SQLLIB\java\db2jcc4.jar.

[download jre](http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html) and install with the default options
## Example
```{r, eval = FALSE}
conn <- emr4washu::connect_db("C:/mydocument/xxx.jar", # path to the jdbc driver
                              "xxx.xxx.xxx", # the host name
                              xxxxx, # the port number
                              'xxx', # the database name  
                              'xxxx', # username
                              .rs.askForPassword("Enter password:")) #password
emr4washu::charlson(conn, 
                    "patient-list.csv" # the csv file containing one column:visit no
                    )           
```
