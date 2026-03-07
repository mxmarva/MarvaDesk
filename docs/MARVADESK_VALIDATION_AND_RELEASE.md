# MarvaDesk – Validación técnica y endurecimiento de builds

Este documento recoge la auditoría de consistencia, validación funcional, referencias residuales y checklist de release para MarvaDesk Cliente y MarvaDesk Agente.

---

## 1. Auditoría de consistencia (variante Rust ↔ nombre visible)

### 1.1 Windows

| Paso | Cómo se selecciona la variante Rust | Cómo se refleja el nombre visible |
|------|-------------------------------------|-----------------------------------|
| build.py --flutter --marvadesk-cliente / --marvadesk-agente | `get_features(args)` añade `marvadesk_cliente` o `marvadesk_agente` al string de features pasado a `cargo build`. | Obligatorio: sin uno de los dos flags, build.py sale con error. |
| build_flutter_windows() | Usa `features = ','.join(get_features(args))` → mismo features en cargo. | Título de ventana desde `get_rustdesk_app_name()` en main.cpp → "MarvaDesk Cliente" / "MarvaDesk Agente" según APP_NAME en hbb_common. |

**Conclusión:** Consistente. Una sola entrada (flags de build.py) determina tanto la feature Rust como el nombre visible.

---

### 1.2 Linux

| Paso | Variante Rust | Nombre visible |
|------|----------------|----------------|
| build.py --flutter --marvadesk-cliente / --marvadesk-agente | Igual que Windows: `get_features(args)` → cargo. | .desktop y ventana "MarvaDesk"; título interno desde core (get_app_name()). |

**Conclusión:** Consistente.

---

### 1.3 Android (riesgo identificado y mitigado)

| Paso | Variante Rust | Nombre visible (flavor) |
|------|----------------|--------------------------|
| ndk_arm64.sh / ndk_arm.sh / ndk_x64.sh / ndk_x86.sh | `MARVADESK_VARIANT` → `marvadesk_${MARVADESK_VARIANT}` en features de `cargo ndk`. | No lo determinan; solo construyen la .so. |
| flutter build apk --flavor cliente \| agente | No invoca cargo; usa las .so ya generadas en jniLibs. | El flavor define `app_name` (MarvaDesk Cliente / MarvaDesk Agente). |

**Inconsistencia potencial:** Si se ejecuta `MARVADESK_VARIANT=cliente bash flutter/ndk_arm64.sh` y luego `flutter build apk --flavor agente`, el APK tendría nombre "MarvaDesk Agente" pero el core Rust sería Cliente (solo entrantes). O al revés.

**Mitigación aplicada:**
- **Script único recomendado:** `flutter/build_android_marvadesk.sh <cliente|agente> [abi...]`. Exporta `MARVADESK_VARIANT`, ejecuta los ndk_*.sh necesarios y luego `flutter build apk --flavor <cliente|agente>`. Así flavor y feature Rust quedan acoplados en un solo comando.
- **build_fdroid.sh:** Si `MARVADESK_VARIANT` está definida, se añade `--flavor ${MARVADESK_VARIANT}` a `flutter build apk`, de modo que el APK use el mismo flavor que la lib Rust construida en el mismo paso.

**Recomendación:** Para builds Android manuales, usar siempre `build_android_marvadesk.sh` en lugar de llamar por separado a los ndk y a `flutter build apk`.

---

### 1.4 iOS

| Paso | Variante Rust | Nombre visible |
|------|----------------|----------------|
| ios_arm64.sh / ios_x64.sh | `MARVADESK_VARIANT` → `marvadesk_${MARVADESK_VARIANT}` en features de `cargo build --target ... --lib`. | No; solo generan la lib estática. |
| flutter build ios | No ejecuta cargo; usa la lib ya generada. | CFBundleDisplayName "MarvaDesk" en Info.plist; título en app desde get_app_name(). |

