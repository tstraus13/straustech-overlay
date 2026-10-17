# straustech-overlay

Personal git-based Gentoo overlay.

## Enable on your Gentoo box
Create `/etc/portage/repos.conf/straustech.conf`:

    [straustech]
    location = /var/db/repos/straustech
    sync-type = git
    sync-uri = https://git.straustech.net/tstrausbaugh/straustech-overlay.git
    auto-sync = true

then: `emaint sync -s straustech`

## Unmask + install
    echo "dev-util/raddebugger ~amd64" >> /etc/portage/package.accept_keywords/straustech
    emerge --oneshot dev-util/raddebugger::straustech
