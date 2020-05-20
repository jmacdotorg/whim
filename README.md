# Whim

Whim is a command-line utility for sending, receiving, and working with [webmentions](https://www.w3.org/TR/webmention/).

Notable features (both real and _graspably aspirational_) include:

* A daemon to receive and store incoming webmentions

* A webmention verifier, suitable for scheduled operation

* A tool for sending webmentions, individually or en masse (given a source URL)

* Commands to query a local database of received webmentions, with both JSON and human-readable output modes

* A simple webserver to display webmention-powered comment sections as HTML, suitable for JavaScript-driven insertion into an otherwise static webpage

## Not really usable yet (but webmention.io is)

_This software is pre-alpha_ and has no documentation, incomplete test coverage, and inflexible configuration. I hope to continue improving this work over the course of 2020. [See the project's Issues tracker for ongoing status updates.](https://github.com/jmacdotorg/whim/milestone/1)

__If you want to start receiving webmentions right now__, please check out Aaron Parecki's most excellent [Webmention.io](https://webmention.io), a free hosted service that you can start using right away, with any web page. (It is also an open-source project.)

__If you are still curious about Whim__, by all means check it out and [give me a holler](mailto:jmac@jmac.org) if you'd like. I'd be happy to answer any questions about this project or [my other IndieWeb work](https://indieweb.org/User:Jmac.org).

You may also wish to join the [\#whim channel on Freenode IRC](http://webchat.freenode.net/?channels=%23whim), where I am likely idling but listening as `jmac`.

## Building and testing whim locally

[App::cpanminus]: https://metacpan.org/pod/App::cpanminus

Use the CPAN or [App::cpanminus][] tools to install dependencies.

``` shell-session
$ cpanm --installdeps --with-develop .
```

And `prove` for the tests!

``` shell-session
$ prove t/ xt/
⋮
Result: PASS
```

## Running whim

The `whim` executable accepts the following subcommands. Some fine day, they may actually have documentation.

* `daemon`: Run a daemon that listens for incoming webmentions and stores them in a local database

* `send`: Send a webmention

* `query`: Query a local database for stored webmentions meeting given criteria

## "Whim"?

Two possible explanations:

1. It stands for [**whi**te **m**atter](https://en.wikipedia.org/wiki/White_matter), the connective tissue betweeen separate neurological structures in the human brain. Its function resembles Webmention's role in allowing independent websites to communicate, and thus helping their respective authors to collaborate.

1. Whim puts the _hi!_ in **w**eb**m**entions.

## Copyright and licence

This software is Copyright (c) 2020 by Jason McIntosh.

This is free software, licensed under the MIT License.