**Mismo riesgo conceptual:** Si se ejecuta ios_arm64.sh con `MARVADESK_VARIANT=agente` y luego se hace `flutter build ios` sin acordarse de la variante, el binario Rust ya está fijado; no hay “flavor” en iOS que lo cambie. El riesgo es humano (compilar lib con una variante y asumir otra).

**Mitigación aplicada:**
- **Script único recomendado:** `flutter/build_ios_marvadesk.sh <cliente|agente>`. Exporta `MARVADESK_VARIANT`, ejecuta ios_arm64.sh e ios_x64.sh y luego `flutter build ios`. Una sola invocación con un argumento asegura consistencia.

---

### 1.5 macOS

| Paso | Variante Rust | Nombre visible |
|------|----------------|----------------|
| build.py --flutter --marvadesk-cliente \| --marvadesk-agente | `get_features(args)` → cargo en build_flutter_dmg(). | PRODUCT_NAME en AppInfo.xcconfig = MarvaDesk; título interno desde core. |

**Conclusión:** Consistente (mismo flujo que Windows/Linux).

---

## 2. Validación funcional

La lógica de variantes (servidores fijos, solo entrantes en Cliente, etc.) está en **hbb_common** (repo externo según contexto). En el repo MarvaDesk se asume que las features `marvadesk_cliente` y `marvadesk_agente` activan `init_marvadesk()` y las constantes correspondientes. Comprobaciones en este repo:

### 2.1 Cliente (marvadesk_cliente)

| Comportamiento esperado | Dónde verificarlo |
|-------------------------|-------------------|
| Nombre visible "MarvaDesk Cliente" | get_app_name() en common.rs lee APP_NAME de hbb_common; en desktop (Windows/Linux) el título viene de get_rustdesk_app_name(); en Android flavor "cliente" → resValue "MarvaDesk Cliente". |
| Solo conexiones entrantes | hbb_common config: HARD_SETTINGS["conn-type"] = "incoming" para Cliente. |
| No permite conexiones salientes | Misma restricción en config. |
| No permite editar servidor IDs / relay / API / key | hbb_common: OVERWRITE_SETTINGS y hide-server-settings. |
| Valores fijos (marvadesk.solucionesmarva.com, etc.) | hbb_common: RENDEZVOUS_SERVERS, RS_PUB_KEY, etc. |
| No intenta auto-update | src/common.rs: do_check_software_update() retorna sin pedir si !is_rustdesk() (APP_NAME != "RustDesk"). |

### 2.2 Agente (marvadesk_agente)

| Comportamiento esperado | Dónde verificarlo |
|-------------------------|-------------------|
| Nombre visible "MarvaDesk Agente" | Igual que arriba; flavor "agente" en Android. |
| Conexiones entrantes y salientes | hbb_common: sin forzar conn-type = "incoming". |
| No permite editar servidor / relay / API / key | Igual que Cliente. |
| Valores fijos | Igual que Cliente. |
| No intenta auto-update | Igual que Cliente. |

### 2.3 Auto-actualización

- En **src/common.rs**, `do_check_software_update()`: si `!is_rustdesk()` se asigna `SOFTWARE_UPDATE_URL = ""` y se retorna sin llamar a api.rustdesk.com. Para MarvaDesk (APP_NAME "MarvaDesk Cliente" o "MarvaDesk Agente") no se hace petición de actualización.

---

## 3. Búsqueda de referencias residuales

Referencias que siguen apuntando a RustDesk / rustdesk.com / api.rustdesk.com o a nombres visibles no actualizados (no exhaustivas en traducciones):

### 3.1 Críticas para producto (nombres/URLs visibles o comportamiento)

