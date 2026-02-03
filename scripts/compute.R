#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(readr)
})

# data_path <- 'C:/projects/o2t-tools/data/drug_prioritization/drug_prioritization/drugstone/phenotype_comparison.string.human_links_v12_0_min900.Ensembl.diamond.trustrank.csv'
# truth_path <- 'C:/projects/o2t-tools/data/drug_prioritization/drug_prioritization/drugstone/truth.csv'
# out_prefix <- 'C:/projects/o2t-tools/results'
# top_n      <- 10

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 4) {
  stop(
    "Usage:\n",
    "Rscript compute_matches.R <data_path> <truth_path> <out_prefix> <top_n>\n\n",
    "Example:\n",
    "Rscript compute_matches.R data.csv truth.csv results 10"
  )
}

data_path  <- args[1]
truth_path <- args[2]
out_prefix <- args[3]
top_n      <- as.integer(args[4])

if (is.na(top_n) || top_n <= 0) {
  stop("top_n must be a positive integer")
}

# --- ensure output dir exists ---
if (!dir.exists(out_prefix)) {
  dir.create(out_prefix, recursive = TRUE)
}

# --- read & preprocess data ---
data <- read.csv(data_path) %>%
  arrange(desc(score)) %>%
  select(drug = X) %>%
  head(top_n) %>%
  mutate(drug = str_trim(drug))

truth <- read.csv(truth_path, header = FALSE, col.names = "drug") %>%
  mutate(drug = str_trim(drug))

# --- compute matches ---
matched_drugs <- inner_join(data, truth, by = "drug")
n_matched <- nrow(matched_drugs)

# --- write outputs ---
matched_drugs_file <- file.path(out_prefix, "matched_drugs.csv")
matched_count_file <- file.path(out_prefix, "matched_count.csv")

write.csv(matched_drugs, matched_drugs_file, row.names = FALSE)
write.csv(data.frame(n_matched = n_matched), matched_count_file, row.names = FALSE)

# --- logging ---
cat("Top N drugs:", top_n, "\n")
cat("Matched drugs:", n_matched, "\n")
cat("Written files:\n")
cat(" -", matched_drugs_file, "\n")
cat(" -", matched_count_file, "\n")
