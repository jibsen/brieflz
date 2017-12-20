FROM alpine:3.7

RUN apk add --no-cache gcc meson

WORKDIR /src
RUN git clone -b add-meson --depth 1 https://github.com/jibsen/brieflz.git
WORKDIR brieflz/build
RUN meson .. && ninja && ninja test
