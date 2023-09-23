FROM julia:1.6.7-bullseye

WORKDIR /app
COPY ./src /app
COPY ./examples /app/data
COPY ./lib /app/lib

# Instale as dependências
RUN julia -e 'import Pkg; Pkg.add("ArgParse")'
RUN julia -e 'import Pkg; Pkg.add("ErrorTypes")'
RUN julia -e 'import Pkg; Pkg.add("JSON")'

ENV JULIA_PKGDIR=/app/.julia
ENV JULIA_NUM_THREADS=4

RUN echo "#!/bin/sh" >> /app/run.sh
RUN echo "julia main.jl --file=./data/fib.json" >> /app/run.sh
RUN echo "julia main.jl --file=./data/combination.json" >> /app/run.sh
RUN echo "julia main.jl --file=./data/sum.json" >> /app/run.sh
RUN echo "julia main.jl --file=./data/print.json" >> /app/run.sh

RUN chmod +x ./lib/bin/rinha

ENTRYPOINT ["/bin/bash", "/app/run.sh"]
