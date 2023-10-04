FROM julia:1.6.7-bullseye

WORKDIR /app
COPY ./src /app
COPY ./lib /app/lib

# Instale as dependências
RUN julia -e 'import Pkg; Pkg.add("ArgParse")'
RUN julia -e 'import Pkg; Pkg.add("ErrorTypes")'
RUN julia -e 'import Pkg; Pkg.add("JSON")'
RUN julia -e 'import Pkg; Pkg.add("Match")'

ENV JULIA_PKGDIR=/app/.julia
ENV JULIA_NUM_THREADS=4

RUN echo "#!/bin/sh" >> /app/run.sh
RUN echo "julia main.jl --file=/var/rinha/source.rinha.json" >> /app/run.sh

RUN chmod +x ./lib/bin/rinha

ENTRYPOINT ["/bin/bash", "/app/run.sh"]
