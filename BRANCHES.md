# Use of branches

Our development model is aimed to keep `master` in a stable and
releaseable state.  In doing this we use the following branches.

## `master`

`master` is the main development branch, it is where you should be
targetting your changes by default.
 
Our documentation on http://docs.puppetlabs.com/mcollective is built
from the /website directory of `master`, so if you are making changes
that change documented behaviour please take care to mention if the
feature is unreleased.

## `stable`

`stable` is intended as read-only branch that points to the current stable
release.  Do not target changes here.

## Release branches

Release branches are a short-lived concern used when preparing a
release, and are typically cut from the head of `master`.  

The changes aimed at a release branch should be constrained to
updating version number, updating changelogs and making other
documentation changes to reflect the changes in this release.

Once a release is shipped, the release branch will be merged back
to `master`.
