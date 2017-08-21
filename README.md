# SLHA.jl
SUSY Les Houches Accord (SLHA) reader/writer for Julia

[![DOI](https://zenodo.org/badge/100952789.svg)](https://zenodo.org/badge/latestdoi/100952789)

SLHA files can be read via **readSLHA(<filename>)** which returns a Julia data structure with all SLHA entries.
The SLHA data structure can be written to file via **writeSLHA(<filename>)**. The functions automatically handle lists, matrices, ... . A detailed description of the Julia data structure can be found at the start of SLHA.jl and (hopefully) soon here.

The code has been written and tested when working on [arXiv:1706.04994](https://arxiv.org/abs/1706.04994).
