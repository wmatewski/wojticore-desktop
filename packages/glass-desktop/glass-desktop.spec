Name:           glass-desktop
Version:        0.1.0~alpha.1
Release:        1%{?dist}
Summary:        Wojticore Glass Desktop meta package
License:        MIT
BuildArch:      noarch
Requires:       glass-shell
Requires:       glass-ui
Requires:       glass-dock
Requires:       glass-topbar
Requires:       glass-launcher
Requires:       glass-hyprland-config

%description
Installs the modular Wojticore Glass Desktop session.

%prep

%build

%install
mkdir -p %{buildroot}/usr/share/doc/glass-desktop
printf 'Wojticore Glass Desktop 0.1.0 Alpha\n' > %{buildroot}/usr/share/doc/glass-desktop/README

%files
/usr/share/doc/glass-desktop/README
