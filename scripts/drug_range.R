#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(readr)
  library(RobustRankAggreg)
})

# Rscript drug_range.R --input "/c/projects/o2t-tools/data/drug_prioritization/drug_prioritization/drugstone/phenotype_comparison.string.human_links_v12_0_min900.Ensembl.diamond.trustrank.csv" "/c/projects/o2t-tools/data/drug_prioritization/drug_prioritization/drugstone/phenotype_comparison.string.human_links_v12_0_min900.Ensembl.domino.trustrank.csv" "/c/projects/o2t-tools/data/drug_prioritization/drug_prioritization/drugstone/phenotype_comparison.string.human_links_v12_0_min900.Ensembl.firstneighbor.trustrank.csv" --out_prefix "/c/projects/o2t-tools/data/drug_prioritization/drug_prioritization/drugstone/results_"
# --- parse command line arguments ---
args <- commandArgs(trailingOnly = TRUE)

if (!("--input" %in% args)) stop("Must provide --input files")
if (!("--out_prefix" %in% args)) stop("Must provide --out_prefix")

get_arg <- function(flag) {
  pos <- which(args == flag)
  if (length(pos) == 0) return(NULL)
  return(args[pos + 1])
}

out_prefix <- get_arg("--out_prefix")

input_pos <- which(args == "--input")
next_flags <- which(startsWith(args, "--") & seq_along(args) > input_pos)
end_pos <- ifelse(length(next_flags) > 0, next_flags[1] - 1, length(args))
input_files <- args[(input_pos + 1):end_pos]
if (length(input_files) == 0) stop("No input files provided after --input")

cat("Input files:", paste(input_files, collapse = ", "), "\n")
cat("Output prefix:", out_prefix, "\n\n")

# --- read & preprocess data ---
read_method <- function(file) {
  df <- read.csv(file, stringsAsFactors = FALSE) %>%
    rename(score_orig = score) %>%
    select(drugId, X = X, score = score_orig)
  df$method <- basename(file)
  return(df)
}

all_data <- lapply(input_files, read_method) %>% bind_rows()

# --- pivot to wide table ---
combined <- all_data %>%
  tidyr::pivot_wider(
    id_cols = c(drugId, X),
    names_from = method,
    values_from = score
  )

# --- compute rank-based metrics ---
score_cols <- setdiff(colnames(combined), c("drugId", "X"))
max_rank <- nrow(combined)  # используем количество всех препаратов

for (col in score_cols) {
  combined[[paste0(col, "_rank")]] <- rank(-combined[[col]], na.last = "keep", ties.method = "average")
  combined[[paste0(col, "_rank")]] <- ifelse(is.na(combined[[paste0(col, "_rank")]]), max_rank + 1, combined[[paste0(col, "_rank")]])
}

# mean & median rank
rank_cols <- grep("_rank$", colnames(combined), value = TRUE)
combined <- combined %>%
  rowwise() %>%
  mutate(
    mean_rank = mean(c_across(all_of(rank_cols))),
    median_rank = median(c_across(all_of(rank_cols))),
    borda_score = sum(max_rank - c_across(all_of(rank_cols)) + 1),
    n_methods = sum(!is.na(c_across(all_of(score_cols))))
  ) %>%
  ungroup()

# --- RRA ---
rank_lists <- lapply(score_cols, function(col) {
  combined %>% arrange(.data[[paste0(col, "_rank")]]) %>% pull(X)
})
names(rank_lists) <- score_cols
rra <- aggregateRanks(rank_lists)
combined <- left_join(combined, rra, by = c("X" = "Name")) %>% rename(rra_score = Score)

# --- optional consensus score for internal sorting ---
combined <- combined %>%
  mutate(
    consensus_score = as.numeric(scale(borda_score)) +
      as.numeric(scale(n_methods)) -
      as.numeric(scale(mean_rank))
  ) %>%
  arrange(desc(consensus_score))

# --- write output ---
write.csv(combined, paste0(out_prefix, "combined_ranking.csv"), row.names = FALSE)
cat("Combined ranking written to", paste0(out_prefix, "combined_ranking.csv"), "\n")