#' Project and code management
#'
#' tidyproject is designed to manage tidy project directories and
#' facilitate reproducibility and reuse of code
#'
#' @section Strategy:
#'
#' \itemize{
#'  \item Code management
#'  \itemize{
#'   \item{Project structure: Defines standardised directory structure for statistical projects}
#'   \item{Long term reproducibility: Local (project level) installation of packages}
#'   \item{Code sharing/reuse: code library + search functionality}
#'  }
#' }
#'
#'
#' @section Options:
#' \code{scripts.dir} = names of the "scripts" directory in the project
#'
#' \code{models.dir} = names of the "models" directory in the project
#'
#' \code{git.exists} = \code{TRUE} if git is installed (only works on unix currently)
#'
#' \code{code_library_path} = character vector. paths of directories containing code files
#'
#' To modify these options use the options() interface.
#' To modify these values permanently set options() in ~/.Rprofile or R_HOME/etc/Rprofile.site
#'
#' @examples
#' \dontrun{
#' make_project("~/AZDXXXX/PKAE1")         ## creates new_project
#' code_library()                          ## display summary of code_library
#' preview("template1.R")                  ## preview file in code_library
#' copy_script("template1.R")              ## copy_script from code_library to project
#'
#' new_script("test.R")                    ## Creates empty test.R
#' copy_script("output.data.R")            ## copies from code_library
#' copy_script("../pathto/script.R")       ## copies from other location
#' }
#' @docType package
#' @name tidyproject

NULL

#' Set project options
set_project_opts <- function(){
  ## Internal function: will set all global variables
  ## put as much AZ specific code in here.
  if(is.null(getOption("scripts.dir"))) options(scripts.dir="Scripts")
  if(is.null(getOption("models.dir"))) options(models.dir="Models")
  if(is.null(getOption("git.exists"))) options(git.exists=requireNamespace("git2r", quietly = TRUE))
  if(is.null(getOption("git.ignore.files"))) options(git.ignore.files=c(""))
  if(getOption("git.exists") & is.null(getOption("user.email"))) options(user.email="user@example.org")
}

scripts_dir <- function(proj_name=getwd()){
  normalizePath(file.path(proj_name,getOption("scripts.dir")),winslash = "/",mustWork = FALSE)
}

models_dir <- function(proj_name=getwd()){
  normalizePath(file.path(proj_name,getOption("models.dir")),winslash = "/",mustWork = FALSE)
}

is_tidyproject <- function(directory = getwd()){
  file.exists(scripts_dir(directory)) &
    file.exists(models_dir(directory))
}

check_if_tidyproject <- function(directory = getwd()){
  if(!is_tidyproject(directory)) stop("directory not a tidyproject")
  return(TRUE)
}

#' Setup files
#' @param file.name character indicating name of file to set up
#' @export
setup_file <- function(file.name){
  check_if_tidyproject()
  Sys.chmod(file.name,mode = "744")  ## 744= read-write-executable for user, read only for others
  if(getOption("git.exists")) {
    git2r::add(git2r::repository("."),file.name)
    message(paste(file.name,"added to git"))
  } else message(paste(file.name,"created"))
}

#' Test if full path
#'
#' @param x string giving file/path name
#' @return TRUE only when path starts with ~, /, \\ or X: (i.e. when x is a full path), FALSE otherwise
#' @examples
#' \dontrun{
#' is_full_path("file.text.ext")
#' is_full_path("/path/to/file.text.ext")
#' }


is_full_path <- function(x) grepl("^(~|/|\\\\|([a-zA-Z]:))",x,perl=TRUE)


#' Check tidyproject for best practice compliance
#'
#' @param proj_name character. default = current working directory. path to directory.
#' @param silent logical. default = FALSE. suppress messages or not
#' @param check_rstudio logical (default = FALSE). Check rstudio studio project directory
#' @export

check_session <- function(proj_name=getwd(),silent=FALSE,check_rstudio=TRUE){
  drstudio.exists <- FALSE
  if(check_rstudio & exists(".rs.getProjectDirectory")){
    drstudio.exists <- FALSE
    drstudio <- do_test("rstudio working dir = current working dir"={
      res <- normalizePath(get(".rs.getProjectDirectory")(),winslash = "/") == normalizePath(".",winslash = "/")
      if(res) return(TRUE) else return(paste0(FALSE,": switch to main dir"))
    },silent = silent)
    if(!drstudio$result[drstudio$test=="rstudio working dir = current working dir"])
      stop("FAILED: working directory should be current working directory. setwd() is discouraged")
  }

  d <- do_test("directory is a tidyproject"=
                 is_tidyproject(proj_name),
               "contains Renvironment_info"=
                 file.exists(file.path(proj_name,"Renvironment_info.txt")),
               "up to date Renvironment_info"={
                 script_times <- file.info(ls_scripts(scripts_dir(proj_name)))$mtime
                 if(length(script_times)==0) return("No scripts")
                 if(!file.exists(file.path(proj_name,"Renvironment_info.txt"))) return("no Renvironment_info.txt")
                 envir_time <- file.info(file.path(proj_name,"Renvironment_info.txt"))$mtime
                 time_diff <- difftime(envir_time,max(script_times))
                 result <- time_diff>=0
                 if(result) return(TRUE)
                 paste0(result,": ",signif(time_diff,2)," ",attr(time_diff,"units"))
               },
               "Project library setup"={
                 if(file.exists(file.path(proj_name,"ProjectLibrary"))){
                   res <- normalizePath(file.path(proj_name,"ProjectLibrary"),winslash = "/") == normalizePath(.libPaths()[1],winslash = "/")
                   return(res)
                 } else return(paste0(FALSE,": no project library"))
               },
               silent=silent)
  if(drstudio.exists) d <- rbind(drstudio,d)
  invisible(d)
}

# rate_my_script <- function(script_name,silent=FALSE){
#   tools::file_ext(script_name)=="R"
#   browser()
# }

do_test <- function(...,silent=FALSE){
  x <- match.call(expand.dots = FALSE)$`...`

  eval_x <- logical(length=length(x))
  for(i in seq_along(x)){
    eval_x[i] <- eval(parse(text = deparse(x[[i]])),envir = parent.frame())
  }
  names(eval_x) <- names(x)

  ## check outputs
  lengths <- sapply(eval_x,length)
  if(any(lengths!=1)) stop(paste("Following tests not return single value:\n",paste(names(eval_x)[lengths!=1],sep="\n")))

  if(!silent) for(test_name in names(eval_x)){
    message(substr(paste(test_name,paste(rep(".",600),collapse = "")),1,50),appendLF = FALSE)
    message(eval_x[[test_name]])
  }

  d <- data.frame(test=names(eval_x),result=unlist(eval_x))
  row.names(d) <- NULL
  invisible(d)
}
