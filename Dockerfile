#
# Fetch the official shellcheck image
#
FROM koalaman/shellcheck:v0.8.0 AS shellcheck

#
# Create a shunit stage to pull a fixed commit into /shunit2
#
FROM alpine:3.16.0 AS shunit

ARG SHUNIT2_SHA=ba130d69bbff304c0c6a9c5e8ab549ae140d6225
ARG SHUNIT2_URL=https://github.com/kward/shunit2/archive/${SHUNIT2_SHA}.tar.gz
RUN wget ${SHUNIT2_URL} -qO shunit2.tar.gz
RUN tar xzf shunit2.tar.gz && mv shunit2-* shunit2

#
# Create a kcov target to run kcov on debian
#
FROM kcov/kcov:v40 AS kcov

# Create a non-root `shpy` user
RUN useradd -ms /bin/sh shpy

# Define the shpy path globally
ENV SHPY_PATH /shpy/shpy

# Copy in shunit2
COPY --from=shunit --chown=shpy /shunit2/shunit2 /usr/local/bin/shunit2

# Create /shpy, /app, /coverage for the non-root user and run as them
RUN mkdir /shpy /app /coverage && chown shpy:shpy /shpy /app /coverage
USER shpy

# Copy the current shpy sources
COPY --chown=shpy ./ /shpy/
WORKDIR /app/

# By default, run `/bin/sh` (which is `dash` under Debian)
CMD ["/bin/sh"]

#
# Base the shpy image on Alpine Linux
#
FROM alpine:3.16.0 AS shpy

# Enable the community repo to install dash
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories

# Install shells and tools available as Alpine packages
# Ncurses is installed for `tput`, which is used by shunit to colorize output
# Curl is installed for the `coverfetch` example
RUN apk --no-cache add --update-cache \
      ncurses curl checkbashisms bash dash mksh zsh

# Create a non-root `shpy` user
RUN addgroup -S shpy && adduser -S shpy -G shpy

# Define the shpy path globally
ENV SHPY_PATH /shpy/shpy

# Copy in shellcheck and shunit2
COPY --from=shellcheck --chown=shpy /bin/shellcheck /usr/local/bin/shellcheck
COPY --from=shunit --chown=shpy /shunit2/shunit2 /usr/local/bin/shunit2

# Create /shpy/ and /app/ for the non-root user and run as them
RUN mkdir /shpy/ /app/ && chown shpy:shpy /shpy/ /app/
USER shpy

# Copy the current shpy sources
COPY --chown=shpy ./ /shpy/
WORKDIR /app/

# By default, run `/bin/sh` (which is `ash` under BusyBox in Alpine Linux)
CMD ["/bin/sh"]
