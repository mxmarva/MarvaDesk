# MarvaDesk – Auditoría y plan de implementación

Este documento contiene la **Fase 1 (Auditoría)** y la **Fase 2 (Plan de implementación)** del proyecto MarvaDesk, fork independiente de RustDesk para Soluciones Marva. No se ha modificado código aún; la implementación se ejecutará en la Fase 3 tras validar este plan.

---

## FASE 1 – AUDITORÍA

### 1.1 Estructura del repositorio

| Ruta | Contenido |
|------|-----------|
| **`src/`** | Código Rust principal: `main.rs`, `lib.rs`, `client.rs`, `server/`, `rendezvous_mediator.rs`, `flutter_ffi.rs`, `ui_interface.rs`, UI legacy (Sciter) en `ui/`, `lang/`, `platform/`, etc. |
| **`flutter/`** | App Flutter: `lib/` (desktop, mobile, common, models), `pubspec.yaml`, `android/`, `ios/`, `windows/`, `linux/`, `macos/`. |
| **`libs/`** | Bibliotecas Rust: `scrap/`, `enigo/`, `clipboard/`, **`hbb_common/`** (submódulo), `virtual_display/`, `remote_printer/`, etc. |
| **`res/`** | Recursos: iconos, `rustdesk.desktop`, `rustdesk-link.desktop`, MSI (WiX), spec RPM, PKGBUILD, scripts, DEBIAN, pam.d. |
| **`.github/`** | Workflows CI (flutter-build, flutter-ci, fdroid, winget, etc.). |

**Submódulos (`.gitmodules`):**

- **`libs/hbb_common`** → `https://github.com/mxmarva/hbb_common`

El submódulo apunta ya a tu repositorio (mxmarva/hbb_common), no al upstream. En el workspace actual `libs/hbb_common` puede estar vacío hasta ejecutar `git submodule update --init --recursive`. **Todo el comportamiento de servidores por defecto, APP_NAME, is_incoming_only, is_outgoing_only y opciones builtin (hide-server-settings) se define en `libs/hbb_common`** (p. ej. en `config.rs`). Sin inicializar ese submódulo no se puede compilar ni auditar los valores por defecto de red.

---

### 1.2 Branding y recursos gráficos

| Ubicación | Uso |
|-----------|-----|
| **`res/icon.png`** | Referenciado en `flutter/pubspec.yaml` para `flutter_launcher_icons` (Android, iOS, Windows, Linux, web). |
| **`res/mac-icon.png`** | Icono macOS en `pubspec.yaml`. |
| **`res/gen_icon.sh`** | Genera tamaños (app_icon_$size.png). |
| **`Cargo.toml`** `[package.metadata.bundle]` | `icon = ["res/32x32.png", "res/128x128.png", "res/128x128@2x.png"]` (macOS/Rust). |
| **`res/msi/`** | `Package.wxs`, `preprocess.py`, `Package.wixproj`: `icon.ico` para instalador Windows. |
| **`flutter/android/`** | `ic_launcher.xml`, `ic_launcher_round.xml`, `ic_launcher_background.xml`, `launch_background.xml`, `styles.xml`. |
| **`flutter/ios/`** | `LaunchScreen.storyboard`, Info.plist (`UILaunchStoryboardName`). |
| **`src/tray.rs`** | `include_bytes!("../res/mac-tray-dark-x2.png")` (tray). |
| **`flutter/lib/common.dart`** | `Image.asset('assets/icon.png', ...)`. |
| **Linux** | `res/rustdesk.desktop` → `Icon=rustdesk`; iconos hicolor como `rustdesk.png` (32x32, 64x64, 128x128). |

**README.md** referencia `res/logo-header.svg`; en el árbol actual no aparece ese archivo. Para MarvaDesk conviene añadir `res/logo-header.svg` o equivalente con el logo de MarvaDesk y actualizar el README.

---

### 1.3 Nombre de la aplicación

El nombre visible se controla así:

| Plataforma | Archivo / lugar | Valor actual |
|------------|-----------------|--------------|
| **Rust (central)** | `src/common.rs` → `get_app_name()` = `hbb_common::config::APP_NAME.read()`. También `is_rustdesk()` compara con `"RustDesk"`. |
| **Rust (override)** | `src/common.rs` | Config JSON de cliente personalizado puede setear `app-name` en runtime. |
| **Windows** | `Cargo.toml` `[package.metadata.winres]`: `ProductName`, `FileDescription`, `OriginalFilename` = "RustDesk". |
| **Windows Flutter** | `flutter/windows/runner/main.cpp` | Por defecto "RustDesk"; se sobrescribe con `get_rustdesk_app_name()` desde `librustdesk.dll`. |
| **Android** | `AndroidManifest.xml`, `strings.xml` | "RustDesk". |
| **iOS** | `Info.plist`, `AppInfo.xcconfig` | RustDesk, com.carriez.flutterHbb. |
| **Linux** | `res/rustdesk.desktop`, `flutter/linux/my_application.cc` | Name=RustDesk, icon rustdesk. |
| **MSI** | `res/msi/preprocess.py` | --app-name "RustDesk". |

