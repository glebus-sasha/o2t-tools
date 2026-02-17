#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(WebGestaltR)
  library(dplyr)
  library(readr)
  library(optparse)
  library(stringr)
})

# ---- define CLI options ----
option_list <- list(
  make_option("--input", type="character", help="Input file path"),
  make_option("--method", type="character", help="ORA or GSEA"),
  make_option("--organism", type="character", default="hsapiens", help="Organism"),
  make_option("--id_space", type="character", help="ensembl or symbol"),
  make_option("--databases", type="character", help="Comma-separated databases"),
  make_option("--output", type="character", default="webgestalt_out", help="Output directory")
)

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

# ---- log inputs ----
cat("Input parameters:\n")
print(opt)

# ---- check required arguments ----
required_args <- c("input", "method", "id_space", "databases")
missing_args <- required_args[!required_args %in% names(opt) | sapply(opt[required_args], is.null)]
if (length(missing_args) > 0) {
  print_help(opt_parser)
  stop("Missing required arguments: ", paste(missing_args, collapse = ", "), "\n")
}

# ---- clean id_space ----
id_space_clean <- tolower(str_trim(opt$id_space))
if (!(id_space_clean %in% c("symbol", "ensembl"))) {
  stop("id_space must be 'symbol' or 'ensembl', got: ", opt$id_space)
}
interestGeneType <- ifelse(id_space_clean == "symbol", "genesymbol", "ensembl_gene_id")
interestColumn <- ifelse(id_space_clean == "symbol", "gene_name", "gene_id")

# ---- process databases ----
enrich_db <- strsplit(opt$databases, ",")[[1]] %>% str_trim()

# ---- read input file ----
data <- read_delim(opt$input, delim="\t", escape_double = FALSE, trim_ws = TRUE)

# ---- prepare data depending on method ----
if (tolower(opt$method) == "gsea") {
  
  if (!all(c("log2FoldChange", "pvalue") %in% colnames(data))) {
    stop("For GSEA, input file must contain 'log2FoldChange' and 'pvalue' columns")
  }
  
  interest_input <- data %>%
    filter(!is.na(pvalue)) %>%
    mutate(rank_metric = sign(log2FoldChange) * -log10(pvalue)) %>%
    select(interestColumn, rank_metric) %>%
    distinct() %>%
    arrange(desc(rank_metric))
  
} else if (tolower(opt$method) == "ora") {
  
  interest_input <- data %>% unique() %>% str_trim()
  
} else {
  stop("method must be ORA or GSEA, got: ", opt$method)
}

# ---- run WebGestaltR ----
WebGestaltR(
  organism = opt$organism,
  enrichMethod = toupper(opt$method),
  enrichDatabase = enrich_db,
  interestGene = interest_input,
  interestGeneType = interestGeneType,
  referenceSet = "genome_protein-coding",
  isOutput = TRUE,
  outputDirectory = opt$output
)

cat("WebGestaltR analysis finished. Output directory:", opt$output, "\n")
