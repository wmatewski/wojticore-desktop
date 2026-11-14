Name:           glass-shell
Version:        0.1.0~alpha.1
Release:        1%{?dist}
Summary:        Quickshell composition for Glass Desktop
License:        MIT
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch
Requires:       quickshell
Requires:       glass-ui = %{version}-%{release}
Requires:       glass-dock = %{version}-%{release}
Requires:       glass-topbar = %{version}-%{release}
Requires:       glass-launcher = %{version}-%{release}

%description
Loads the Glass top bar, dock and launcher as a Quickshell session.

%prep
%setup -q

%build

%install
install -d %{buildroot}/usr/share/wojticore-glass
install -m 0644 files/Shell.qml %{buildroot}/usr/share/wojticore-glass/Shell.qml

%files
/usr/share/wojticore-glass/Shell.qml
