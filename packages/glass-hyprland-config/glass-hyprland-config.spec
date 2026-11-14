Name:           glass-hyprland-config
Version:        0.1.0~alpha.1
Release:        1%{?dist}
Summary:        Isolated Hyprland session configuration for Glass Desktop
License:        MIT
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch
Requires:       hyprland
Requires:       glass-shell = %{version}-%{release}
Recommends:     swaybg
Recommends:     kitty

%description
Adds a distinct Glass Desktop login session and per-user first-run config without modifying existing Hyprland settings.

%prep
%setup -q

%build

%install
install -d %{buildroot}/usr/bin %{buildroot}/usr/share/wayland-sessions %{buildroot}/usr/share/wojticore-glass
install -m 0755 files/glass-session %{buildroot}/usr/bin/glass-session
install -m 0644 files/glass.desktop %{buildroot}/usr/share/wayland-sessions/glass.desktop
install -m 0644 files/default-hyprland.conf %{buildroot}/usr/share/wojticore-glass/default-hyprland.conf
install -m 0644 files/glass-wallpaper.png %{buildroot}/usr/share/wojticore-glass/glass-wallpaper.png

%files
/usr/bin/glass-session
/usr/share/wayland-sessions/glass.desktop
/usr/share/wojticore-glass/default-hyprland.conf
/usr/share/wojticore-glass/glass-wallpaper.png
