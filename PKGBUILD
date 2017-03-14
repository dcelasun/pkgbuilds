# Maintainer: Carl George < arch at cgtx dot us >

pkgname="mkdocs"
pkgver="0.16.2"
pkgrel="1"
pkgdesc="Project documentation with Markdown."
arch=("any")
url="http://www.mkdocs.org"
license=("BSD")
makedepends=("python-setuptools")
source=("https://files.pythonhosted.org/packages/source/${pkgname:0:1}/${pkgname}/${pkgname}-${pkgver}.tar.gz"
        "${pkgname}.bash_completion")
sha256sums=('0b9531be052cc36e1973c3f87f39f85c5bf24d356211db2bbd068255466ec621'
            '66edd841378428e23fd617ff046fd8ea50b5cc5b70f3f3d50ac29bd5d33fd11f')

build() {
    cd "${srcdir}/${pkgname}-${pkgver}"
    python setup.py build
}

package() {
    depends=(
        "python-click>=3.3"
        "python-jinja>=2.7.1"
        "python-livereload>=2.5.1"
        "python-markdown>=2.3.1"
        "python-yaml>=3.10"
        "python-tornado>=4.1"
    )
    cd "${srcdir}/${pkgname}-${pkgver}"
    python setup.py install --skip-build --root="${pkgdir}" --optimize=1
    install -Dm644 "LICENSE" "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
    install -Dm644 "${srcdir}/${pkgname}.bash_completion" "${pkgdir}/usr/share/bash-completion/completions/${pkgname}"
}
