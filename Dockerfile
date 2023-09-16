FROM julia:latest

WORKDIR /app
COPY ./src /app
COPY ./data /app/data
COPY ./lib /app/lib

# Instale as dependências
RUN julia -e 'import Pkg; Pkg.add("ArgParse")'
RUN julia -e 'import Pkg; Pkg.add("ErrorTypes")'
RUN julia -e 'import Pkg; Pkg.add("JSON")'

ENV JULIA_PKGDIR=/app/.julia
ENV JULIA_NUM_THREADS=4

RUN echo "#!/bin/sh" >> /app/run.sh
RUN echo "julia -O 3 -g 0 main.jl --file=./data/fib.rinha" >> /app/run.sh
RUN echo "julia -O 3 -g 0 main.jl --file=./data/combination.rinha" >> /app/run.sh
RUN echo "julia -O 3 -g 0 main.jl --file=./data/sum.rinha" >> /app/run.sh

ENTRYPOINT ["/bin/bash", "/app/run.sh"]
