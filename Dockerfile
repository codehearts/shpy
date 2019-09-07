# Fetch the official shellcheck image
FROM koalaman/shellcheck:v0.7.0 AS shellcheck

# Create a shunit stage to pull the latest commit into /shunit2 
FROM alpine:3.10.1 AS shunit
RUN apk --no-cache add git
RUN git clone --depth 1 https://github.com/kward/shunit2.git

# Base the shpy image on Alpine Linux
FROM alpine:3.10.1

# Install shells and tools available as Alpine packages
# Ncurses is installed for `tput`, which is used by shunit to colorize output
RUN apk --no-cache add \
      ncurses=6.1_p20190518-r0 \
      checkbashisms=2.19.5-r0 \
      bash=5.0.0-r0 \
      mksh=57-r0 \
      zsh=5.7.1-r0

# Create a non-root `shpy` user
RUN addgroup -S shpy && adduser -S shpy -G shpy

# Define the shpy path globally
ENV SHPY_PATH /shpy/shpy

# Copy in shellcheck and shunit2
COPY --from=shellcheck --chown=shpy /bin/shellcheck /usr/local/bin/shellcheck
COPY --from=shunit --chown=shpy /shunit2/shunit2 /usr/local/bin/shunit2

# Create /shpy/ for the non-root user and run as them
RUN mkdir /shpy/ && chown shpy:shpy /shpy/
USER shpy

# Copy the current shpy sources
COPY --chown=shpy ./ /shpy/
WORKDIR /home/shpy/

# By default, run `/bin/sh` (which is `ash` under BusyBox in Alpine Linux)
CMD ["/bin/sh"]
