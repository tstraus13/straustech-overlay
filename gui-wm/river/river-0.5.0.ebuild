# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Zig package-manager dependencies, keyed by the hash in build.zig.zon.
# zig-wlroots and translate-c are pinned to git commits upstream; Codeberg
# serves those commits as tarballs with identical content hashes.
declare -g -r -A ZBS_DEPENDENCIES=(
	[pixman-0.3.0-LClMnz2VAAAs7QSCGwLimV5VUYx0JFnX5xWU6HwtMuDX.tar.gz]='https://codeberg.org/ifreund/zig-pixman/archive/v0.3.0.tar.gz'
	[wayland-0.6.0-lQa1kqz8AQADQmdNJsNhLoNHcnEGEUjrOaPV-dtEnEmX.tar.gz]='https://codeberg.org/ifreund/zig-wayland/archive/v0.6.0.tar.gz'
	[wlroots-0.20.2-dev-jmOlcrJuBABMWPGDKK86BO7zrfmxm17nimqFb0gffZTn.tar.gz]='https://codeberg.org/ifreund/zig-wlroots/archive/c183af18ae35dd5fb3dde709697c8f84bb1dc7f3.tar.gz'
	[xkbcommon-0.4.0-VDqIe0i2AgDRsok2GpMFYJ8SVhQS10_PI2M_CnHXsJJZ.tar.gz]='https://codeberg.org/ifreund/zig-xkbcommon/archive/v0.4.0.tar.gz'
	[translate_c-0.0.0-Q_BUWlL1BgD7PmL27vTsccyNCOvKb-B65O5Ki1ZKm-ED.tar.gz]='https://codeberg.org/ifreund/translate-c/archive/64570104eeed461dc221e77574cd3f1c5b7eb974.tar.gz'
	# Transitive: translate-c -> aro; zig-wlroots -> its own xkbcommon pin.
	[aro-0.0.0-JSD1QmbSNgDrBkBPRoDPwy1rN1ABGBa7B1NzC-lqnGxw.tar.gz]='https://codeberg.org/ifreund/arocc/archive/1bf978f1e63d4fe66a90b6637ba709e9abc3c854.tar.gz'
	[xkbcommon-0.3.0-VDqIe3K9AQB2fG5ZeRcMC9i7kfrp5m2rWgLrmdNn9azr.tar.gz]='https://codeberg.org/ifreund/zig-xkbcommon/archive/v0.3.0.tar.gz'
)

ZIG_SLOT="0.16"
# Zig's self-hosted linker cannot handle the SFrame sections in
# glibc >= 2.39 crt objects; build with the LLVM backend + lld instead.
ZIG_NEEDS_LLVM=1
inherit zig

DESCRIPTION="Non-monolithic Wayland compositor with an external window manager"
HOMEPAGE="https://isaacfreund.com/software/river/ https://codeberg.org/river/river"
SRC_URI="
	https://codeberg.org/river/river/releases/download/v${PV}/${P}.tar.gz
	${ZBS_DEPENDENCIES_SRC_URI}
"

# river itself is GPL-3 only; bundled Zig binding packages are MIT.
LICENSE="GPL-3 MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+man xwayland"

DEPEND="
	dev-libs/libevdev
	dev-libs/libinput:=
	dev-libs/wayland
	gui-libs/wlroots:0.20
	x11-libs/libxkbcommon
	x11-libs/pixman
	xwayland? ( gui-libs/wlroots:0.20[X] )
"
RDEPEND="
	${DEPEND}
	xwayland? ( x11-base/xwayland )
"
BDEPEND="
	dev-libs/wayland-protocols
	dev-util/wayland-scanner
	man? ( app-text/scdoc )
"

DOCS=( README.md )

src_prepare() {
	# Upstream pipes "doc/<page>.1.scd" relative to the cwd, but zig.eclass
	# builds out-of-tree; use the absolute path already passed as $0.
	sed -i 's|"scdoc < doc/" ++ page ++ ".1.scd"|"scdoc < \\"$0\\""|' build.zig || die
	grep -q 'scdoc < \\"$0\\"' build.zig || die "scdoc path fix did not apply"

	zig_src_prepare
}

src_configure() {
	local my_zbs_args=(
		-Dpie=true
		-Dllvm=true
		-Dstrip=false
		-Dman-pages=$(usex man true false)
		-Dxwayland=$(usex xwayland true false)
	)

	zig_src_configure
}
