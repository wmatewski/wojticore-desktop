Name:           glass-topbar
Version:        0.1.0~alpha.1
Release:        1%{?dist}
Summary:        Top panel for Glass Desktop
License:        MIT
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch
Requires:       glass-ui = %{version}-%{release}

%description
Quickshell top bar with workspaces and date/time.

%prep
%setup -q

%build

%install
install -d %{buildroot}/usr/share/wojticore-glass/qml/GlassTopbar
install -m 0644 files/* %{buildroot}/usr/share/wojticore-glass/qml/GlassTopbar/

%files
/usr/share/wojticore-glass/qml/GlassTopbar
