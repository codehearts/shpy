# :mag: Greetings, Detective

So you're looking to contribute to shpy, eh? Do you think you're ready to face the dangers of gumshoeing shell corporations, sleuthing through pipes, and finding justice for those processes killed in cold blood? Grab your badge, it's time for your first mission!

- [Getting Started](#star2-getting-started)
- [Project Structure](#herb-project-structure)
- [Development](#computer-development)
- [Testing](#alembic-testing)
- [Submitting Changes](#incoming_envelope-submitting-changes)
- [Getting in Touch](#phone-getting-in-touch)

## :star2: Getting Started

Before you dive in, there are a few ground rules for `shpy` development:

1. shpy must remain POSIX compliant, with the exception of the `local` keyword
1. Support for new shells can be added, but shpy can never lose support for a shell
1. All changes must be covered by existing or new unit tests
1. New features must have documentation

These resources are a big help in understanding what POSIX compliance entails:

- [The POSIX Shell And Utilities](http://shellhaters.org)  
  Provides quick links to different portions of the POSIX shell spec
- [Insufficiently known POSIX shell features](https://apenwarr.ca/log/20110228)  
  Justifies the use of `local` in shell scripting, despite `local` not being POSIX-compliant
- [Dash as `/bin/sh`](https://wiki.ubuntu.com/DashAsBinSh)  
  Details common "bashisms" in shell scripting and how to rewrite them for POSIX compliance

## :herb: Project Structure

- `t/` - Testing directory
  - `run_tests` - Script to run all tests, returns 0 on success
  - `test_*` - Individual test files, organized by functionality under test
- `.travis.yml` - Configures continuous integration with Travis CI
- `Dockerfile` - Defines the shpy image used in testing and production
- `docker-compose.yml` - Coordinates execution of multiple shpy containers for testing
- `shpy-shunit2` - The bindings and helpers for integrating shpy with the [shunit2](https://github.com/kward/shunit2) unit testing framework
- `shpy` - The entirety of the shpy codebase

## :computer: Development

Shpy is written in POSIX-compliant shell scripting, with the exception of the `local` keyword. The only required development tool is [Docker](https://docker.com)

## :alembic: Testing

Your code can be tested under multiple shells using the Docker image. To run tests with all supported shells, as well as the analysis tools and code coverage, you can run Docker compose as follows:

```sh
docker-compose up --build \
  && docker-compose ps | grep -v 'Exit 0'
```

If any services show a non-zero exit state, you can view the output from that service with `docker-compose logs <service>` (e.g. `docker-compose logs shellcheck`)

Code coverage results will be available in the `coverage/` directory at the root of the repo. Opening `coverage/index.html` gives you a web interface to the results

To run tests under a specific shell, or to run a specific analysis tool, you can run one of the following commands:

| Command | Purpose |
| ------- | ------- |
| `docker-compose run ash` | Run all tests with `sh`, which on Alpine Linux is BusyBox's `ash` |
| `docker-compose run bash` | Run all tests with `bash` |
| `docker-compose run checkbashisms` | Check all sources and tests for bash-specific functionality |
| `docker-compose run kcov` | Generate coverage reports for all sources and tests with `kcov` |
| `docker-compose run mksh` | Run all tests with `mksh`, the successor to `pdksh` |
| `docker-compose run shellcheck` | Run static analysis on all sources and tests for warnings and suggestions |
| `docker-compose run zsh` | Run all tests with `zsh` |

## :incoming_envelope: Submitting Changes

Once your code is polished and tests are passing, it's time to submit a pull request! When creating your PR, it's a good idea for your description to explain  _what_ was changed and _why_ the change was needed

Once the CI build for your branch passes and a project owner reviews your code (which should happen within a few days), your change will be rebased into the master branch and your contribution complete! Thanks! :sparkling_heart:

## :phone: Getting in Touch

For bugs, you can [create a new issue](https://github.com/codehearts/shpy/issues/new) in the tracker. Be sure to describe _what you did_, _what you expected_, and _what actually happened_. If there's anything you tried in response to the issue, that's good to know as well!

For questions or concerns, feel free to reach out to [@codehearts](https://twitter.com/codehearts) on Twitter!
