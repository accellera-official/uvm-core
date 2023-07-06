How to Contribute
=================

 This repository is owned by the [Accellera Systems Initiative][1] and
 is maintained by the [Universal Verification Methodology (UVM) Working Group][2] (UVM WG)
 according to the [Accellera Policies and Procedures][3].

 Anyone may report an issue and, if desired, provide a patch to resolve the issue; see the 
 Issue Reporting and Patch Submission sections below for details.  Such issues may be taken
 up by Accellera UVM Working Group members and turned into a contribution to the reference
 implementation.
 **Contributions to the reference implementation can be
   accepted only from Accellera members.**

### Join the Accellera UVM Working Group

 If you would like to contribute to the development of UVM and/or this
 reference implementation, have your company, organization, or university
 join Accellera and its working groups.
 Find out more information at http://www.accellera.org/about/join.
 If your company, organization or university is already an Accellera member,
 you can request to [join the UVM Working Group here][4].

### Join the UVM community forum

 If you are not an Accellera member, please join the **[UVM community
 forum][5]** to provide feedback and join the general
 discussion around the evolution of UVM.

---------------------------------------------------------------------
Issue reporting
---------------------------------------------------------------------

The UVM Community may report functional or efficiency bugs via the [Issue Tracker][6].

A functional bug refers to an issue in the reference implementation wherein the
behavior or functionality deviates from the 1800.2 standard, and that deviation
is not explicitly called out in [DEVIATIONS.md][8]. 

On the other hand, an efficiency bug, also known as a performance bug, refers
to an issue in the reference implementation that affects its overall efficiency
or resource utilization.  An efficiency bug may cause the implementation to 
consume excessive memory, take longer to execute, or use more CPU resources than
necessary.

The [Issue Tracker][6] is only used to track functional and 
efficiency bugs reported by the UVM community.  **All [Issue Tracker][6] requests 
for functional enhancements or new features will be rejected**.  If you'd like to 
contribute a functional enhancement or new feature, please contact a member
of the UVM WG, or better yet please consider [becoming an Accellera Member][10] 
and [joining the UVM WG][4]! 

UVM WG members have access to the WG-internal issue tracking at [MantisHub][7].
Issues tracked via [MantisHub][7] may include functional and efficiency bugs 
as well as new feature requests.

When reporting bugs, please specify the following information (if applicable):

  1. UVM Version
  2. Platform, Compiler, Simulator, Flags
  3. Description of the problem
  4. Steps to reproduce the problem, preferably a small code sample to demonstrate.
  5. Compile/runtime warnings and errors

> **Note**
> All bugs will only be tested against the latest publicly available
> version of the product.

> **Note**
> All C++ compilers and SystemVerilog simulators have bugs of different
> degrees of severity.  We cannot fix those bugs.  Please report them to 
> the appropriate vendor.

---------------------------------------------------------------------
Patch submission
---------------------------------------------------------------------

The following **sign-off procedure** is established to ensure that
patches submitted for inclusion into this Accellera reference
implementation are properly licensed under the
[Apache License Version 2.0](LICENSE).

The sign-off is a simple line at the end of the explanation for the
patch (or commit message), which certifies that you wrote it yourself
or otherwise have the right to pass it on as an open-source patch:

### Accellera Developer's Certificate of Origin

By making a signed-off contribution to this Accellera project,
I certify that:

 1. The contribution was created in whole or in part by me and I have
    the right to submit it under the Apache License Version 2.0
    (see LICENSE).

 2. The contribution was provided directly to me by some other person
    who certified (1) above, and I am forwarding it without
    modification.

 3. I understand and agree that this Accellera project and the
    contribution are public and that a record of the contribution
    (including all personal information I submit with it, including
    my sign-off) is maintained indefinitely and may be redistributed
    in accordance with this project or the Apache License Version 2.0.

If you can certify the above *Accellera Developer's Certificate of Origin*,
please use `git commit --signoff` to add a line of the form:
```
  Signed-off-by: Ima Contributor <ima@contributor.example.org>
```
using your real name (no pseudonyms or anonymous contributions).

> **Note**  
> For Accellera members, contributions are already bound by the
> [Accellera policies and procedures][3] and the sign-off is optional,
> but recommended.  For **non-Accellera** members, the sign-off is
> **mandatory** for consideration by the Accellera WGs.

When a pull-request is submitted against the public repository, it
may be considered by the Accellera UVM WG for inclusion.
An Accellera member may submit it to the private repository with their
own `Signed-off-by` line appended.  It stays under the sole governance
of the UVM WG to decide whether the proposal will be included
in the reference implementation (or future Accellera standards).

---------------------------------------------------------------------
Repository organization
---------------------------------------------------------------------

The central source code repository of the Accellera UVM implementation
is hosted in two repositories at [GitHub](http://github.com).  The main
repositories are **private** to the [`OSCI-WG` GitHub organization][9] and
can be found at:

 * https://github.com/OSCI-WG/uvm-core  (core UVM library)
 * https://github.com/OSCI-WG/uvm-tests (regression test suite)

To obtain access to these repositories and the GitHub organization in general,
UVM members can contact the UVM chairs at <mailto:uvm-chair@lists.accellera.org>
including their GitHub account name.

A read-only, **public** version of these repositories can be found at

 * https://github.com/accellera-official/uvm-core  (core UVM library)
 * https://github.com/accellera-official/uvm-tests (regression test suite)


[1]: https://www.accellera.org
[2]: https://accellera.org/activities/working-groups/uvm
[3]: https://accellera.org/about/policies-and-procedures
[4]: https://workspace.accellera.org/workgroup/index
[5]: https://forums.accellera.org/forum/24-uvm-universal-verification-methodology
[6]: https://github.com/accellera-official/uvm-core/issues
[7]: https://accellera.mantishub.io/my_view_page.php
[8]: DEVIATIONS.md
[9]: https://github.com/osci-wg "Accellera WG GitHub organization"
[10]: http://www.accellera.org/about/join
