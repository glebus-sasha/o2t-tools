#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(WebGestaltR)
  library(dplyr)
  library(readr)
  library(optparse)
})

# ---- define command line options ----
option_list <- list(
  make_option("--input", type="character", help="Input file path (TSV)"),
  make_option("--method", type="character", help="ORA or GSEA"),
  make_option("--organism", type="character", default="hsapiens",
              help="Organism (default: hsapiens)"),
  make_option("--id_space", type="character",
              help="ensembl or symbol (affects which column to use)"),
  make_option("--databases", type="character",
              help="Comma-separated list of enrichment databases"),
  make_option("--output", type="character", default="webgestalt_out",
              help="Output directory")
)

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

# ---- check required arguments ----
if (is.null(opt$input) ||
    is.null(opt$method) ||
    is.null(opt$id_space) ||
    is.null(opt$databases)) {
  print_help(opt_parser)
  stop("Missing required arguments\n", call.=FALSE)
}

# ---- process databases ----
enrich_db <- strsplit(opt$databases, ",")[[1]]

# ---- read input file ----
data <- read_delim(opt$input, delim="\t", escape_double = FALSE, trim_ws = TRUE)

# ---- select interest column based on id_space ----
interest_col <- case_when(
  opt$id_space == "symbol"  ~ "gene_name",
  opt$id_space == "ensembl" ~ "gene_id",
  TRUE ~ stop("id_space must be 'symbol' or 'ensembl'")
)

if (!(interest_col %in% colnames(data))) {
  stop(paste("Column", interest_col, "not found in input file"))
}

# ---- prepare input depending on method ----
if (toupper(opt$method) == "GSEA") {
  
  required_cols <- c("log2FoldChange", "pvalue", interest_col)
  missing_cols <- setdiff(required_cols, colnames(data))
  if (length(missing_cols) > 0) {
    stop(paste("For GSEA, input must contain columns:", paste(missing_cols, collapse=", ")))
  }
  
  gsea_data <- data %>%
    filter(!is.na(pvalue)) %>%
    mutate(rank_metric = sign(log2FoldChange) * -log10(pvalue)) %>%
    select(all_of(interest_col), rank_metric) %>%
    distinct() %>%
    arrange(desc(rank_metric))
  
  interest_input <- gsea_data
  
} else if (toupper(opt$method) == "ORA") {
  
  interest_input <- data %>%
    pull(all_of(interest_col)) %>%
    unique()
  
} else {
  stop("method must be ORA or GSEA")
}

# ---- run WebGestaltR ----
WebGestaltR(
  organism = opt$organism,
  enrichMethod = toupper(opt$method),
  enrichDatabase = enrich_db,
  interestGene = interest_input,
  interestGeneType = ifelse(opt$id_space == "symbol", "genesymbol", "ensembl_gene_id"),
  referenceSet = "genome_protein-coding",
  isOutput = TRUE,
  outputDirectory = opt$output
)

cat("WebGestaltR analysis completed successfully.\n")
cat("Output written to:", opt$output, "\n")
