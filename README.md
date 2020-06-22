[![Build Status](https://travis-ci.com/jmacdotorg/whim.svg?branch=master)](https://travis-ci.com/jmacdotorg/whim)
# Whim

Whim is a command-line utility for sending, receiving, and working with [webmentions](https://jmac.org/webmention/).

Notable features include:

- A daemon to receive and store incoming webmentions
- A webmention verifier, suitable for scheduled operation
- A tool for sending webmentions, individually or en masse (given a source URL)
- Commands to query a local database of received webmentions
- A simple webserver to display webmention-powered comment sections as HTML, suitable for JavaScript-driven insertion into an otherwise static webpage

## Project status

### It's alpha

_This software is very young_, with present-but-incomplete documentation and inflexible configuration. It is _absolutely_ full of not just bugs but questionable design decisions that I have yet to acknowledge and address.

I began this project in the spring of 2020, and hope to continue improving it over the course of the year. [See the project's Issues tracker for ongoing status updates.](https://github.com/jmacdotorg/whim/milestone/1)

### Mature alternatives

**If you want to start receiving webmentions right now**, please check out Aaron Parecki's most excellent [Webmention.io](https://webmention.io), a free hosted service that you can start using right away, with any web page. (It is also an open-source project.)

### Contact and support

**If you are still curious about Whim**, by all means check it out and [give me a holler](mailto:jmac@jmac.org) if you'd like. I'd be happy to answer any questions about this project or [my other IndieWeb work](https://indieweb.org/User:Jmac.org).

You may also wish to join the ["#whim" channel on Freenode IRC](http://webchat.freenode.net/?channels=%23whim), where I am likely idling but listening as `jmac`.

## Installing Whim

You need the following stuff already installed to run Whim:

- SQLite
- Perl (version 5.24.0 or higher)
- The \`cpanm\` command-line program. It is likely available as "cpanminus" in your favorite package manager. You can also install it through the instructions at [https://cpanmin.us](https://cpanmin.us).

### Installing Whim via CPAN

_Watch this space..._ Alas, you have to install Whim via source, for now, as described below.

### Installing Whim from source

Install dependencies:

    $ cpanm --installdeps .
    

If you want to test Whim before installing it (this step is optional):

    $ prove -l t/ xt/
    ⋮
    Result: PASS

Finally, install Whim:

    $ perl Makefile.PL
    $ make
    $ make install

## Running whim

The `whim` executable accepts the following subcommands.

- `listen`: Run a daemon that listens for incoming webmentions and stores them in a local database.

    See also ["Displaying webmentions"](#displaying-webmentions), below.

- `send`: Send webmentions.
- `query`: Query a local database for stored, verified webmentions meeting given criteria, and display the results as a human-readable summary.

    (It _should_ offer JSON output as well, but alas it does not right now.)

    This command also lets you view and modify a blocklist of unwelcome webmention sources. Blocked webmentions don't appear in query results.

- `verify`: Try to verify every stored webmention that requires verification.

For quick help on any command, run `whim help [command]`.

For more complete documentation, run `man whim`.

## Displaying webmentions

Besides listening for incoming webmentions, the `listen` command also sets up an HTTP endpont at `/display_wms`. It accepts GET requests that contain one query-string argument, `url`. Whim will fetch and display, as HTML, all verified webmentions whose source matches the given URL.

For example:

    http//example.com:8080/display_wms?url=https://some-source.example/foobar

Whim uses a set of default templates to make this work. You can provide your own templates in `$HOME/.whim/templates`. The fact that I have no further information for you about this is a known issue. (GitHub issue #34)

## "Whim"?

Two possible explanations:

1. It stands for [**whi**te **m**atter](https://en.wikipedia.org/wiki/White_matter), the connective tissue betweeen separate neurological structures in the human brain. Its function resembles Webmention's role in allowing independent websites to communicate, and thus helping their respective authors to collaborate.
2. Whim puts the _hi!_ in **w**eb**m**entions.

## Author and contributors

Whim's lead developer is Jason McIntosh.

Contributors include:

- Adam Herzog
- Brian Wisti

## Copyright and licence

This software is Copyright (c) 2020 by Jason McIntosh.

This is free software, licensed under the MIT License.
