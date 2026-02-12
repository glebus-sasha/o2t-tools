FROM rocker/tidyverse:latest

# Системные зависимости для пакетов R
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libxml2-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем нужные пакеты R
RUN R -e "install.packages(c('dplyr', 'stringr', 'readr', 'ggplot2', 'plotly', 'EnhancedVolcano', 'htmlwidgets'), repos='https://cloud.r-project.org')"

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
