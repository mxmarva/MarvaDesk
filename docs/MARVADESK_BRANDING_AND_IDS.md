# MarvaDesk – Branding visible e identificadores de paquete

Este documento resume los cambios de **fase de branding**: nombres visibles, package/bundle ids, manifests, desktop entries y metadatos, **sin cambiar** el nombre interno del binario (`rustdesk` / `librustdesk`).

---

## 1. Resumen por bloques

### 1.1 Android

| Elemento | Valor / cambio |
|----------|----------------|
| **applicationId** | `com.solucionesmarva.desk` (en `flutter/android/app/build.gradle`) |
| **Package Kotlin** | Se mantiene `com.carriez.flutter_hbb` (no se mueve código; el `applicationId` es independiente). |
| **App name** | Por **product flavors**: `agente` → "MarvaDesk Agente", `cliente` → "MarvaDesk Cliente" (`resValue "string", "app_name", "..."`). |
| **strings.xml** | `app_name` por defecto "MarvaDesk"; descripción del servicio de accesibilidad actualizada a MarvaDesk. |
| **Manifest** | `android:label="@string/app_name"`, servicio Input con `android:label="MarvaDesk Input"`, intent `com.solucionesmarva.desk.DEBUG_BOOT_COMPLETED`, scheme de deep link `marvadesk`. |
| **BootReceiver** | Constante `DEBUG_BOOT_COMPLETED = "com.solucionesmarva.desk.DEBUG_BOOT_COMPLETED"`; Toast "MarvaDesk is Open". |
| **Launcher / assets** | Sin cambios de rutas; iconos siguen en `@mipmap/ic_launcher` (no se han tocado nombres de recursos). |

**Build Android:** hay que compilar con **flavor** para que el nombre sea "MarvaDesk Cliente" o "MarvaDesk Agente":

- Cliente: `cd flutter && flutter build apk --flavor cliente --release` (tras haber generado las libs con `MARVADESK_VARIANT=cliente` y los scripts ndk).
- Agente: `flutter build apk --flavor agente --release`.

Si no se especifica flavor, Gradle usa el primero por orden alfabético (`agente`).

---

### 1.2 iOS

| Elemento | Valor / cambio |
|----------|----------------|
| **Bundle identifier** | `com.solucionesmarva.desk` (en `Runner.xcodeproj/project.pbxproj` y `macos/Runner/Configs/AppInfo.xcconfig`). |
| **Display name** | "MarvaDesk" en `Info.plist` (CFBundleDisplayName, CFBundleName). En la pantalla de inicio se ve "MarvaDesk"; el título completo "MarvaDesk Cliente" / "MarvaDesk Agente" lo aporta el core en tiempo de ejecución. |
| **URL scheme** | `marvadesk`; CFBundleURLName `com.solucionesmarva.desk`. |
| **macOS** | Mismo bundle id y AppInfo.xcconfig; Info.plist con scheme `marvadesk`. |

**Pendiente manual (firma / provisioning):** al cambiar el bundle id a `com.solucionesmarva.desk`, hay que:

- En **Apple Developer**: crear un App ID `com.solucionesmarva.desk` y los provisioning profiles que usen ese ID.
- En Xcode: seleccionar el equipo y el perfil de provisioning correspondiente para el target Runner (iOS y macOS si aplica).
- Sin esto, el build fallará en firma o al instalar en dispositivo.

---

### 1.3 Desktop

| Elemento | Valor / cambio |
|----------|----------------|
| **Cargo.toml** | `[package.metadata.winres]`: ProductName "MarvaDesk", FileDescription "MarvaDesk Remote Desktop", LegalCopyright "Soluciones Marva". `[package.metadata.bundle]`: name "MarvaDesk", identifier "com.solucionesmarva.desk". |
| **Linux .desktop** | `res/rustdesk.desktop`: Name=MarvaDesk. Exec/Icon/StartupWMClass siguen usando `rustdesk` (binario e icono sin cambiar). |
| **Linux .desktop link** | `res/rustdesk-link.desktop`: Name=MarvaDesk, MimeType `x-scheme-handler/marvadesk`. |
| **Linux systemd** | `res/rustdesk.service`: Description=MarvaDesk. Exec sigue siendo `/usr/bin/rustdesk`. |
| **Linux ventanas** | `flutter/linux/my_application.cc`: título de ventana y header bar "MarvaDesk". Icono sigue cargando desde tema "rustdesk". |
| **Windows** | `flutter/windows/runner/main.cpp`: ya usa `get_rustdesk_app_name()` para el título de ventana (MarvaDesk Cliente/Agente según variante). `Runner.rc`: CompanyName, FileDescription, LegalCopyright, ProductName a MarvaDesk; InternalName y OriginalFilename se mantienen "rustdesk" / "rustdesk.exe". |
| **MSI / instalador** | `res/msi/preprocess.py`: `--app-name` por defecto "MarvaDesk". Los nombres visibles del instalador salen de ese valor (sustitución de "RustDesk" por app-name). |

