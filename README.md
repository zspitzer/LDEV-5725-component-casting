# LDEV-5725 Component Casting Error Test

This repository contains tests to reproduce and verify the fix for [LDEV-5725](https://luceeserver.atlassian.net/browse/LDEV-5725).

## The Bug

When upgrading/downgrading Lucee versions, users may encounter:

```
"there is a problem with casting [zip://lucee-admin.lar!/Application.cfc/application_cfc$cf]
to a component (ComponentPageImpl)"
```

## Root Cause

When Lucee is updated while running:

1. Archive bundles (like `lucee-admin.lar`) are installed as OSGi bundles
2. Classes loaded from archives have dependencies on `lucee.runtime.ComponentPageImpl`
3. When the core bundle is updated, the Felix cache can retain **multiple versions** of `lucee.core`
4. Archive bundles may remain wired to the **old** core's classloader
5. Java's `instanceof` check fails because the class identities differ between classloaders

## Workaround

Purging the Felix cache (`lucee-server/felix-cache`) forces OSGi to reinstall all bundles fresh.

## Test Approach

The GitHub Action workflow:

1. Installs Lucee with version A
2. Accesses admin (loads the `lucee-admin.lar` bundle)
3. Drops version B `.lco` in the deploy folder
4. Triggers a restart via admin API
5. Tests admin access - this should trigger the bug if the fix isn't in place

## Running Locally

You can run the tests locally using the Lucee installer on Linux, or adapt for your environment.

## Related Issues

- [LDEV-5659](https://luceeserver.atlassian.net/browse/LDEV-5659) - Multiple bundle versions simultaneously
- [LDEV-5696](https://luceeserver.atlassian.net/browse/LDEV-5696) - Felix cache listing previous versions
- [LDEV-5884](https://luceeserver.atlassian.net/browse/LDEV-5884) - Loader version selection
