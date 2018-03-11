pkgname=pgdms
pkgver=0.0.1
pkgrel=1
pkgdesc="Document management system"
arch=('x86_64')
license=('GPL')
depends=('postgresql')
options=('!makeflags')
source=()

package() {
  cd "$startdir"
  make DESTDIR="${pkgdir}" install
}