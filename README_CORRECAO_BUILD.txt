Correção feita:
- Adicionado o arquivo que estava faltando no Assets.xcassets/ProxyMoney.imageset/proxy.png.
- Corrigido Contents.json do ProxyMoney.imageset e MoneyDrop.imageset com scale 1x.
- Mantido CFBundleExecutable no Info.plist para GBox/ESign.
- Mantido workflow para gerar IPA unsigned no GitHub Actions.

Esse erro derrubava o xcodebuild com exit code 65 no GitHub Actions.
