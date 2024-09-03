Development process of the Accellera UVM implementation
===========================================================
*An HTML-rendered copy of this document can be found at:*
 <https://github.com/accellera-official/uvm-core/blob/main/DEVELOPMENT.md>.


In this document, the internal development process for Accellera's UVM Working Group
is described. This document focuses on the technical aspects related to the development of the
UVM-SV implementation.  Legal and formal procedures are documented at
<http://accellera.org/about/policies>.

---------------------------------------------------------------------
Git pointers
---------------------------------------------------------------------

Comprehensive documentation about [Git][1], a distributed version control
system, can be found in the [Pro Git book][2], also available online.
Since Git is 'distributed', it is a very natural choice for the distributed
development process needed for the collaboratively evolving proof-of-concept
implementation of UVM.


A basic cheat sheet containing the an overview of the general
Git commands and workflow can be found online:
 * [pdf cheatsheet][3]
 * [interactive cheatsheet][4].

 [1]: http://git-scm.com
 [2]: http://git-scm.com/book
 [3]: https://services.github.com/on-demand/downloads/github-git-cheat-sheet.pdf
 [4]: http://ndpsoftware.com/git-cheatsheet.html

---------------------------------------------------------------------
Repository Setup
---------------------------------------------------------------------

The central source code repository of the Accellera UVM implementation is
hosted in two sets of [Git][5] repositories at [GitHub][6].  The main
repositories are **private** to the [`OSCI-WG` organization][7] and can be
found at:

 * https://github.com/OSCI-WG/uvm-core    (core UVM library)
 * https://github.com/OSCI-WG/uvm-tests   (regression test suite)

Members of the GitHub [`OSCI-WG` organization][7] with the necessary access
rights can clone the private repositories via SSH from the locations

     git clone -o osci-wg git@github.com:OSCI-WG/uvm-core.git
     git clone -o osci-wg git@github.com:OSCI-WG/uvm-tests.git

respectively.

To obtain access to these repositories you need an account on [GitHub][6].
The `OSCI-WG` repositories are for Accellera members only. In order to see the private
repositories, you will need to be added to the access list. To gain access, provide
the account details to Accellera by sending your github username to
<mailto:uvm-chair@lists.accellera.org> or <mailto:lynn@accellera.org>
and your account will be enabled.

A read-only, **public** version of these repositories can be found at

 * https://github.com/accellera-official/uvm-core   (core UVM library)
 * https://github.com/accellera-official/uvm-tests  (regression test suite)

The public repositories do not require membership in the [`OSCI-WG` organization][7] 
for access.

 [5]: http://git-scm.com "Git version control system"
 [6]: http://github.com
 [7]: https://github.com/osci-wg "Accellera WG GitHub organization"

### Relationship between private and public repositories

New features and enhancements are developed by the UVM WG in the **private**
repositories, see below.  Please check the [CONTRIBUTING][9] guidelines
how to join Accellera and its working groups to contribute to the
development of UVM.

The **public** repositories are typically updated only together with
public releases of the Accellera UVM reference implementation.

In-between public releases, bug fixes may be published via the public
repositories as well.

 [9]: CONTRIBUTING.md "Contributing to UVM"

### Creating a personal fork

In order to contribute changes to the different repositories, it is
recommended to create personal (or company-based) [forks][10] of the
repositories on GitHub and push the proposed changes (bugfixes,
features, ...) there.

