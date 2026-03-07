## URLs visibles en la app (referencia)

Base: **https://www.solucionesmarva.com**. Rutas usadas:

| URL | Uso en la app | Archivo(s) |
|-----|----------------|------------|
| `https://www.solucionesmarva.com` | Enlace “web” / guía servidor público; enlace genérico en ajustes; ayuda Linux (genérico, no hay docs propios) | connection_page.dart (desktop), desktop_setting_page.dart, common.dart, settings_page.dart, desktop_home_page.dart (3 tarjetas de ayuda Linux) |
| `https://www.solucionesmarva.com/` | const url y texto mostrado en ajustes móvil | settings_page.dart |
| `https://www.solucionesmarva.com/aviso-de-privacidad/` | Política de privacidad (Aviso de Privacidad de Soluciones Marva) | desktop_setting_page.dart, install_page.dart, settings_page.dart |
| `https://www.solucionesmarva.com/download` | Botón “Descargar nueva versión” (página por crear) | desktop_home_page.dart, connection_page.dart (móvil) |

Las rutas `/docs/en/client/linux/...` no existen ni se crearán; los enlaces de ayuda Linux en desktop_home_page apuntan a la base `https://www.solucionesmarva.com`.

---

### 1.1 Cambios seguros (UI / texto / enlaces) – APLICADOS

| Archivo | Referencia | Cambio aplicado |
|---------|------------|------------------|
| flutter/lib/desktop/pages/connection_page.dart | URL `https://rustdesk.com/pricing` | → `https://www.solucionesmarva.com` |
| flutter/lib/desktop/pages/desktop_setting_page.dart | URLs privacy y website | → `https://www.solucionesmarva.com/aviso-de-privacidad/` y `https://www.solucionesmarva.com` |
| flutter/lib/mobile/pages/settings_page.dart | `const url`, texto "rustdesk.com", Privacy Statement URL | → `https://www.solucionesmarva.com/`, "www.solucionesmarva.com", `https://www.solucionesmarva.com/aviso-de-privacidad/` |
| flutter/lib/desktop/pages/install_page.dart | URLs privacy en tooltip/mensaje | → `https://www.solucionesmarva.com/aviso-de-privacidad/` |
| flutter/lib/common.dart | launchUrl('https://rustdesk.com') | → `https://www.solucionesmarva.com` |
| flutter/lib/desktop/pages/desktop_home_page.dart | download; ayuda Linux (3 enlaces) | → `https://www.solucionesmarva.com/download`; enlaces de ayuda Linux → `https://www.solucionesmarva.com` (genérico, no hay docs Linux) |
| flutter/lib/mobile/pages/connection_page.dart | URL botón actualización | → `https://www.solucionesmarva.com/download` |
| flutter/lib/desktop/widgets/tabbar_widget.dart | Texto fijo "RustDesk" en barra de pestañas | → `bind.mainGetAppNameSync()` (muestra "MarvaDesk Cliente" o "MarvaDesk Agente") |

Base URL usada en enlaces visibles: **https://www.solucionesmarva.com**. Listado exacto de URLs en **docs/MARVADESK_RELEASE_CLEANUP.md** (sección “URLs visibles en la app”).

---

## 1. Archivos con referencias visibles residuales (listado y clasificación)

---

### 1.2 Referencias dejadas intactas (riesgosas o internas)

