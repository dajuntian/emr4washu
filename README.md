# emr4washu

## Overview
The R package of emr4washu wraps up some of the frequent sql querries into R package, so we can minimize the copy and paste code. By standadizing the user interface (input, output), it would be easier to pipeline the data flow. The real world healthcare data are dirty, but don't panic. There is always hope. 

The purpose was not to replace any existing tools, rather than a supplemental tool whenever necessary. It only works with our internal database and the workflow is supposed to be consistent for typical queries.

## Installation (Curently NOT working)
```{r, eval = FALSE}
install.packages("devtools")
devtools::install_github("dajuntian/emr4washu")
library(emr4washu)
```
## Alternatively, reqeust the source file from us and then install through
```{r, eval = FALSE}
#"C:/Download/emr4washu0090.tar.gz" should be replaced by the actual location in your computer.
install.packages("C:/Download/emr4washu0090.tar.gz", repos = NULL, type="source") 
```
## Post-Installation
[download jdbc driver](http://www-01.ibm.com/support/docview.wss?uid=swg21363866). If you already have the IBM client installed, it is usually found at C:\Program Files\IBM\SQLLIB\java\db2jcc4.jar.

[download jre](http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html) and install with the default options
## Example
```{r, eval = FALSE}
#The first step is to setup the connectio the database.
conn <- connect_db("C:/mydocument/db2jcc4.jar", # path to the jdbc driver
                              "db.company.org", # the host name, could be found through confluence page
                              10000, # ditto
                              'dbname', # ditto  
                              'abc1234', # this is from DBA
                              .rs.askForPassword("Enter password:")) #password, or save it to ~

#Here the input table should be perminant table in our user schema and should have the column visit_no,
#And the visit_no should be the same type as the VISIT_NO.
#For Apache score, another column INDEX_DATE is required and the type should be datetime 
#(= admission date most likely)
#The output table should also be perminant table and should not exist because DB2 doesn't alow rewrite table

charlson(conn, 
         "abc1234.cohort", # the input table containing one column:visit no
         "abc1234.cohort_w_charlson", # the output table name
        ) 
        
lab(conn, 
    "abc1234.cohort", # the input table containing one column:visit no
    "abc1234.cohort_w_lab", # the output table name
    )
    
#This function is used to commit a sql file to the database and generate output as resultset_1, etc.
#I wrote this function is becuase sometimes I have very complex queries and I would like to separate them 
#into different pieces. And also I can export the data into csv by coding. This way the process would be 
#more easily to be reproduced.
#right now support for comments is limited. Also see ?emr4washu::parse_sql_comments
#It will NOT work if you have something similar to "select * from table where x = '--';"
#or "select * from table where x = '/**/';".
#However, I haven't seen this kind of case so far.
commit_sql(conn, "Z:/EMR/bearhunt.sql") 
commit_sql(conn, "select * from session.candidate", file_flag = F)

#disconnect from the database
RJDBC::dbDisconnect(conn)
```
