# Empacotamento no Linux

O `flutter_launcher_icons` não suporta Linux, então o ícone é entregue de duas
formas:

1. **Janela do app** — `linux/runner/my_application.cc` chama
   `my_application_set_window_icon()`, que carrega
   `data/flutter_assets/assets/icon/app_icon.png` a partir do diretório do
   executável. Funciona tanto em `flutter run -d linux` quanto no bundle de
   release, sem precisar instalar nada.
2. **Menu de aplicativos / dock** — os arquivos deste diretório seguem o padrão
   freedesktop e são usados na instalação:

   ```
   br.dev.minello.fake_generator.desktop
   icons/hicolor/<tamanho>x<tamanho>/apps/br.dev.minello.fake_generator.png
   ```

   Os PNGs são gerados por `python tool/generate_icon.py` (tamanhos 16 a 512).

## Instalando o bundle

Depois de `flutter build linux --release`, o bundle fica em
`build/linux/x64/release/bundle/`. Para instalar no diretório do usuário:

```bash
BUNDLE=build/linux/x64/release/bundle

# Binário + libs + assets.
mkdir -p ~/.local/opt/fake_generator
cp -r "$BUNDLE"/* ~/.local/opt/fake_generator/
mkdir -p ~/.local/bin
ln -sf ~/.local/opt/fake_generator/fake_generator ~/.local/bin/fake_generator

# Ícones do tema hicolor.
cp -r linux/packaging/icons/hicolor ~/.local/share/icons/

# Entrada do menu.
mkdir -p ~/.local/share/applications
cp linux/packaging/br.dev.minello.fake_generator.desktop ~/.local/share/applications/

update-desktop-database ~/.local/share/applications 2>/dev/null || true
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor 2>/dev/null || true
```

Para instalação global, troque `~/.local` por `/usr/local` (ou `/usr`) e rode os
comandos com `sudo`. Se você mudar o `APPLICATION_ID` em `linux/CMakeLists.txt`,
atualize também `LINUX_APP_ID` em `tool/generate_icon.py`, o nome dos PNGs e os
campos `Icon=`/`StartupWMClass=` do `.desktop`.
