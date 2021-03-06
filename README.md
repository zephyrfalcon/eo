# Eo

This is Eo, a stack-based/functional/etc hybrid language.

## Current status

Eo is currently not under active development.

## Requirements

* [ooc](https://ooc-lang.org/)
* pcre library

Currently only tested on Mac OS X (using [Homebrew](https://brew.sh/)). (See `brew info rock` and
`brew info pcre` for more information.)

To compile, just enter `rock` or `rock -v` while in the `eo` toplevel directory. (This should produce a file `eo-main`, among other things.)

To run the Eo test suite, enter `eor --test` in the toplevel directory.  (Don't
bother running the `test` script; this will only produce a few errors. It only
exists to check that the ooc testing framework works, and to see what it does
in case of failures/errors.)

**Update 2017-09-03:** I worked on this in 2015. Currently it still compiles (using
macOS Sierra 10.12.6, XCode 8.8.3, Homebrew 1.3.1), but I get a bunch of
warnings. 

## Rationale

I wanted a stack-based language, but with various higher-level features, like
code blocks, lists and first-class namespaces. Also reader macros and (pseudo)
local variables, to make things easier to understand.

## Documentation

...still needs to be written. For now, "use the code, Luke", as they say. Soz.
(`source/tests` contains a number of test files, which have the form of actual
Eo expressions (as entered at the REPL), and the expected result.)

