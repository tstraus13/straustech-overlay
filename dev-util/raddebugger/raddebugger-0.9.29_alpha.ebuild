# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="RAD: native, user-mode, multi-process, graphical debugger and fast linker (Epic Games)"
HOMEPAGE="https://github.com/EpicGames/raddebugger"

SRC_URI="https://github.com/EpicGames/raddebugger/archive/refs/tags/v0.9.29-alpha.tar.gz -> ${P}.tar.gz"

# GitHub auto-tarball extracts to <repo>-<tag>: leading v stripped, hyphens kept.
S="${WORKDIR}/raddebugger-0.9.29-alpha"

LICENSE="MIT"
SLOT="0"
# Vendored x86-64 BLAKE3 assembly restricts this to amd64.
KEYWORDS="~amd64"

IUSE=""

RDEPEND="
    media-libs/freetype:=
    x11-libs/libX11
    x11-libs/libXext
    x11-libs/libXfixes
    # libglvnd ships gl.pc and egl.pc, which build.sh queries via pkg-config.
    media-libs/libglvnd
"
DEPEND="${RDEPEND}"
BDEPEND="
    dev-vcs/git
    virtual/pkgconfig
"

src_prepare() {
    default
    # build.sh calls `git describe --always` / `git rev-parse HEAD` under `set -eu`.
    # The unpacked tree has no .git, so stand up a throwaway repo with one empty
    # commit; the resulting hash is only baked into the binary as a build id.
    git -C "${S}" init -q || die
    git -C "${S}" -c user.email=gentoo@localhost -c user.name=Gentoo \
        commit -q --allow-empty -m "${P}" || die
}

src_compile() {
    # build.sh's `gcc` argument selects the $CC toolchain; force the system compiler.
    CC="$(tc-getCC)" AR="$(tc-getAR)" \
        ./build.sh release gcc raddbg radlink radbin
}

src_install() {
    dobin build/raddbg build/radlink build/radbin
    dodoc README.md CHANGELOG.md
}
