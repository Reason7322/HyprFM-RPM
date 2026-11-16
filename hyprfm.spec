Name:           hyprfm
Version:        0.7.0
Release:        1%{?dist}
Summary:        Qt/QML file manager for Wayland desktops
License:        MIT
URL:            https://github.com/soyeb-jim285/hyprfm
# Bundled source generated from the exact upstream stable tag, including submodules.
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  ninja-build
BuildRequires:  pkgconfig(gio-2.0)
BuildRequires:  pkgconfig(gio-unix-2.0)
BuildRequires:  qt6-qtbase-devel
BuildRequires:  qt6-qtdeclarative-devel
BuildRequires:  qt6-qtsvg-devel
BuildRequires:  desktop-file-utils
# Zig >= 0.17 is supplied by the isolated GitHub Actions build runner.
# Fedora 45's Zig 0.16 is insufficient for the pinned libghostty-vt.
# The upstream CMake fetches Ghostty's commit and validates its SHA256.

%description
HyprFM is a Qt 6/QML file manager for Wayland desktops.
This build includes the embedded Ghostty terminal and file-picker portal.

%prep
%autosetup

%build
%cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=OFF \
    -DHYPRFM_TERMINAL=ON \
    -DHYPRFM_ENABLE_QML_CACHEGEN=ON \
    -DHYPRFM_DATA_DIR=%{_datadir}/hyprfm
%cmake_build

%install
%cmake_install

%check
desktop-file-validate %{buildroot}%{_datadir}/applications/io.github.soyeb_jim285.HyprFM.desktop

%files
%license LICENSE
%{_bindir}/hyprfm
%{_bindir}/xdg-desktop-portal-hyprfm
%{_datadir}/hyprfm/
%{_datadir}/applications/io.github.soyeb_jim285.HyprFM.desktop
%{_datadir}/icons/hicolor/scalable/apps/io.github.soyeb_jim285.HyprFM.svg
%{_datadir}/metainfo/io.github.soyeb_jim285.HyprFM.metainfo.xml
%{_datadir}/xdg-desktop-portal/portals/hyprfm.portal
%{_datadir}/dbus-1/services/org.freedesktop.impl.portal.desktop.hyprfm.service
%{_datadir}/systemd/user/xdg-desktop-portal-hyprfm.service

%changelog
* Mon Nov 16 2026 Personal HyprFM RPM Packaging - 0.7.0-1
- Initial draft for Fedora 45 with embedded Ghostty terminal