Para **MarvaDesk Cliente** y **MarvaDesk Agente** el valor canónico debe venir de `hbb_common::config::APP_NAME` y reflejarse en todos los puntos anteriores.

---

### 1.4 Servidores por defecto y configuración de red

- **Definición**: En **`libs/hbb_common`**. Ahí se definen `RENDEZVOUS_SERVERS`, `RS_PUB_KEY`, relay, API server, etc.
- **UI**: "ID/Relay Server" se oculta si `bind.mainGetBuildinOption(key: kOptionHideServerSetting) == 'Y'` (opción builtin definida en hbb_common).
- **Datos fijos deseados**: Servidor IDs/Relay: `marvadesk.solucionesmarva.com`, API: `https://marvadesk.solucionesmarva.com`, Key: `4vmqFkjjkIAJudQtOnw4Yw2ErhCVlkrlShucTkdFWt4=` — configurar en `libs/hbb_common`.

---

### 1.5 Package names / Bundle IDs

- **Android**: `com.carriez.flutter_hbb` → objetivo `com.solucionesmarva.desk`.
- **iOS/macOS**: `com.carriez.flutterHbb` → `com.solucionesmarva.desk`.
- **Linux**: `APPLICATION_ID`, `BINARY_NAME` en `flutter/linux/CMakeLists.txt`.
- **Flatpak**: `com.rustdesk.RustDesk` → nuevo id para MarvaDesk si aplica.

---

### 1.6 Variantes Cliente vs Agente

- **Incoming only** ya existe: `config::is_incoming_only()` en Rust; en `client.rs` impide conexión saliente; en Flutter oculta panel "conectar a otro".
- **Outgoing only** ya existe para el caso contrario.
- No hay product flavors en Android ni schemes en iOS; las variantes se resuelven con configuración en **hbb_common** (dos builds con distinta config o env).

---

### 1.7 Licencia

- **LICENCE**: AGPL-3.0. No eliminar. Mantener copyright de Purslane Ltd. y atribuciones obligatorias.

---

## FASE 2 – PLAN DE IMPLEMENTACIÓN

### 2.1 Estrategia

- **libs/hbb_common** (tu fork mxmarva/hbb_common): Definir servidores fijos, Key, `hide-server-settings=Y`, y para Cliente `APP_NAME="MarvaDesk Cliente"` + `is_incoming_only=true`; para Agente `APP_NAME="MarvaDesk Agente"` + `is_incoming_only=false`.
- **Repo principal**: Reemplazar branding a MarvaDesk; cambiar IDs a `com.solucionesmarva.desk`; no borrar licencia ni atribuciones.

### 2.2 Archivos a editar (lista resumida)

- **Cargo.toml**: winres, bundle (nombre, identifier).
- **build.py**: hbb_name y referencias a nombre de app.
- **flutter/windows/runner/main.cpp**, **flutter/linux/my_application.cc**, **flutter/linux/CMakeLists.txt**.
- **flutter/android**: build.gradle, AndroidManifest.xml, strings.xml.
- **flutter/ios**: Info.plist, project.pbxproj.
- **flutter/macos**: AppInfo.xcconfig.
- **res/rustdesk.desktop**, **res/rustdesk-link.desktop**, **res/msi/preprocess.py** y Package.
- **flatpak**: metainfo si se publica MarvaDesk por separado.
- **README.md**: actualizado para MarvaDesk / Soluciones Marva.

### 2.3 Riesgos

- Submódulo vacío: inicializar y configurar en mxmarva/hbb_common.
- Cambio de applicationId/bundle id: nueva firma y provisioning en Android/iOS.
- Scripts CI: actualizar nombres y rutas a MarvaDesk.

### 2.4 Tareas manuales posteriores

- Keystore Android y provisioning iOS para `com.solucionesmarva.desk`.
- Sustitución de iconos y logos por assets de MarvaDesk.
- Firma de código y publicación en tiendas si aplica.

### 2.5 Checklist de validación

**Cliente**: Nombre "MarvaDesk Cliente"; solo recibir conexiones; no editar servidores; servidores fijos.  
**Agente**: Nombre "MarvaDesk Agente"; conexiones entrantes y salientes; no editar servidores; servidores fijos.  
**General**: Licencia y copyright preservados; builds correctos; sin referencias operativas al upstream.

---

*Documento generado para el proyecto MarvaDesk (Soluciones Marva).*