| Ubicación | Referencia | Motivo para no tocar |
|-----------|------------|------------------------|
| **Rust – lógica y tests** | | |
| src/common.rs | `is_rustdesk()` compara con `"RustDesk"`, is_public(rustdesk.com), admin URL, tests | Necesario para detectar build oficial vs MarvaDesk y para tests; cambiar rompería lógica y tests. |
| src/common.rs | Comentarios api.rustdesk.com, RustDeskInterval, rutas macOS en comentarios | Solo documentación/código interno. |
| **Rust – identificadores / rutas internas** | | |
| src/platform/windows.rs | Rutas `RustDesk`, `RustDeskCustomClientStaging`, ProgramData, comentarios | Rutas de instalación y staging; cambiar podría afectar actualizaciones o instalador. |
| src/virtual_display_manager.rs | `RUSTDESK_IDD_DEVICE_STRING`, comentarios | Identificador de driver IDD; cambio podría afectar compatibilidad con driver. |
| src/server/uinput.rs | Nombre dispositivo "RustDesk UInput Keyboard" | Nombre interno de dispositivo Linux. |
| src/whiteboard/macos.rs | Título ventana "RustDesk whiteboard" | Podría cambiarse a "MarvaDesk whiteboard" en una fase posterior si se desea. |
| src/plugin/*.rs | Mensajes "RustDesk wants to install...", "contact RustDesk team" | Textos de plugin; opcional sustituir en fase posterior. |
| **Rust – traducciones** | | |
| src/lang/*.rs (be, ja, el, ge, sc, sq, tr, he, nb, etc.) | Claves y cadenas con "RustDesk", "RustDesk Input", "About RustDesk" | Las claves (p. ej. "About RustDesk") se usan en translate(); cambiar exige tocar muchos archivos y comprobar que no se rompa ninguna clave. Dejado para fase posterior o sustitución masiva controlada. |
| **Flutter – internos** | | |
| flutter/lib/utils/multi_window_manager.dart | Clase `RustDeskMultiWindowManager`, `rustDeskWinManager` | Identificadores de código; cambiar requiere refactor en todos los usos. |
| flutter/lib/consts.dart | `kPlatformAdditionsRustDeskVirtualDisplays` | Constante usada en model.dart y toolbar; identificador de plataforma. |
| flutter/lib/models/model.dart | `RustDeskVirtualDisplays`, `isRustDeskIdd` | Getters y lógica de virtual displays; nombre técnico. |
| flutter/lib/common/widgets/toolbar.dart | `isRustDeskIdd` | Uso de la constante anterior. |
| flutter/lib/web/bridge.dart | Comentario y comparación `!= "RustDesk"` | Lógica is_custom_client; debe seguir comparando con "RustDesk". |
| flutter/lib/common.dart | debugPrint "RustDesk", comentarios de log | Solo logs/comentarios. |
| flutter/lib/plugin/manager.dart, plugin/widgets/desc_ui.dart | Comentarios "RustDesk" | Comentarios internos. |
| **Otros** | | |
| res/msi, res/job.py, libs/remote_printer | Nombres RustDesk en driver/impresora, comentarios | Empaquetado y driver; no afectan UI visible; opcional más adelante. |

---

## 2. Resumen de archivos modificados en esta fase

- flutter/lib/desktop/pages/connection_page.dart  
- flutter/lib/desktop/pages/desktop_setting_page.dart  
- flutter/lib/desktop/pages/desktop_home_page.dart  
- flutter/lib/desktop/pages/install_page.dart  
- flutter/lib/desktop/widgets/tabbar_widget.dart  
- flutter/lib/mobile/pages/connection_page.dart  
- flutter/lib/mobile/pages/settings_page.dart  
- flutter/lib/common.dart  

No se ha modificado: ningún binario, ninguna ruta de instalación, ningún nombre de crate/carpeta Kotlin, ni claves de traducción en Rust.

---

## 3. Checklist final de release por plataforma

### Windows
- [ ] `python3 build.py --flutter --marvadesk-cliente` o `--marvadesk-agente` (obligatorio).
- [ ] Título de ventana y barra de pestañas muestran "MarvaDesk Cliente" o "MarvaDesk Agente".
- [ ] Enlaces visibles (web, privacidad, descarga) apuntan a www.solucionesmarva.com.
- [ ] No aparece aviso de actualización desde RustDesk.
- [ ] Firma de código (opcional): configurar signtool/certificado si se distribuye instalador.

### Linux
- [ ] Mismo build.py y variante que Windows.
- [ ] .desktop y ventana muestran MarvaDesk; enlaces a www.solucionesmarva.com.
- [ ] Probar Cliente y Agente (solo entrantes / entrantes+salientes).

### Android
- [ ] Build con `bash flutter/build_android_marvadesk.sh cliente` o `agente` (acopla Rust y flavor).
- [ ] applicationId `com.solucionesmarva.desk`; nombre bajo icono "MarvaDesk Cliente" o "MarvaDesk Agente".
- [ ] Firma release: key.properties y keystore para com.solucionesmarva.desk.
- [ ] Enlaces en la app a www.solucionesmarva.com.

### iOS
- [ ] Build con `bash flutter/build_ios_marvadesk.sh cliente` o `agente`.
- [ ] Bundle ID `com.solucionesmarva.desk`; provisioning profile y firma en Xcode.
- [ ] Display name "MarvaDesk"; título en app desde core.

### macOS
- [ ] `python3 build.py --flutter --marvadesk-cliente` o `--marvadesk-agente`.
- [ ] Bundle id y AppInfo MarvaDesk; enlaces a www.solucionesmarva.com.

---

## 4. Pasos finales manuales (firma y publicación)

### Android
1. Crear o usar keystore para firma de release (com.solucionesmarva.desk).  
2. Configurar `flutter/android/key.properties` (storeFile, storePassword, keyAlias, keyPassword).  
3. Para Play Store: crear aplicación nueva con package `com.solucionesmarva.desk` (no es actualización de una app con otro package).  
4. Opcional: F-Droid con `MARVADESK_VARIANT=cliente` o `agente` y build_fdroid.sh.

### iOS / macOS
1. En Apple Developer: App ID `com.solucionesmarva.desk`, provisioning profiles (desarrollo y distribución).  
2. En Xcode (Runner): seleccionar equipo y perfil para el target Runner.  
3. Archivo → Archive y distribuir a App Store o Ad Hoc según convenga.

### Windows
1. Si se distribuye instalador: configurar firma de código (certificado, signtool) según documentación de build.py.  
2. MSI/instalador: preprocess.py usa por defecto app-name "MarvaDesk"; comprobar que los nombres visibles en el instalador sean correctos.

### Linux
1. Empaquetado (deb/rpm/Flatpak) según scripts existentes; no cambian nombres de binario ni rutas críticas.  
2. Comprobar que los .desktop instalados muestren "MarvaDesk" y que los enlaces sean los nuevos.

---

## 5. Entrega resumida

- **Archivos modificados:** 8 en Flutter (URLs y título de barra de pestañas).  
- **Referencias dejadas intactas:** Lógica y tests en common.rs, rutas e identificadores en platform/virtual_display/uinput/plugin, constantes y clases en Flutter (multi_window_manager, consts, model, toolbar, bridge), todos los archivos de idioma en src/lang. Razón: evitar roturas de build, firma y comportamiento; muchas requieren refactor o decisión de branding en traducciones.  
- **Pasos finales manuales:** Firma Android (keystore/key.properties), provisioning y firma iOS/macOS (Xcode), opcional firma Windows para instalador; publicación en tiendas con nuevo package/bundle id.  
- **URL base en UI:** https://www.solucionesmarva.com. Listado de cada URL (con rutas) en la sección «URLs visibles en la app» del mismo doc.