No se han cambiado: nombre del ejecutable (`rustdesk`), rutas de scripts que invocan `rustdesk` (deb/rpm/pacman, systemd), ni licencias/atribuciones obligatorias.

---

## 2. Auto-actualización desactivada para MarvaDesk

Para que la app **no** intente actualizarse desde el GitHub oficial de RustDesk (y así no pise la build con la versión estándar):

- En **`src/common.rs`**, al inicio de `do_check_software_update()` se comprueba `is_rustdesk()`. Si es falso (MarvaDesk Cliente / MarvaDesk Agente), se deja `SOFTWARE_UPDATE_URL` vacío y se retorna sin hacer la petición a `api.rustdesk.com`.

Así, en builds con variante MarvaDesk no se rellena la URL de actualización y no se ofrece actualizar desde RustDesk.

---

## 3. Variante obligatoria en build con Flutter

En **`build.py`**, cuando se usa `--flutter`, es **obligatorio** indicar una de las dos variantes:

- Si no se pasa ni `--marvadesk-cliente` ni `--marvadesk-agente`, el script sale con error y muestra un mensaje indicando que debe usarse uno de los dos flags.

Ejemplo correcto: `python3 build.py --flutter --marvadesk-cliente`.

---

## 4. Archivos modificados (lista)

| Archivo | Cambios |
|---------|---------|
| **build.py** | Comprobación al inicio de `main()`: si `--flutter` y no hay `--marvadesk-cliente` ni `--marvadesk-agente`, error y exit. |
| **src/common.rs** | Al inicio de `do_check_software_update()`, si `!is_rustdesk()` se pone `SOFTWARE_UPDATE_URL` vacío y se retorna. |
| **flutter/android/app/build.gradle** | applicationId `com.solucionesmarva.desk`; product flavors `agente` y `cliente` con `resValue` para `app_name`. |
| **flutter/android/app/src/main/AndroidManifest.xml** | label `@string/app_name`, DEBUG_BOOT_COMPLETED `com.solucionesmarva.desk.DEBUG_BOOT_COMPLETED`, servicio Input "MarvaDesk Input", scheme `marvadesk`. |
| **flutter/android/app/src/main/res/values/strings.xml** | app_name "MarvaDesk", descripción accesibilidad MarvaDesk. |
| **flutter/android/.../BootReceiver.kt** | Constante DEBUG_BOOT_COMPLETED y Toast "MarvaDesk is Open". |
| **flutter/ios/Runner/Info.plist** | CFBundleDisplayName y CFBundleName "MarvaDesk"; URL scheme `marvadesk`, CFBundleURLName `com.solucionesmarva.desk`. |
| **flutter/ios/Runner.xcodeproj/project.pbxproj** | PRODUCT_BUNDLE_IDENTIFIER = com.solucionesmarva.desk. |
| **flutter/macos/Runner/Configs/AppInfo.xcconfig** | PRODUCT_NAME MarvaDesk, PRODUCT_BUNDLE_IDENTIFIER com.solucionesmarva.desk, copyright Soluciones Marva. |
| **flutter/macos/Runner/Info.plist** | URL scheme `marvadesk`, CFBundleURLName `com.solucionesmarva.desk`. |
| **flutter/macos/Runner.xcodeproj/project.pbxproj** | PRODUCT_BUNDLE_IDENTIFIER = com.solucionesmarva.desk. |
| **Cargo.toml** | package.metadata.winres y package.metadata.bundle con nombres y copyright Soluciones Marva. |
| **res/rustdesk.desktop** | Name=MarvaDesk. |
| **res/rustdesk-link.desktop** | Name=MarvaDesk, MimeType x-scheme-handler/marvadesk. |
| **res/rustdesk.service** | Description=MarvaDesk. |
| **res/msi/preprocess.py** | default app-name "MarvaDesk". |
| **flutter/linux/my_application.cc** | Comentario y títulos de ventana "MarvaDesk". |
| **flutter/windows/runner/Runner.rc** | CompanyName, FileDescription, LegalCopyright, ProductName a MarvaDesk. |

