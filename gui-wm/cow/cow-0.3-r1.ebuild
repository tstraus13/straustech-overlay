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
IUSE="ncurses +themes test"
RESTRICT="!test? ( test )"

DEPEND="
	dev-libs/libbsd
	dev-libs/libevent:=
	dev-libs/wayland
	media-libs/fontconfig
	x11-libs/cairo
	x11-libs/libxkbcommon
	x11-libs/pango
	ncurses? ( sys-libs/ncurses:= )
"
# cow is a river window manager; the session file runs `river -c cow-start`.
RDEPEND="
	${DEPEND}
	gui-wm/river
"
# Man pages are built unconditionally whenever scdoc is found (automagic),
# so always provide it rather than pretending a USE flag controls it.
BDEPEND="
	>=dev-libs/wayland-protocols-1.41
	dev-util/wayland-scanner
	>=sys-devel/bison-3.0
	>=sys-devel/flex-2.6
	app-text/scdoc
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
		# The example themes set titlebar.button.N.action, which cow-0.3
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
	elog "or from a TTY with:  river -c cow-start"
	elog
	elog "The default /etc/cow/cow.conf binds Logo+Return to xterm; install a"
	elog "terminal (e.g. x11-terms/xterm with river[xwayland], or gui-apps/foot)"
	elog "or change that binding in ~/.config/cow/cow.conf."

	if use themes; then
		elog
		elog "Example decoration themes are in ${EROOT}/usr/share/cow/themes."
		elog "Enable one in ~/.config/cow/cow.conf, e.g.:"
		elog "    include /usr/share/cow/themes/redmond98/theme.conf"
		elog "    decor -a redmond98"
	fi
}