| Archivo | Uso | Sugerencia |
|---------|-----|-------------|
| flutter/lib/mobile/pages/connection_page.dart | `url = 'https://rustdesk.com/download'` | Sustituir por URL de MarvaDesk/Soluciones Marva si se quiere que el botón de descarga apunte a vuestra web. |
| flutter/lib/mobile/pages/settings_page.dart | `url = 'https://rustdesk.com/'`, texto "rustdesk.com", privacy | Idem. |
| flutter/lib/desktop/pages/connection_page.dart | `"https://rustdesk.com/pricing"` | Idem. |
| flutter/lib/desktop/pages/desktop_home_page.dart | rustdesk.com/download, docs | Idem. |
| flutter/lib/desktop/pages/desktop_setting_page.dart | rustdesk.com/privacy, rustdesk.com | Idem. |
| flutter/lib/desktop/pages/install_page.dart | rustdesk.com/privacy | Idem. |
| flutter/lib/common.dart | launchUrl('https://rustdesk.com') | Idem. |
| flutter/lib/desktop/widgets/tabbar_widget.dart | string "RustDesk" (hardcoded) | Sustituir por get_app_name() o "MarvaDesk" según contexto. |
| src/common.rs | is_public() y admin URL "https://admin.rustdesk.com"; comentarios api.rustdesk.com | Comportamiento: is_rustdesk() ya evita update. Admin URL solo relevante si se usa esa función para algo en MarvaDesk. |

### 3.2 Menos críticas (internas, comentarios, traducciones)

