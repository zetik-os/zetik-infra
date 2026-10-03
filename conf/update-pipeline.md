# Zetik tool update pipeline

Flow: Debian Testing / upstream release -> detection -> provenance review ->
isolated build -> staging -> dependency checks -> functional checks ->
approved snapshot -> signed rolling publication -> normal APT update.

## Policy
- Prefer the Debian package. Maintain own packaging only where it adds value.
- Prefer stable upstream releases; dev versions need explicit opt-in.
- Never mix Kali/Parrot repos into the published system.
- No `sudo pip`, no `curl | sh`, no `git pull` as update mechanism.
- Publish only via the signed Zetik APT repo with `Signed-By`; never `trusted=yes`.

## How a user keeps tools updated / downloads them
On an installed Zetik system the Zetik repo is in
`/etc/apt/sources.list.d/zetik.sources` (deb822, `Signed-By` a keyring):

    sudo apt update && sudo apt full-upgrade          # rolling updates
    sudo apt install nmap                              # one catalog tool
    sudo apt install zetik-tools-web                  # a tool group metapackage

Inspect before installing:

    zetik catalog groups
    zetik catalog show nmap
    zetik tools status

`zetik doctor` refuses to pass if APT sources are unsafe (foreign repo,
`trusted=yes`, or a Zetik source missing `Signed-By`).
