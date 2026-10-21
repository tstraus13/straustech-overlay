# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Tiling Wayland compositor with a non-tile-friendly tiling window manager"
HOMEPAGE="https://codeberg.org/river/river https://isaacfreund.com/software/river"
SRC_URI="
	https://codeberg.org/river/river/releases/download/v${PV}/river-${PV}.tar.gz
	https://codeberg.org/ifreund/zig-pixman/archive/v0.3.0.tar.gz -> zig-pixman-0.3.0.tar.gz
	https://codeberg.org/ifreund/zig-wayland/archive/v0.6.0.tar.gz -> zig-wayland-0.6.0.tar.gz
	https://codeberg.org/ifreund/zig-wlroots/archive/v0.20.1.tar.gz -> zig-wlroots-0.20.1.tar.gz
	https://codeberg.org/ifreund/zig-xkbcommon/archive/v0.4.0.tar.gz -> zig-xkbcommon-0.4.0.tar.gz
"
S="${WORKDIR}/river-${PV}"

LICENSE="0BSD CC-BY-SA-4.0 GPL-3+ MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+xwayland man"

RDEPEND="
	gui-libs/wlroots:0.20
	dev-libs/libevdev
	dev-libs/libinput
	dev-libs/wayland
	x11-libs/libxkbcommon
	media-libs/pixman
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-lang/zig:0.16[llvm]
	dev-vcs/git
	virtual/pkgconfig
	man? ( app-misc/scdoc )
"

# build.zig.zon pins translate-c to a git commit; portage cannot pin a
# commit in SRC_URI, so clone it in the fetch phase instead.
TRANSLATE_C_REPO="https://codeberg.org/ziglang/translate-c.git"
TRANSLATE_C_COMMIT="57c559cf581b1fcad90494eda219f98abeb155ce"

fetch() {
	default

	git clone --quiet "${TRANSLATE_C_REPO}" "${WORKDIR}/translate-c" || die
	git -C "${WORKDIR}/translate-c" checkout --quiet "${TRANSLATE_C_COMMIT}" || die
}

# Zig's package manager refuses network access at build time, so seed its
# global cache from the sources fetched above; zig verifies each package
# against the hash in build.zig.zon.
_seed_zig_cache() {
	local zig_cache="${T}/zig-cache"
	local src
	for src in \
		"${DISTDIR}/zig-pixman-0.3.0.tar.gz" \
		"${DISTDIR}/zig-wayland-0.6.0.tar.gz" \
		"${DISTDIR}/zig-wlroots-0.20.1.tar.gz" \
		"${DISTDIR}/zig-xkbcommon-0.4.0.tar.gz" \
		"${WORKDIR}/translate-c"
	do
		zig fetch --global-cache-dir "${zig_cache}" "${src}" \
			|| die "zig fetch: ${src}"
	done
	echo "${zig_cache}/p"
}

src_compile() {
	local zig_cache
	zig_cache="$(_seed_zig_cache)"

	# -Dllvm: glibc >= 2.39 crt objects carry SFrame sections that break
	# Zig's default codegen (ziglang/zig#31272); upstream Arch CI does the
	# same. -Dcpu=baseline: portable binary, per upstream PACKAGING.md.
	local args=( --system "${zig_cache}"
		-Dcpu=baseline
		-Doptimize=ReleaseSafe
	)
	use xwayland && args+=( -Dxwayland )
	use man && args+=( -Dman-pages ) || args+=( -Dman-pages=false )

	zig build "${args[@]}" --prefix="${EPREFIX}/usr" install || die
}

src_test() {
	local zig_cache
	zig_cache="$(_seed_zig_cache)"

	zig build --system "${zig_cache}" -Dcpu=baseline -Doptimize=ReleaseSafe test || die
}