- **src/server/uinput.rs:** nombre interno "RustDesk UInput Keyboard" (dispositivo Linux).
- **src/lang/*.rs:** Muchas cadenas con "RustDesk" en traducciones (ja, el, ge, sc, sq, etc.). Sustituir por "MarvaDesk" o usar clave traducida que tome el nombre de la app si se quiere coherencia en todos los idiomas.
- **res/job.py, libs/remote_printer, res/msi:** Referencias a RustDesk en comentarios o nombres de driver/impresora; no cambian el flujo de MarvaDesk pero pueden actualizarse en una fase de branding de impresora/driver.

### 3.3 Scheme / deep links

- Android e iOS ya usan scheme **marvadesk** en manifest e Info.plist.
- En Dart, enlaces generados (p. ej. home_page.dart) pueden seguir usando un prefijo; si se usa get_uri_prefix() del core, para MarvaDesk devolvería "marvadesk cliente://" o "marvadesk agente://" (con espacio). Si se quiere un esquema único "marvadesk://", conviene normalizar en hbb_common o en el cliente (p. ej. usar siempre "marvadesk" como scheme en la UI).

---

## 4. Release readiness – Checklist por plataforma

### Windows
- [ ] build.py exige --marvadesk-cliente o --marvadesk-agente con --flutter.
- [ ] cargo build --features incluye marvadesk_cliente o marvadesk_agente.
- [ ] Título de ventana y metadatos (Runner.rc / winres) muestran MarvaDesk.
- [ ] No se muestra aviso de actualización desde RustDesk.
- [ ] Probar Cliente: solo entrantes, no editar servidores.
- [ ] Probar Agente: entrantes y salientes, no editar servidores.

### Linux
- [ ] Igual que Windows (build.py, features, .desktop, my_application.cc).
- [ ] Probar Cliente y Agente como en Windows.

### Android
- [ ] Usar **build_android_marvadesk.sh** cliente o agente para acoplar Rust y flavor.
- [ ] applicationId com.solucionesmarva.desk; flavors cliente y agente con nombres correctos.
- [ ] Firma de release configurada para el nuevo applicationId.
- [ ] Probar instalación y que el nombre bajo el icono sea "MarvaDesk Cliente" o "MarvaDesk Agente".
- [ ] Probar comportamiento Cliente/Agente y que no haya update desde RustDesk.

### iOS
- [ ] Usar **build_ios_marvadesk.sh** cliente o agente para acoplar Rust y variante.
- [ ] Bundle id com.solucionesmarva.desk; provisioning y firma en Xcode.
- [ ] Display name "MarvaDesk"; título en app desde core.
- [ ] Probar en dispositivo/simulador y comportamiento de variante.

### macOS
- [ ] build.py --flutter --marvadesk-cliente o --marvadesk-agente.
- [ ] Bundle id y AppInfo.xcconfig MarvaDesk.
- [ ] Probar Cliente y Agente.

---

## 5. Entrega: archivos problemáticos, inconsistencias y cambios sugeridos

### 5.1 Archivos / puntos problemáticos encontrados

1. **Android:** Flavor y feature Rust desacoplados si se usa `flutter build apk --flavor X` sin haber generado las .so con MARVADESK_VARIANT=X.
2. **build_fdroid.sh:** Antes no pasaba --flavor a flutter build apk cuando MARVADESK_VARIANT estaba definida; corregido para que use `--flavor ${MARVADESK_VARIANT}`.
3. **iOS/macOS:** Mismo riesgo conceptual (lib construida con una variante, usuario puede asumir otra).
4. **Referencias rustdesk.com / RustDesk en Flutter y en traducciones:** Enlaces y textos visibles siguen apuntando a rustdesk.com; tabbar_widget tiene "RustDesk" hardcoded.

### 5.2 Inconsistencias detectadas

| Plataforma | Inconsistencia | Estado |
|------------|----------------|--------|
| Android | flavor sin garantía de coincidir con feature Rust | Mitigado con build_android_marvadesk.sh y doc. |
| build_fdroid | flutter build apk sin --flavor | Corregido: se añade --flavor cuando MARVADESK_VARIANT está definida. |
| iOS | variante Rust solo en scripts, no en Xcode | Mitigado con build_ios_marvadesk.sh. |

### 5.3 Cambios aplicados (endurecimiento)

- **flutter/build_android_marvadesk.sh:** Script que recibe cliente|agente, exporta MARVADESK_VARIANT, ejecuta ndk_*.sh (por ABI) y luego flutter build apk --flavor <cliente|agente>.
- **flutter/build_ios_marvadesk.sh:** Script que recibe cliente|agente, exporta MARVADESK_VARIANT, ejecuta ios_arm64.sh e ios_x64.sh y luego flutter build ios.
- **flutter/build_fdroid.sh:** Uso de `--flavor ${MARVADESK_VARIANT}` en las dos llamadas a flutter build apk cuando MARVADESK_VARIANT está definida.

### 5.4 Cambios sugeridos mínimos (opcionales para release)

- ~~Sustituir en Flutter las URLs rustdesk.com por URLs de Soluciones Marva~~ **Hecho en fase de limpieza:** ver **docs/MARVADESK_RELEASE_CLEANUP.md**.
- ~~En tabbar_widget.dart, reemplazar el string "RustDesk" por el nombre que devuelva el core~~ **Hecho:** se usa `bind.mainGetAppNameSync()`.
- Revisar home_page.dart y cualquier generación de enlace (marvadesk://) para que el scheme sea coherente con el manifest (marvadesk).

### 5.5 Checklist final de publicación

- [ ] **Desktop (Win/Linux/mac):** build.py siempre con --marvadesk-cliente o --marvadesk-agente; probado Cliente y Agente.
- [ ] **Android:** Builds con build_android_marvadesk.sh; firma con com.solucionesmarva.desk; probado ambos flavors.
- [ ] **iOS:** Builds con build_ios_marvadesk.sh; App ID y provisioning com.solucionesmarva.desk; probado en dispositivo.
- [ ] **F-Droid/CI:** MARVADESK_VARIANT definida y build_fdroid.sh usando --flavor.
- [ ] **Actualización:** Confirmar que no se llama a api.rustdesk.com (do_check_software_update con !is_rustdesk()).
- [ ] **Documentación:** MARVADESK_BUILD_VARIANTS.md y MARVADESK_BRANDING_AND_IDS.md actualizados con los scripts build_android_marvadesk.sh y build_ios_marvadesk.sh como entrada recomendada para Android e iOS.
