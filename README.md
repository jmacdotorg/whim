# Whim

Whim is my working title for a bunch of command-line utilities for sending and  receiving [webmentions](https://www.w3.org/TR/webmention/), as well as querying a local database of stored webmentions.

The query utility lets you maintain a block-list of undesired webmention sources, which it will automatically filter out of any subsequent queries.

Whim also includes a Perl library.

## Not really usable yet (but webmention.io is)

_This software is pre-alpha_ and has no documentation, incomplete test coverage, and inflexible configuration. Today, this repository exists mainly for my own convenience while I work on the project. I hope to continue improving this work over the course of 2020.

__If you want to start receiving webmentions right now__, please check out Aaron Parecki's most excellent [Webmention.io](https://webmention.io), a free hosted service that you can start using right away, with any web page. (It is also an open-source project.)

__If you are still curious about Whim__, by all means check it out and [give me a holler](mailto:jmac@jmac.org) if you'd like. I'd be happy to answer any questions about this project or [my other IndieWeb work](https://indieweb.org/User:Jmac.org).

## Manifest

_Please note that the names of all these utilities and libraries are subject to change._

The command-line utilities include:

* `wmd`: Run a daemon that listens for incoming webmentions and stores them in a local database

* `wms`: Send a webmention

* `wmq`: Query a local database for stored webmentions meeting given criteria

Other stuff:

* `Whim.pm`: A Perl code library with various functions for receiving, storing, and querying webmentions. `wmd` and `wmq` both make use of it.

## "Whim"?

Two possible explanations:

1. It stands for [**whi**te **m**atter](https://en.wikipedia.org/wiki/White_matter), the connective tissue betweeen distant neurological structures that resembles Webmention's role in allowing independent websites to communicate.

1. Whim puts the _hi!_ in webmentions.

## Copyright and licence

This software is Copyright (c) 2020 by Jason McIntosh.

This is free software, licensed under the MIT License.
