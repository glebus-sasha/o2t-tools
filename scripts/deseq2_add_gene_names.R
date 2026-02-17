#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

# --- parse command-line arguments ---
args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3) {
  stop(
    "Usage:\n",
    "Rscript deseq2_add_gene_names.R <deseq2_results_path> <tx2gene_path> <out_prefix>\n\n",
    "Example:\n",
    "Rscript deseq2_add_gene_names.R phenotype_comparison.deseq2.results.tsv tx2gene.tsv res_"
  )
}

deseq2_results_path <- args[1]
tx2gene_path        <- args[2]
out_prefix          <- args[3]

# deseq2_results_path <- 'data/deseq2_differential/phenotype_comparison.deseq2.results.tsv'
# tx2gene_path <- 'data/tx2gene.tsv'
# out_prefix <- 'name_added'

# --- read input files ---
deseq2_results <- read_delim(deseq2_results_path, delim = "\t", escape_double = FALSE, trim_ws = TRUE)
tx2gene <- read_delim(tx2gene_path, delim = "\t", escape_double = FALSE, trim_ws = TRUE) %>%
  select(gene_id, gene_name) %>%
  distinct()

# --- join gene names ---
res_with_names <- deseq2_results %>%
  left_join(tx2gene, by = "gene_id") %>% 
  select(gene_id, gene_name, everything())

# --- write output ---
out_file <- paste0(out_prefix, "_gene_names_added.tsv")
write_delim(res_with_names, out_file, delim = "\t")

# --- logging ---
cat("Input DESeq2 results:", deseq2_results_path, "\n")
cat("Input tx2gene:", tx2gene_path, "\n")
cat("Output written to:", out_file, "\n")
cat("Total rows:", nrow(res_with_names), "\n")
