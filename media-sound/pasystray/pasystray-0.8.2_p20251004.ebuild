# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools xdg

# Upstream master snapshot: 0.8.2 predates Ayatana AppIndicator support,
# and its GtkStatusIcon (X11 tray) backend crashes under Wayland. With
# Ayatana it shows up in StatusNotifierItem trays such as waybar's.
COMMIT="5a199dc6958bcaac07a8031eb48b9fad8730bf71"

DESCRIPTION="PulseAudio system tray"
HOMEPAGE="https://github.com/christophgysin/pasystray"
SRC_URI="https://github.com/christophgysin/${PN}/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${COMMIT}"

LICENSE="LGPL-2.1+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+appindicator libnotify zeroconf"

RDEPEND="
	dev-libs/glib
	|| (
		media-libs/libpulse[glib]
		media-sound/pulseaudio-daemon[glib,zeroconf?]
	)
	x11-libs/gtk+:3
	x11-libs/libX11
	appindicator? ( dev-libs/libayatana-appindicator )
	libnotify? ( x11-libs/libnotify )
	zeroconf? ( net-dns/avahi )
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

src_prepare() {
	default

	# configure.ac checks HAVE_APPINDICATOR instead of
	# HAVE_AYATANA_APPINDICATOR when --enable-ayatana-appindicator is given.
	sed -i 's/test "x$enable_ayatana_appindicator" = xyes \&\& test "x$HAVE_APPINDICATOR" = x0/test "x$enable_ayatana_appindicator" = xyes \&\& test "x$HAVE_AYATANA_APPINDICATOR" = x0/' \
		configure.ac || die
	grep -q 'xyes && test "x$HAVE_AYATANA_APPINDICATOR" = x0' configure.ac \
		|| die "ayatana configure fix did not apply"

	eautoreconf
}

src_configure() {
	# Never pick up Ubuntu's legacy libappindicator automagically.
	econf \
		--disable-appindicator \
		$(use_enable appindicator ayatana-appindicator) \
		$(use_enable libnotify notify) \
		$(use_enable zeroconf avahi)
}
