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
IUSE="ncurses test"
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
}

src_configure() {
	local emesonargs=(
		-Dcow_debug=false
		$(meson_feature ncurses cowdiag)
	)
	meson_src_configure
}

pkg_postinst() {
	elog "Start a CoW session from a Wayland display manager (cow.desktop),"
	elog "or from a TTY with:  river -c cow-start"
	elog
	elog "The default /etc/cow/cow.conf binds Logo+Return to xterm; install a"
	elog "terminal (e.g. x11-terms/xterm with river[xwayland], or gui-apps/foot)"
	elog "or change that binding in ~/.config/cow/cow.conf."
}
