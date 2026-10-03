# Building zetik-john

zetik-john packages the jumbo edition of John the Ripper from upstream, so it
can ship a newer john than Debian provides. It needs a real build environment
and network access to fetch the pinned source, so it is not built by the quick
lab builder.

## Steps

```sh
sudo apt build-dep .            # or install the Build-Depends by hand
sh get-orig-source.sh           # fetch pinned upstream into the orig tarball
dpkg-buildpackage -b -us -uc    # compile and produce the .deb
```

The result replaces the Debian john (Provides, Conflicts, Replaces: john), so
`zetik-john | john` in the password-audit group installs this when available.

## Verification

After install, `john --list=build-info` shows the jumbo build and format list.
