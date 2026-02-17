#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(WebGestaltR)
  library(dplyr)
  library(readr)
  library(optparse)
})

# ---- define options ----
option_list <- list(
  make_option("--input", type="character", help="Input file path"),
  make_option("--method", type="character", help="ORA or GSEA"),
  make_option("--organism", type="character", default="hsapiens",
              help="Organism (default: hsapiens)"),
  make_option("--id_space", type="character",
              help="ensembl or symbol"),
  make_option("--databases", type="character",
              help="Comma-separated databases"),
  make_option("--output", type="character", default="webgestalt_out",
              help="Output directory")
)

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

# ---- check required ----
if (is.null(opt$input) ||
    is.null(opt$method) ||
    is.null(opt$id_space) ||
    is.null(opt$databases)) {
  print_help(opt_parser)
  stop("Missing required arguments\n", call.=FALSE)
}

# ---- process databases ----
enrich_db <- strsplit(opt$databases, ",")[[1]]

# ---- map id_space ----
interestGeneType <- case_when(
  opt$id_space == "symbol"  ~ "genesymbol",
  opt$id_space == "ensembl" ~ "ensembl_gene_id",
  TRUE ~ stop("id_space must be 'symbol' or 'ensembl'")
)

# ---- read data ----
data <- read_delim(opt$input, delim="\t")

# ---- prepare input depending on method ----
if (opt$method == "GSEA") {
  
  if (!all(c("log2FoldChange", "pvalue") %in% colnames(data))) {
    stop("For GSEA input must contain log2FoldChange and pvalue columns")
  }
  
  gsea_data <- data %>%
    filter(!is.na(pvalue)) %>%
    mutate(rank_metric = sign(log2FoldChange) * -log10(pvalue)) %>%
    select(1, rank_metric) %>%
    distinct() %>%
    arrange(desc(rank_metric))
  
  interest_input <- gsea_data
  
} else if (opt$method == "ORA") {
  
  interest_input <- data[[1]]
  
} else {
  stop("method must be ORA or GSEA")
}

# ---- run WebGestaltR ----
WebGestaltR(
  organism = opt$organism,
  enrichMethod = opt$method,
  enrichDatabase = enrich_db,
  interestGene = interest_input,
  interestGeneType = interestGeneType,
  referenceSet = "genome_protein-coding",
  isOutput = TRUE,
  outputDirectory = opt$output
)

cat("Analysis completed\n")
