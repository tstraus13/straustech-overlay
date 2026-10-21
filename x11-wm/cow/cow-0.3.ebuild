# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson

DESCRIPTION="Compositor on Wayland: a stacking window manager using River as the compositor"
HOMEPAGE="https://cow-wm.codeberg.page/cow/ https://codeberg.org/cow-wm/cow"
SRC_URI="https://codeberg.org/cow-wm/cow/archive/0.3.tar.gz -> ${P}.tar.gz"

# Codeberg's generic archive unpacks to the bare repo name.
S="${WORKDIR}/cow"

LICENSE="ISC"
SLOT="0"
KEYWORDS="~amd64"
IUSE="man"

RDEPEND="
	dev-libs/libbsd
	dev-libs/libevent
	dev-libs/wayland
	dev-libs/wayland-protocols
	gui-libs/pango[cairo]
	media-libs/cairo
	media-libs/fontconfig
	sys-libs/ncurses
	x11-wm/river
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-build/ninja
	dev-util/meson
	virtual/pkgconfig
	sys-devel/bison
	sys-devel/flex
	man? ( app-misc/scdoc )
"

src_configure() {
	# Man pages build automatically when scdoc is found (meson scdoc probe);
	# the man USE flag only controls whether scdoc is provided in BDEPEND.
	local emesonargs=(
		-Dcow_debug=false
	)
	meson_src_configure
}
