#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(plotly)
  library(EnhancedVolcano)
  library(htmlwidgets)
})

# -------------------------
# Обработка аргументов
# -------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2 || length(args) > 4) {
  stop(
    "Usage:\n",
    "Rscript volcano_plot.R <data_path> <out_prefix> [pCutoff] [FCcutoff]\n\n",
    "Example:\n",
    "Rscript volcano_plot.R data.tsv volcano_ 0.05 1"
  )
}

data_path  <- args[1]
out_prefix <- args[2]
pCutoff    <- ifelse(length(args) >= 3, as.numeric(args[3]), 0.05)
FCcutoff   <- ifelse(length(args) == 4, as.numeric(args[4]), 1)

# data_path <- 'data/phenotype_comparison.deseq2.results.tsv'
# out_prefix <- 'rez'


# -------------------------
# Чтение данных
# -------------------------
data <- read_delim(data_path, delim = "\t", escape_double = FALSE, trim_ws = TRUE)

# Проверим, есть ли нужные колонки
required_cols <- c("log2FoldChange", "padj")
missing_cols <- setdiff(required_cols, colnames(data))
if (length(missing_cols) > 0) {
  stop("Missing required columns in input: ", paste(missing_cols, collapse = ", "))
}

# -------------------------
# Создание статического Volcano Plot
# -------------------------
png_file <- paste0(out_prefix, "volcano.png")

p <- EnhancedVolcano(
  data,
  lab = rownames(data),
  x = 'log2FoldChange',
  y = 'padj',
  pCutoff = pCutoff,
  FCcutoff = FCcutoff,
  pointSize = 2.0,
  labSize = 3.0
)
p <- p + labs(x = "Log2 Fold Change", y = "-Log10 Adjusted p-value")

ggsave(png_file, plot = p, width = 7, height = 6)
cat("Saved static volcano plot:", png_file, "\n")

# -------------------------
# Создание интерактивного Plotly Volcano
# -------------------------
html_file <- paste0(out_prefix, "volcano.html")

# Подготовка данных для plotly
data$gene <- rownames(data)
data$significant <- "NS"
data$significant[data$padj < pCutoff & data$log2FoldChange > FCcutoff] <- "Up"
data$significant[data$padj < pCutoff & data$log2FoldChange < -FCcutoff] <- "Down"

p_interactive <- plot_ly(
  data,
  x = ~log2FoldChange,
  y = ~-log10(padj),
  text = ~gene,
  color = ~significant,
  colors = c("blue", "grey", "red"),
  type = "scatter",
  mode = "markers",
  marker = list(size = 6),
  hovertemplate = "<b>%{text}</b><br>log2FC: %{x}<br>padj: %{customdata}<extra></extra>",
  customdata = ~padj
) %>%
  layout(
    xaxis = list(title = "Log2 Fold Change"),
    yaxis = list(title = "-Log10 Adjusted p-value")
  )

saveWidget(p_interactive, html_file, selfcontained = TRUE)
cat("Saved interactive volcano plot:", html_file, "\n")
