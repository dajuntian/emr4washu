#' remove comments from sql statements.
#' 
#' This function is used to parse comments from sql statments. It removes
#' something like /* coments*/ or --. But it won't work if there is something
#' like select * from tname where x = '--test'.
#' @param input_sql the statements of sql in string variable
#' @export
#' @examples 
#' parse_sql_comments("select * from t --select \n where t <2")
parse_sql_comments <- function(input_sql) {
    gsub("(--.*)|(((/\\*)+?[\\w\\W]+?(\\*/)+))", " ", input_sql, perl = T)
}