---

## 5. Riesgos y consideraciones

| Área | Riesgo | Nota |
|------|--------|------|
| **Android** | Cambio de applicationId exige **nueva firma** y, en Play Store, se considera otra app (no actualización in-place de la antigua). | Configurar signing con keystore de Soluciones Marva y usar el mismo applicationId en todos los builds de MarvaDesk. |
| **iOS** | Nuevo bundle id exige **nuevo App ID y provisioning** en Apple Developer. | Crear App ID `com.solucionesmarva.desk` y perfiles de provisioning; en Xcode asignar equipo y perfil al target Runner. |
| **Android flavors** | Si se ejecuta `flutter build apk` sin `--flavor`, se usa el primer flavor (agente). | Documentar que para Cliente hay que usar `--flavor cliente`. |
| **Deep links** | Scheme cambiado a `marvadesk`. Enlaces antiguos `rustdesk://` no abrirán esta app. | Esperado; enlaces propios deben usar `marvadesk://`. |
| **Dart / UI** | Varios enlaces y textos siguen apuntando a rustdesk.com (descargas, privacidad, etc.). | No eliminados; se pueden sustituir en una fase posterior por URLs de Soluciones Marva si se desea. |

---

## 6. Pendientes manuales (firma / provisioning)

- **Android:** Configurar en el proyecto (o en CI) el keystore y la configuración de firma para `com.solucionesmarva.desk` (release y, si aplica, debug).
- **iOS / macOS:** En Apple Developer, crear App ID `com.solucionesmarva.desk`, provisioning profiles (desarrollo y distribución) y en Xcode asignar el equipo y el perfil al target Runner.

---

## 7. Cómo probar Cliente y Agente

### Desktop (Windows / Linux / macOS)

- Cliente: `python3 build.py --flutter --marvadesk-cliente` (y opciones que uses: hwcodec, vram, etc.). Ejecutar el binario generado; el título de ventana y el nombre en la barra de tareas deben mostrar "MarvaDesk Cliente".
- Agente: `python3 build.py --flutter --marvadesk-agente`. Idem con "MarvaDesk Agente".

### Android

- Generar libs con la variante deseada, por ejemplo: `MARVADESK_VARIANT=cliente bash flutter/ndk_arm64.sh` (y el resto de ABIs si hace falta). **Recomendado:** usar `bash flutter/build_android_marvadesk.sh cliente` (o `agente`) para que flavor y feature Rust coincidan.
- Build: `cd flutter && flutter build apk --flavor cliente --release` (o `--flavor agente`).
- Instalar el APK; el nombre bajo el icono debe ser "MarvaDesk Cliente" o "MarvaDesk Agente" según el flavor. Comprobar que el servicio y el ID mostrado usen los servidores MarvaDesk (config de hbb_common).

### iOS

- Generar lib con variante: `MARVADESK_VARIANT=cliente bash flutter/ios_arm64.sh` (y ios_x64.sh si se usa simulador). **Recomendado:** usar `bash flutter/build_ios_marvadesk.sh cliente` (o `agente`) para acoplar variante Rust.
- En Xcode, configurar firma con el perfil para `com.solucionesmarva.desk`.
- `cd flutter && flutter build ios` (o abrir el proyecto en Xcode y run). En el dispositivo/simulador el nombre bajo el icono es "MarvaDesk"; dentro de la app el título será "MarvaDesk Cliente" o "MarvaDesk Agente" según la variante compilada.

Comprobar en todas las variantes que **no** aparezca aviso de actualización desde RustDesk (por la desactivación en `do_check_software_update()`).

Para auditoría de consistencia, validación funcional y checklist de release, ver **docs/MARVADESK_VALIDATION_AND_RELEASE.md**.
