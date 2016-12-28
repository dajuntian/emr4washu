# emr4washu

## Overview
emr4washu wraps up some of my recipes into R package, so we can cook more efficiently. The goal is we don't need wash the dirty dishes anymore.

## Installation
```{r, eval = FALSE}
install.packages("devtools")
devtools::install_github("dajuntian/emr4washu")
```
## Post-Installation
download jdbc driver for the database and save it somewhere safe.
## Example
```{r, eval = FALSE}
conn <- emr4washu::connect_db("C:/mydocument/xxx.jar", # path to the jdbc driver
                              "xxx.xxx.xxx", # the host name
                              xxxxx, # the port number
                              'xxx', # the database name  
                              'xxxx', # username
                              .rs.askForPassword("Enter password:")) #password
```
