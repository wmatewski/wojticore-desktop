Name:           glass-dock
Version:        0.1.0~alpha.1
Release:        1%{?dist}
Summary:        Floating application dock for Glass Desktop
License:        MIT
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch
Requires:       glass-ui = %{version}-%{release}

%description
Floating Quickshell dock with launch shortcuts for common desktop entries.

%prep
%setup -q

%build

%install
install -d %{buildroot}/usr/share/wojticore-glass/qml/GlassDock
install -m 0644 files/* %{buildroot}/usr/share/wojticore-glass/qml/GlassDock/

%files
/usr/share/wojticore-glass/qml/GlassDock
