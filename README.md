# JIRA Security Updater

This docker container modifies Jira so that it will allow you to update
to a version of Jira that does not have a security vulnerability that you
are currently exposed to.

## This can only be used in Australia!

Before you download this package, be aware that you are only legally entitled
to use this if you are under Australian Copyright jurisdiction.

To be eligible for protection under Section 47D of the Copyright Act, you must
ensure that this:

* Is made from a legitimate copy
* Is only used for Interoperability
* Uses the minimum possible reverse engineered/copied code
* An update is not available to you when you made this

## Usage

Simply clone the repository and type `make build`. That will create a
docker image tagged as jira:`$VERSION` which you can then push to your
CI/CD services and treat as a normal package update.

To ensure compliance with the copyright laws of Australia, no alterations
are made to your licence file. All of your purchased resources are
unchanged.

### Debugging

There is some code that has been commented out and left over in the
Dockerfile to assist with debugging further issues.

