# straustech-overlay

Personal git-based Gentoo overlay.

## Enable on your Gentoo box
Create `/etc/portage/repos.conf/straustech.conf`:

    [straustech]
    location = /var/db/repos/straustech
    sync-type = git
    sync-uri = https://github.com/tstraus13/straustech-overlay.git
    auto-sync = true

then: `emaint sync --repo straustech`
