# docker run --rm -it -v "$(pwd)":/src -v "$(pwd)"/z88dk-local:/z88dk-local -e ZCCCFG=/z88dk-local/config z88dk/z88dk sh
docker run --rm -it \
       -v "$(pwd)":/src \
       -v "$(pwd)"/z88dk-local:/z88dk-local \
       -v "$(pwd)"/../z88dk-local/config/mycron.cfg:/opt/z88dk/lib/config/mycron.cfg:ro \
       z88dk/z88dk sh
