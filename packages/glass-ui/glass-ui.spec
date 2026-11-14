Name:           glass-ui
Version:        0.1.0~alpha.1
Release:        1%{?dist}
Summary:        Shared QML components and design tokens for Glass Desktop
License:        MIT
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

%description
Shared Liquid Glass colors, typography, cards and buttons for QML applications.

%prep
%setup -q

%build

%install
install -d %{buildroot}/usr/share/wojticore-glass/qml/GlassUI
install -m 0644 files/* %{buildroot}/usr/share/wojticore-glass/qml/GlassUI/

%files
/usr/share/wojticore-glass/qml/GlassUI
