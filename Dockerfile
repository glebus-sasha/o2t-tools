FROM rocker/tidyverse:latest

# Устанавливаем только нужные пакеты
RUN R -e "install.packages(c('dplyr', 'stringr', 'readr'), repos='https://cloud.r-project.org')"

# Копируем R-скрипты
COPY scripts/ /usr/local/bin/

# Делаем скрипты исполняемыми
RUN chmod +x /usr/local/bin/*.R

# Алиасы без .R
RUN for f in /usr/local/bin/*.R; do ln -s "$f" "${f%.R}"; done

# По умолчанию — интерактивный shell
ENTRYPOINT ["/bin/bash"]
