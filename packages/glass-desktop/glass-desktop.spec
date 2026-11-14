Name:           glass-desktop
Version:        0.1.0~alpha.1
Release:        1%{?dist}
Summary:        Wojticore Glass Desktop meta package
License:        MIT
BuildArch:      noarch
Requires:       glass-shell = %{version}-%{release}
Requires:       glass-ui = %{version}-%{release}
Requires:       glass-dock = %{version}-%{release}
Requires:       glass-topbar = %{version}-%{release}
Requires:       glass-launcher = %{version}-%{release}
Requires:       glass-hyprland-config = %{version}-%{release}

%description
Installs the modular Wojticore Glass Desktop session.

%prep

%build

%install
mkdir -p %{buildroot}/usr/share/doc/glass-desktop
printf 'Wojticore Glass Desktop 0.1.0 Alpha\n' > %{buildroot}/usr/share/doc/glass-desktop/README

%files
/usr/share/doc/glass-desktop/README
