context("Code Library")

proj_name <- "test_tidyproject"

cleanup <- function(proj_name) {
    if (file.exists(proj_name)) 
        unlink(proj_name, recursive = TRUE, force = TRUE)
    base_proj_name <- paste0(proj_name, ".git")
    if (file.exists(base_proj_name)) 
        unlink(base_proj_name, recursive = TRUE, force = TRUE)
}

test_that("Code library", {
    
    currentwd <- getwd()
    make_project(proj_name)
    on.exit({
        setwd(currentwd)
        cleanup(proj_name)
    })
    
    setwd(proj_name)
    
    dir.create("code_lib_test")
    
    replace_code_library(NULL)
    code_library_path_old <- getOption("code_library_path")
    on.exit(replace_code_library(code_library_path_old))
    expect_true(is.null(code_library_path_old))
    
    expect_message(code_library())
    x <- code_library()
    expect_true(is.data.frame(x) & nrow(x) == 0)
    
    attach_code_library("code_lib_test")
    expect_true(code_library_path() == "code_lib_test")
    expect_true(normalizePath("code_lib_test") %in% normalizePath(getOption("code_library_path")))
    
    write(c("## Description: abc"),
          file = file.path("code_lib_test","test2.R"))
    
    write(c("## Description: def",
            "## Keywords: kword1, kword2"),
          file = file.path("code_lib_test","test3.R"))
    
    write(c("## Description: hij",
            "source(\"test2.R\")",
            "source(\"test3.R\")"),
          file = file.path("code_lib_test","test4.R"))
    
    write(c("## Description: klm"),
          file = file.path("code_lib_test","test5.R"))
    
    expect_true(file.exists(file.path("code_lib_test", "test2.R")))
    
    clib <- code_library(viewer = FALSE, silent = TRUE)
    expect_true("character" %in% class(clib))
    
    clib <- code_library(viewer = FALSE, silent = TRUE, return_info = TRUE)
    expect_true("data.frame" %in% class(clib))
    
    copy_script("test4.R")
    expect_true(file.exists(file.path(getOption("scripts.dir"), "test2.R")))
     
    file_contents <- readLines(file.path(getOption("scripts.dir"), "test2.R"))
    expect_true(length(file_contents) > 2)
    
    unlink(file.path(getOption("scripts.dir"), "test2.R"), force = TRUE)
    copy_file("test2.R", getOption("scripts.dir"))
    expect_true(file.exists(file.path(getOption("scripts.dir"), "test2.R")))
    
    info <- info_scripts(code_library(viewer = FALSE, silent = TRUE), viewer = FALSE)
    expect_true("data.frame" %in% class(info))
    
    copy_script("Scripts/test2.R","test5.R")
    expect_true(file.exists(file.path(getOption("scripts.dir"), "test5.R")))
    
    matched.file <- search_raw(code_library(viewer = FALSE, silent = TRUE), "hi")
    expect_true(normalizePath(matched.file) == normalizePath(file.path("code_lib_test", 
        "test4.R")))
    
    matched.file <- search_raw(code_library(viewer = FALSE, silent = TRUE), "nomatch")
    expect_true(length(matched.file) == 0)

    ## should match file name too    
    matched.file <- search_raw(code_library(viewer = FALSE, silent = TRUE), "test4")
    expect_true(length(matched.file) == 1)
    
    matched.file <- search_raw(code_library(viewer = FALSE, silent = TRUE), "test2")
    expect_true(length(matched.file) == 2)
    
    matched.file <- search_keyword(code_library(viewer = FALSE, silent = TRUE), "kword1")
    expect_true(length(matched.file) == 1)
    
    preview("test4.R")
    
    replace_code_library(NULL)
    expect_true(is.null(getOption("code_library_path")))
    
    get_github_code_library("testCodeLibrary",
                            giturl="https://github.com/tsahota/PMXcodelibrary",
                            config_file="test_config.R")
    
    expect_true(length(readLines("test_config.R"))>0)
    
    
})

