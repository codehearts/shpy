# :mag: Greetings, Detective

So you're looking to contribute to shpy, eh? Do you think you're ready to face the dangers of gumshoeing shell corporations, sleuthing through pipes, and finding justice for those processes killed in cold blood? Grab your badge, it's time for your first mission!

- [Getting Started](#star2-getting-started)
- [Project Structure](#herb-project-structure)
- [Development](#computer-development)
- [Testing](#alembic-testing)
  - [Writing Tests](#writing-tests)
  - [Running Tests](#running-tests)
- [Submitting Changes](#incoming_envelope-submitting-changes)
- [Release Checklist](#ship-release-checklist)
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

- `test/` - Testing directory
  - `run_tests` - Script to run all tests, returns 0 on success
  - `test_*` - Individual test files, organized by functionality under test
- `examples/` - Practical examples of shpy usage
  - `*/` - An individual example project, such as `coverfetch`
    - `README.md` - Basic example overview and walkthrough of writing the tests
    - `*` - Documented shell script for the example, such as `coverfetch`
    - `test.sh` - Documented tests for the example
- `hooks/` - Hooks for the automated Docker image builds
- `.travis.yml` - Configures continuous integration with Travis CI
- `Dockerfile` - Defines the shpy image used in testing and production
- `docker-compose.yml` - Coordinates execution of multiple shpy containers for testing
- `shpy-shunit2` - The bindings and helpers for integrating shpy with the [shunit2](https://github.com/kward/shunit2) unit testing framework
- `shpy` - The entirety of the shpy codebase

## :computer: Development

Shpy is written in POSIX-compliant shell scripting, with the exception of the `local` keyword. The only required development tool is [Docker](https://docker.com)

When a spy is first created, `_shpy_inited` is set in the environment and a temporary working directory is created. A bin directory is also created and prepended to the path

Spies are implemented with the following metadata written to disk

- `$_shpy_spies_dir/`
  - `bin/`
    - `$spy_name`: Executable shell script to run the spy
  - `outputs/$spy_name/`
    - Contains numbered files, starting from 0, for the spy's output to stdout when called
  - `errors/$spy_name/`
    - Contains numbered files, starting from 0, for the spy's output to stderr when called
  - `$spy_name/`
    - Contains numbered directories, starting from 0, for each call to the spy
      - Contains numbered files, starting from 0, containing each individual argument to a call of the spy

The follow environment variables are also set and exported for each spy:

- `_shpy_${spy_name}_status_codes`: Space-delimited list of status codes to return for a spy, defaults to `"0"`
- `_shpy_${spy_name}_current`: Index of the current call to the spy being examined, used by `wasSpyCalledWith`

## :alembic: Testing

### Writing Tests

Tests are organized in the `test/` directory by function under test, with files named as `test_<function_under_test>`. Each file contains one function per unit test, prefixed with `it` and followed by a description of the test. An example from `test/test_createSpy`:

```sh
itReturns1WhenCreatingSpyWithoutArgs() {
    createSpy >/dev/null
    assertEquals 1 $?
}
```

When writing tests, your assertion message should be lowercase and specify what went wrong, not what was expected. Remember that expected values come before actual values!

```sh
createSpy -o 'hello world' helloSpy
assertEquals 'unexpected spy output' 'hello world' "$(helloSpy)"
```

Tests should verify the expected _stdout_, expected _stderr_, and expected _return value_, even if the expected output is nothing. In some cases it may make sense to omit some of these tests, and that's perfectly ok!

If your test involves calling a spy, you should create a second test case for the same condition that runs the spy in a new shell with `runInNewShell`. This ensures shpy works for sourced _and_ executed scripts

The `assertDies` function is provided for tests that expect `_shpy_die` to be called. This function takes the command to run as a string, an optional expected death message, and an optional expected exit status:

```sh
assertDies 'createSpy -z' 'Error: Unknown option -z' 1
```

The `doOrDie` function is provided to fail a test if the given code returns a non-zero exit status. Use this in situations where code is not expected to fail:

```sh
doOrDie createSpy mySpy
```

The `runInNewShell` function is provided to run a command in a new process of the parent shell. This is useful to simulate shell scripts that are executed rather than sourced:

```sh
runInNewShell mySpy --some --args

# To preserve argument whitespace, you may need to wrap your command in quotes
runInNewShell 'mySpy --message "hello world" file1 file2'
```

### Running Tests

Your code can be tested under multiple shells using the Docker image. To run tests with all supported shells, as well as the analysis tools and code coverage, you can run Docker compose as follows:

```sh
docker-compose up --build \
  && docker-compose ps | grep -v 'Exit 0'
```

To run tests for an example, set the `CMD` environment variable as follows, where `<example>` is the name of the example (renamer, coverfetch)

```sh
CMD=/shpy/examples/<example>/test.sh docker-compose up --build \
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

## :ship: Release Checklist

Shpy releases are versioned using the [semver](https://semver.org) major.minor.patch format

Segment | Reason to bump
:-----  | :-------------
Major   | Breaking changes to the API, such as renaming an existing public function
Minor   | New functionality is added, such as improving the performance of spies or supporting the sourcing of spies
Patch   | Bug fixes, such as fixing an issue where spies did not work with `nounset` set

During a version bump, all segments to the right of the bumped segment are reset to 0, such as 0.0.1 to 0.1.0, 1.2.3 to 2.0.0, and so on

Before creating a new release, run through this checklist to ensure nothing is forgotten!

- [ ] Update the `SHPY_VERSION` variable in `shpy` and its test in `test/test_testEnvironment`
- [ ] Document any public-facing changes in `README.md`
- [ ] Document any architectural or internal API changes in `CONTRIBUTING.md`
- [ ] Once the PR is approved, tag the head of `master` and push

        git tag -a x.y.z -m 'brief description of changes'
        git push origin x.y.z

- [ ] Create a release on GitHub with a fully fleshed description of changes

## :phone: Getting in Touch

For bugs, you can [create a new issue](https://github.com/codehearts/shpy/issues/new) in the tracker. Be sure to describe _what you did_, _what you expected_, and _what actually happened_. If there's anything you tried in response to the issue, that's good to know as well!

For questions or concerns, feel free to reach out to [@codehearts](https://twitter.com/codehearts) on Twitter!
