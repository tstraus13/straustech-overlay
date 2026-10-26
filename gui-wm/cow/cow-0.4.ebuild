# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson

DESCRIPTION="Compositor on Wayland: an FVWM/MWM-style stacking window manager for river"
HOMEPAGE="https://cow-wm.codeberg.page/cow/ https://codeberg.org/cow-wm/cow"
SRC_URI="https://codeberg.org/cow-wm/cow/archive/${PV}.tar.gz -> ${P}.tar.gz"
# Codeberg's tag archive unpacks to the bare repository name.
S="${WORKDIR}/${PN}"

LICENSE="ISC"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+appmenu ncurses +themes test"
RESTRICT="!test? ( test )"

# libbsd is optional upstream but used automagically whenever it is found.
DEPEND="
	dev-libs/libbsd
	dev-libs/libevent:=
	dev-libs/wayland
	media-libs/fontconfig
	x11-libs/cairo
	x11-libs/libxkbcommon
	x11-libs/pango
	appmenu? ( dev-libs/libxml2:= )
	ncurses? ( sys-libs/ncurses:= )
"
# cow is a river window manager; the session file runs `river -c cow-start`.
RDEPEND="
	${DEPEND}
	gui-wm/river
"
# Man pages are built whenever lowdown is found (automagic; 0.4 moved from
# scdoc to Markdown + lowdown), so always provide it.
BDEPEND="
	>=dev-libs/wayland-protocols-1.41
	dev-util/wayland-scanner
	>=sys-devel/bison-3.0
	>=sys-devel/flex-2.6
	app-text/lowdown
	virtual/pkgconfig
"

src_prepare() {
	default

	# Upstream derives /etc from ${prefix} ("/usr" + "/etc/cow" ->
	# /usr/etc/cow) both for installing and for the compiled-in
	# COW_SYSCONFDIR; use meson's sysconfdir (/etc on Gentoo) instead.
	local sysconf="get_option('prefix') / get_option('sysconfdir') / 'cow'"
	sed -i \
		-e "s|etc_prefix + '/etc/cow\"'|(${sysconf}) + '\"'|" \
		-e "s|etc_prefix + '/etc/cow'|${sysconf}|" \
		meson.build || die
	grep -q "etc_prefix + '/etc/cow" meson.build && die "sysconfdir fix did not apply"

	if use themes; then
		# The example themes set titlebar.button.N.action, which cow-0.3/0.4
		# accepts in validation but has no option for, so every `include`
		# reports "unknown key". The lines only restate the default button
		# bindings (now done with bind-decoration), so drop them.
		sed -i -E '/^decor -d [^ ]+ titlebar\.button\.[0-9]+\.action /d' \
			examples/themes/*/theme.conf || die
		grep -qE 'titlebar\.button\.[0-9]+\.action' examples/themes/*/theme.conf \
			&& die "theme .action cleanup did not apply"
	fi
}

src_configure() {
	local emesonargs=(
		-Dcow_debug=false
		$(meson_feature appmenu cow_appmenu)
		$(meson_feature ncurses cowdiag)
	)
	meson_src_configure
}

src_install() {
	meson_src_install

	if use themes; then
		insinto /usr/share/cow/themes
		local theme
		for theme in examples/themes/*/; do
			[[ -f ${theme}theme.conf ]] && doins -r "${theme%/}"
		done
		newdoc examples/themes/README.md README.themes.md
	fi
}

pkg_postinst() {
	elog "Start a CoW session from a Wayland display manager (cow.desktop),"
	elog "or from a TTY with:  river -c cow"
	elog
	elog "CoW now loads ${EROOT}/usr/share/cow/cow-defaults.conf first and then"
	elog "~/.config/cow/cow.conf on top of it, so a personal cow.conf should only"
	elog "hold overrides. ${EROOT}/etc/cow/cow.conf is a commented template."
	elog "Inspect the defaults with:  moocow show -D -f config config"

	local v
	for v in ${REPLACING_VERSIONS}; do
		if ver_test "${v}" -lt 0.4; then
			ewarn
			ewarn "Upgrading from CoW ${v}:"
			ewarn " - cow-start was removed; session commands must run 'river -c cow'"
			ewarn "   (e.g. a greetd/tuigreet --cmd 'river -c cow-start' must change)."
			ewarn "   tuigreet --remember-user-session also caches the old command in"
			ewarn "   /var/cache/tuigreet/lastsession-<user>; fix or delete those files."
			ewarn " - ~/.config/cow/cow.conf files copied from the old full system"
			ewarn "   config still work but duplicate the new defaults; trim them"
			ewarn "   down to your own changes. after-start.sh is no longer run."
			break
		fi
	done

	if ! use appmenu; then
		elog
		elog "Built without USE=appmenu: the default Applications menu needs"
		elog "cow-appmenu. Add to cow.conf:  alias applications-refresh script { }"
	fi

	if use themes; then
		elog
		elog "Example decoration themes are in ${EROOT}/usr/share/cow/themes."
		elog "Enable one in ~/.config/cow/cow.conf, e.g.:"
		elog "    include /usr/share/cow/themes/redmond98/theme.conf"
		elog "    decor -a redmond98"
	fi
}
