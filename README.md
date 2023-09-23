<div align="center">
  <a href="https://github.com/aripiprazole/rinha-de-compiler" alt="Link para o repositório da Rinha de Compiladores" target="_blank">
    <img src="https://raw.githubusercontent.com/aripiprazole/rinha-de-compiler/main/img/banner.png" alt="Logo da Rinha de Compilers">
  </a>
</div>

---

[![Julia](https://github.com/cleissonbarbosa/rinha-compiladores-julia/actions/workflows/julia.yml/badge.svg)](https://github.com/cleissonbarbosa/rinha-compiladores-julia/actions/workflows/julia.yml)

Simple interpreter for the "rinha de compiladores" challenge

⚠️ **Notice**

**<span style="color:red">This project is not finished yet, so it is not recommended to use it in production.</span>**

## Run

1. Install [Julia](https://julialang.org/downloads/)
1. Install PKGs
```bash
julia -e 'import Pkg; Pkg.add("ArgParse")'
julia -e 'import Pkg; Pkg.add("ErrorTypes")'
julia -e 'import Pkg; Pkg.add("JSON")'
```
1. Run
```bash
make run file='./examples/source.rinha.json'
```
---

[Challenge Repo](https://github.com/aripiprazole/rinha-de-compiler)

[LICENSE](LICENSE)