> *Note:*
> Forks of the private repositories are only accessible to members
> of the [`OSCI-WG` GitHub organization][7].  Details of the intended
> work-flow are described in [Basic branch setup](#basic-branch-setup).

It is convenient to add this GitHub fork as a remote to your local
clone of the repository:

      cd <repo>/
      git remote add origin git@github.com:<your-account>/<repo>.git
      git branch --set-upstream master origin/master

Any changes can then be pushed to GitHub using:

      git push [options] [<repository>] [<refspec>...]

 * If you omit the `<repository>`, the default destination is
   the remote of the current branch (or `origin`).
 * The `<refspec>` basically follows the format
    `<local-branch>:<remote-branch>`, or just `<branch>`, if
   both are the same.
 * Omitting the `<refspec>` pushes all branches with 'matching'
   remote branches to the repository.

It is also good to create a few branches tracking the main `OSCI-WG` 
or `accellera-official` branches (The `master` branch has already 
been created).

	(cd uvm-core && git checkout --track osci-wg/release)
    (cd uvm-core && git checkout --track osci-wg/official)

The branch setup can be validated with the following commands and 
should indicate that the local master and release branches are tracking 
the upstream remotes.

```
~/tmp/uvmtest/uvm-core$ git branch -vv
  master  4cb3b20 [osci-wg/master] Merge pull request #39 from OSCI-WG/Mantis_5481
* release 4ed28a0 [osci-wg/release] added starting_phase update to the release notes
~/tmp/uvmtest/uvm-core$ cd ../uvm-tests/
~/tmp/uvmtest/uvm-tests$ git branch -vv
* master 8d95595 [osci-wg/master] Merge pull request #23 from ...
~/tmp/uvmtest/uvm-tests$
```

Since the OSCI-WG repositories and especially `OSCI-WG/master` and 
`OSCI-WG/release` branches are managed by Accellera you should 
consider them as 'read-only' i.e branches which receive your commits 
should have your own repositories as upstream repositories configured.

> *Note:*
> OSCI-WG admins do have write access and CAN push directly to the repos. 
> This capability should limited to repository maintenance only. To be on 
> the safe side the branches `official`, `release`, and `master`
> should never receive local commits and they should never be pushed.
[10]: https://help.github.com/articles/fork-a-repo

### Git RCS Filters

The UVM distribution includes the RCS keywords, e.g. `$keyword$` in 
the source files for the keywords `File`, `Rev`, and `Hash`.

Git does nothing with these keywords by default; however, the Git filter
mechanism can be used to expand these keywords with useful information.

For example:
```
//----------------------------------------------------------------------
// Git details (see DEVELOPMENT.md):
//
// $File$
// $Rev$
// $Hash$
//
//----------------------------------------------------------------------
```

The details of how to enable such filters are beyond the scope of this
document.

---------------------------------------------------------------------
Development flow
---------------------------------------------------------------------


### Basic branch setup

The private **uvm-core** repository accessible via the [`OSCI-WG` GitHub organization][7]
has three primary branches:

* **master**

  The latest and greatest `HEAD` of the UVM development.
  This is, were all the new features and fixes go.

* **official**

  The latest revision pushed to the public repository of UVM.
  This may also include changes that are not yet part of a
  release package.

* **release**

  This branch is used to create the release tarballs, both
  internal and public snapshots. Since the uvm-tests repository 
  is not released in a tarball it does not have a 'release' branch

The `release` branch is different from the `master` branch in that 
it fully tracks the contents of the released tarball.  This requires 
the following changes compared to the `master` branch:

  - generated documentation added to content
  - internal files are stripped
    (`.gitignore`, internal documentation, ...).

To prepare a release, the `master` branch would then be merged into the
`release` branch and the clean working tree could be used as baseline for
the tarball (e.g., via `git-archive(1)`).  Details are described in the 
[release management document][12].  The history of the (core library)
repostitory could then look like shown in the following graph
(time progresses upwards):

       time  feature   master  hotfix official
             branches    |          | |
        ^      |  |
        |                [master]
        |                |            [official]
        ^          ----- o            |
        |         /      |            o - [uvm-1.4.1]
        |        /    -- o           /|
        |       /    /   |          o |
        ^      |  o--   ...          \|
        |      o ...     |  --------- o - [uvm-1.4]
        |      |  o     .../          |
        |      o   \---- o -[release] ..
        ^       \       \|            |
        |        ------- o            o   (internal snapshot)
        |               ...           |
        ^                             o - [uvm-1.3]

It should usually be sufficient to keep the two branches `master`
and `official`, and cherry-pick hotfixes for emergency releases
directly on top of the `official` branch. For convenience, an
additional `release` branch is used to mark the branching
point for the last release to the public repositories.

If more sophisticated version branches are needed, a development
model similar to the well-known ["successful branching model"][11]
can be deployed.  Not all aspects of this model are expected to
be needed for the UVM implementation, as we usually
maintain only a single (i.e., the latest) public release.

[11]: http://nvie.com/posts/a-successful-git-branching-model/ "'A successful Git branching model' by Vincent Driessen"
[12]: https://github.com/OSCI-WG/uvm-tests/blob/master/admin/docs/make-github-release.md


### Adding a feature (set)

The development of a new contribution in form of a feature or a
complex bug fix is best done in a new feature branch, which is
forked and checked out from the Accellera `master` branch:

      git checkout -b <company>-<feature-xyz> master

Then code up the new contribution.  Please try to facilitate code
review by other Accellera members by logically grouping your changes into
one commit per addressed issue. For the commit messages, please
consider to follow these suggestions: 

>  *Note:* **Commit messages**
>
>  Though not required, it's a good idea to begin the commit message with
>  a single short (less than 50 character) line summarizing the change,
>  followed by a blank line and then a more thorough description. Tools
>  that turn commits into email, for example, use the first line on the
>  `Subject:` line and the rest of the commit in the body.
>
> *Note:* **Sign-off procedure for commits**
>
> In order to document that contributions are submitted under the
> Apache-2.0 license (see `LICENSE`), a sign-off procedure is
> defined in the [contributing guidelines][9]. 
>
> This sign-off procedure is required for contributions via the 
> public repositories, and optional for contributions via the 
> private repositories.

During the development of the contribution, the `master` branch may
receive other commits. In that case, consider rebasing the commits in
your feature branch onto the `HEAD` of the `master` branch to keep the
history clean. Once the contribution is ready for review by the
working group, push the feature branch in your fork of the respective
repository on GitHub:

      git push <your-github-fork-remote-name> <company>-<feature-xyz>

Then, send a [pull request][14] either manually or via [GitHub][11] to
initiate the code review by the working group members.  The summary
can be manually generated by

      git request-pull master git@github.com/<account>/<repo>.git \
              <company-feature-xyz>

to be sent to the LWG reflector.

To review the proposed contributions, one can either browse the
repository at GitHub, or add the remote location to a local
clone of the repository

      # add the fork to your set of "remotes"
      git remote add <remote-name> git@github.com/<account>/<repo>.git
      git fetch  <remote-name>

      # examine differences
      git diff master..<remote-name>/<company-feature-xyz>
      git log <remote-name>/<company-feature-xyz>

After the contribution is accepted, it will be merged into the working group's
`master` branch by the responsible source code maintainer.  This should
be done with an explicit *merge commit*, to keep the individual 
contributions separated:

      git merge --no-ff --log \
         <remote-name>/<company-feature-xyz>

Instead of fully merging the contribution, the maintainer may choose
to cherry-pick individual commits or to rebase the feature branch on
an intermittently updated `master`. He may also request additional
changes to be done by the submitter. In that case, the submitter may
need to merge recent changes to the `master` branch into his feature
branch before carrying out the requested changes.

After the contribution has been fully merged into `master`, the
feature branch in the local and Github fork may be deleted.

      git branch -d <company-feature-xyz>      # delete local branch
      git push  origin :<company-feature-xyz>  # delete remote branch

[14]: https://help.github.com/articles/using-pull-requests "Using Pull Requests - github:help"

### Updating the `official` branch and repository

The `official` branch of the repository is setup to track pre-release bug patches to the
tarball releases of the reference implementation.  In effect, [accellera-official/uvm-core:main][15]
is the publicly read-only mirror of the privately read/write [OSCI-WG/uvm-core:official][16].
See [CONTRIBUTING][9] for more details on "Functional Bugs."

The `official` branch in `OSCI-WG` gets updates in two ways:
1. When a new release is made, the `official` branch is updated to
   point to that release.
2. When a bug fix patch is accepted for the existing release, the `official` branch
   is updated.

Note that the `official` branch is _not_ updated directly from `master` or `release`,
and shares no common history with either branch.  This is intentional, as it helps
to prevent cross contamination in both the files and commit history.  

To update the `official` branch, a patch file should be generated from a pull request
of [accellera-official/uvm-core:main][15] or [OSCI-WG/uvm-core:master][17].  These patches
can be easily acquired from the github UI by appending `.patch` to the URL for the
pull request.

For example:

```
# The patch for OSCI-WG/uvm-core pull request #500
wget https://github.com/OSCI-WG/uvm-core/pull/500.patch
```

> **Note:** All patches taken from the [accellera-official/uvm-core:main][15] MUST be 
> signed off with a Developer's Certificate of Origin.  See [CONTRIBUTING][9] for more details.

The patch file can then be applied to `OSCI-WG/uvm-core:official` using the following commands:
```
git checkout -b official_issue_<issue_number> --track osci-wg/official
git apply <patch_file>
... possible edits ...
git commit -m "Applying patch for accellera-official/uvm-core#<issue_number>"
git push -u origin official_issue_<issue_number>
```

Note that edits to the patch may be necessary to ensure that the patch is compatible with the
`official` branch.  This could occur if the patch is coming [OSCI-WG/uvm-core:master][17] and
needs tweaks because of enhancements made to `master` since the last tarball, or if the patch
is coming from [accellera-official/uvm-core:main][15] and needs to be merged into other patches
that have been applied.

Applying patches from [OSCI-WG/uvm-core:official][16] to [accellera-official/uvm-core:main][15] 
is done in a similar way as above.

First, the latest commit to [OSCI-WG/uvm-core:official][16] must be tagged to indicate
that this is a patch point.  That tag is then used to produce a patch file for use 
with [accellera-official/uvm-core:main][15].

This can be done using the following command:
```
## These commands are executed in a clone of OSCI-WG/uvm-core
# Make sure you're up to date with OSCI-WG
git checkout master
git fetch --all
# Delete the local branch to ensure a clean work area
git branch -D official
# Create a local branch
git checkout -b official --track osci-wg/official
# Tag this location for the patch
git tag -a OFFICIAL_<VERSION>_PATCH<PATCH_NUMBER> -m "Official Patch <PATCH_NUMBER> for 1800.2 <VERSION>"
git push osci-wg OFFICIAL_<VERSION>_PATCH<PATCH_NUMBER>
# Create a patch file for the latest commit to official
git diff <PREVIOUS_OFFICIAL_TAG> OFFICIAL_<VERSION>_PATCH<PATCH_NUMBER> > official_patch_<PATCH_NUMBER>.patch
```

This patch file can then be used to update the official repository using the following command:
```
## These commands are executed in a clone of accellera-official/uvm-core
# Make sure you're up to date with accellera-official
git checkout main
git fetch --all
# Create a patch branch
git checkout -b official_patch_<PATCH_NUMBER> --track accellera-official/main
# Apply the patch file
git apply <PATCH FILE>
# Commit the changes, making sure to sign the commit
git commit -s -m "Official Patch <PATCH_NUMBER> for 1800.2 <VERSION>"
# Push the changes up, create a pull request to be merged by the WG
git push origin official_patch_<PATCH_NUMBER>
```

The WG can then accept the new pull request and merge the changes into `main`.

[15]: https://github.com/accellera-official/uvm-core "accellera-official/uvm-core:main"
[16]: https://github.com/OSCI-WG/uvm-core/tree/official "OSCI-WG/uvm-core:official"
[17]: https://github.com/OSCI-WG/uvm-core/tree/master "OSCI-WG/uvm-core:master"

---------------------------------------------------------------------
Versioning scheme
---------------------------------------------------------------------

In general, the versioning pattern for the UVM reference
implementation follows a "Major Minor.Patch" scheme. The **major version**
is the UVM version as defined in latest release IEEE Std. 1800.2, 
`2020` as of the writing of this document.  The **minor version** is incremented
for new Accellera releases with functional/additive enhancements.  The **patch version**
is incremented for bugfix/errata only releases.

> **Note**
> The version number of the reference implementation is only incremented when 
> official release tarballs are created.  Patch updates published to the 
> public repositories without an associated tarball shall not cause the 
> version number to change.
>
> **Note** 
> In general, no compatibility guarantees are attached to these version
> numbers, not even for PoC implementation itself, to avoid burdens
> across different UVM implementations.
