FROM rocker/tidyverse:latest

# Системные зависимости
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libxml2-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# --- CRAN пакеты ---
RUN R -e "install.packages(c('dplyr', 'stringr', 'readr', 'ggplot2', 'plotly', 'htmlwidgets', 'optparse'), repos='https://cloud.r-project.org')"

# --- Bioconductor пакеты ---
RUN R -e "if (!requireNamespace('BiocManager', quietly=TRUE)) install.packages('BiocManager', repos='https://cloud.r-project.org'); BiocManager::install(c('EnhancedVolcano','WebGestaltR'), update=FALSE, ask=FALSE)"

# Копируем R-скрипты
COPY scripts/ /usr/local/bin/

# Делаем скрипты исполняемыми
RUN chmod +x /usr/local/bin/*.R

# Алиасы без .R
RUN for f in /usr/local/bin/*.R; do ln -s "$f" "${f%.R}"; done

# Рабочая директория
WORKDIR /usr/local/bin

# По умолчанию — интерактивный shell
ENTRYPOINT ["/bin/bash"]
