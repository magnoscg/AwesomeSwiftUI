# Security policy

## Supported versions

Fixes go into the latest release and into `develop`. Code you already copied
into your project does not update itself, so check the component again if a
report affects it.

## Reporting a vulnerability

Report it privately through GitHub:
[open a private report](https://github.com/magnoscg/AwesomeSwiftUI/security/advisories/new),
or use "Report a vulnerability" in the Security tab. Please do not open a
public issue, pull request or discussion about it.

Include the component, the iOS version, the steps that show the problem and
what an attacker gains. You will get an answer as soon as possible. The aim is
to release a fix before the details are public, crediting you unless you prefer
otherwise.

## Scope

In scope:

- A component that exposes user data, or that behaves unsafely with untrusted
  input.
- The repository's scripts and workflows.
- Code in the catalog whose stated origin or license is false.

Out of scope:

- How an app uses a component once it has been copied and changed.
- The hosting of the documentation site.
