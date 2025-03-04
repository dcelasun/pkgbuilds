# Maintainer: D. Can Celasun <can[at]dcc[dot]im>

pkgname=visual-studio-code-insiders-bin
_pkgname=visual-studio-code-insiders
pkgver=1740987991
pkgrel=1
pkgdesc="Editor for building and debugging modern web and cloud applications (insiders version)"
arch=('x86_64' 'aarch64' 'armv7h')
url="https://code.visualstudio.com/"
license=('custom: commercial')
# lsof: need for terminal splitting, see https://github.com/Microsoft/vscode/issues/62991
depends=(libxkbfile gnupg gtk3 libsecret nss gcc-libs libnotify libxss glibc lsof)
optdepends=('glib2: Needed for move to trash functionality'
            'libdbusmenu-glib: Needed for KDE global menu')
provides=(vscode)
options=(!strip)

pkgver() {
    if [ "${CARCH}" = "x86_64" ]; then
        IFS='/' read -ra ADDR <<< $(curl -ILs -o /dev/null -w %{url_effective} https://update.code.visualstudio.com/latest/linux-x64/insider); echo "${ADDR[7]}" | sed 's/code-insider-x64-//g' | sed 's/.tar.gz//g' | sed 's/-/./g'
    elif [ "${CARCH}" = "aarch64" ]; then
        IFS='/' read -ra ADDR <<< $(curl -ILs -o /dev/null -w %{url_effective} https://update.code.visualstudio.com/latest/linux-arm64/insider); echo "${ADDR[7]}" | sed 's/code-insider-arm64-//g' | sed 's/.tar.gz//g' | sed 's/-/./g'
    elif [ "${CARCH}" = "armv7h" ]; then
        IFS='/' read -ra ADDR <<< $(curl -ILs -o /dev/null -w %{url_effective} https://update.code.visualstudio.com/latest/linux-armhf/insider); echo "${ADDR[7]}" | sed 's/code-insider-armhf-//g' | sed 's/.tar.gz//g' | sed 's/-/./g'
    fi
}
source=(${_pkgname}.desktop ${_pkgname}-url-handler.desktop ${_pkgname}-bin.sh)
source_x86_64=(code_x64_${pkgver}.tar.gz::https://update.code.visualstudio.com/latest/linux-x64/insider)
source_aarch64=(code_arm64_${pkgver}.tar.gz::https://update.code.visualstudio.com/latest/linux-arm64/insider)
source_armv7h=(code_armhf_${pkgver}.tar.gz::https://update.code.visualstudio.com/latest/linux-armhf/insider)

sha256sums=('381bcf5644e7fba645537215f5d488b25fc9ee1509d19226f031071a6abb3bdd'
            'b961802b4f27ae8f871f64a1435dd93ee17fc72f78137bf6cc3f6aa1b107105d'
            '44c99cf30f0ae3ea32c6176b86265cf6c8044de4497b6b45b0c912b5ad5b004c')
sha256sums_x86_64=('c84a33869d8e5cae4f8dcb90f0cd1470834c0923717b218de6371d4a6d48bf61')
sha256sums_aarch64=('90042c51795edd6e9845cf7c06ac449acd75292818a201833ab63c5ff66bfed7')
sha256sums_armv7h=('2e2af2d8202c4a6f97c868e57360a73cf4e1fb18c4b413a118aaaeea4a21c798')
package() {
  _pkg=VSCode-linux-x64
  if [ "${CARCH}" = "aarch64" ]; then
    _pkg=VSCode-linux-arm64
  fi
  if [ "${CARCH}" = "armv7h" ]; then
    _pkg=VSCode-linux-armhf
  fi
  if [ "${CARCH}" = "i686" ]; then
    _pkg=VSCode-linux-ia32
  fi

  install -d "${pkgdir}/usr/share/"{licenses/${_pkgname},applications,pixmaps}
  install -d "${pkgdir}/opt/${_pkgname}"
  install -d "${pkgdir}/usr/bin"

  install -m644 "${srcdir}/${_pkg}/resources/app/LICENSE.rtf" "${pkgdir}/usr/share/licenses/${_pkgname}/LICENSE.rtf"
  install -m644 "${srcdir}/${_pkg}/resources/app/resources/linux/code.png" "${pkgdir}/usr/share/pixmaps/${_pkgname}.png"
  install -m644 "${srcdir}/${_pkgname}.desktop" "${pkgdir}/usr/share/applications/${_pkgname}.desktop"
  install -m644 "${srcdir}/${_pkgname}-url-handler.desktop" "${pkgdir}/usr/share/applications/${_pkgname}-url-handler.desktop"

  cp -r "${srcdir}/${_pkg}/"* "${pkgdir}/opt/${_pkgname}" -R

  # Launcher
  install -m755 "${srcdir}/${_pkgname}-bin.sh" "${pkgdir}/usr/bin/code-insiders"
}
