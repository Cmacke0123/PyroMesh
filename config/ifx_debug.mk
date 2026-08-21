FC = ifx

FFLAGS = \
    -g \
    -O0 \
    -traceback \
    -warn all \
    -check all \
    -check bounds \
    -fpe0 \
    -standard-semantics \
    -fp-model precise \
    -qopenmp \
    -module build/mod