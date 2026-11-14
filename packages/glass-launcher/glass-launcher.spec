Name:           glass-launcher
Version:        0.1.0~alpha.1
Release:        1%{?dist}
Summary:        Application launcher for Glass Desktop
License:        MIT
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch
Requires:       glass-ui = %{version}-%{release}

%description
Keyboard-first launcher that searches installed XDG desktop entries.

%prep
%setup -q

%build

%install
install -d %{buildroot}/usr/share/wojticore-glass/qml/GlassLauncher
install -m 0644 files/* %{buildroot}/usr/share/wojticore-glass/qml/GlassLauncher/

%files
/usr/share/wojticore-glass/qml/GlassLauncher
