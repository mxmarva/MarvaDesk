# MarvaDesk – Integración de variantes de build (Cliente / Agente)

## 1. Auditoría: dónde se invoca cargo / hbb_common

| Origen | Dónde | Comando / uso |
|--------|--------|----------------|
| **Cargo.toml (raíz)** | `[dependencies]` y `[build-dependencies]` | `hbb_common = { path = "libs/hbb_common" }` sin features. Todas las compilaciones del crate principal usan esta dependencia. |
| **build.py** | `get_features(args)` → `features = ','.join(get_features(args))` | `cargo build --features {features} --lib --release` (Windows Flutter, Linux deb, Arch, macOS DMG). También `cargo build --release --features ...` en rutas sin Flutter. |
| **build.py** | build_flutter_windows, build_flutter_dmg, build_flutter_deb, build_flutter_arch_manjaro | Mismo `features` pasado a cargo. |
| **flutter/ndk_arm64.sh** | Línea 2 | `cargo ndk ... --features flutter,hwcodec` |
| **flutter/ndk_arm.sh** | Línea 2 | `cargo ndk ... --features flutter,hwcodec` |
| **flutter/ndk_x64.sh** | Línea 2 | `cargo ndk ... --features flutter` |
| **flutter/ndk_x86.sh** | Línea 2 | `cargo ndk ... --features flutter` |
| **flutter/ios_arm64.sh** | Línea 2 | `cargo build --features flutter,hwcodec --release --target aarch64-apple-ios --lib` |
| **flutter/ios_x64.sh** | Línea 2 | `cargo build --features flutter --release --target x86_64-apple-ios --lib` |
| **flutter/run.sh** | Línea 8 | `cargo build --features flutter` |
| **flutter/build_fdroid.sh** | RUSTDESK_FEATURES por ABI, luego cargo ndk | `--features "${RUSTDESK_FEATURES}"` (ej. `flutter,hwcodec` o `flutter`). |
| **.github/workflows/flutter-build.yml** | Varios jobs | `cargo build --features inline,vram,hwcodec ...`, `cargo build --features flutter,hwcodec --release --target aarch64-apple-ios --lib`, `cargo build --lib ... --features hwcodec,flutter,...`, etc. |
| **libs/enigo, libs/libxdo-sys-stub** | Cargo.toml propios | `hbb_common = { path = "../hbb_common" }` sin features; heredan la versión del workspace. |

Conclusión: la variante MarvaDesk (Cliente o Agente) debe añadirse como **feature adicional** en todas las invocaciones de `cargo build` / `cargo ndk` que construyan el binario o la lib del proyecto principal. La forma más limpia es definir en el crate principal las features `marvadesk_cliente` y `marvadesk_agente` que reenvían a `hbb_common/marvadesk_cliente` y `hbb_common/marvadesk_agente`, y pasar una de ellas en cada build.

---

## 2. Dónde pasar las features

- **Crate principal (Cargo.toml raíz)**: Añadir `marvadesk_cliente = ["hbb_common/marvadesk_cliente"]` y `marvadesk_agente = ["hbb_common/marvadesk_agente"]` en `[features]`. Así cualquier comando `cargo build --features flutter,marvadesk_cliente` (o `marvadesk_agente`) activa la variante en hbb_common.
- **build.py**: Añadir argumentos `--marvadesk-cliente` y `--marvadesk-agente` (excluyentes). En `get_features(args)` añadir la feature correspondiente al string de features que se pasa a cargo. **Con `--flutter`, es obligatorio** pasar uno de los dos; si no, el script sale con error.
- **flutter/ndk_*.sh y flutter/ios_*.sh**: Usar variable de entorno `MARVADESK_VARIANT=cliente` o `MARVADESK_VARIANT=agente`. Si está definida, añadir `,marvadesk_${MARVADESK_VARIANT}` a la lista de features del comando cargo.
- **flutter/run.sh**: Idem; si `MARVADESK_VARIANT` está definida, añadirla a las features de `cargo build`.
- **flutter/build_fdroid.sh**: Después de fijar `RUSTDESK_FEATURES` por ABI, si `MARVADESK_VARIANT` está definida, hacer `RUSTDESK_FEATURES="${RUSTDESK_FEATURES},marvadesk_${MARVADESK_VARIANT}"`.
- **.github/workflows**: Para CI de MarvaDesk, definir en el workflow (input o env) la variante deseada y pasar la feature en cada paso que ejecute `cargo build` o `cargo ndk` (p. ej. añadiendo `,marvadesk_cliente` o `,marvadesk_agente` al string de features). Opcional en esta fase; se puede documentar para cuando se configure CI propio.

---

## 3. Convención única de build

- **Desktop (build.py)**  
  - Cliente: `python3 build.py --flutter --marvadesk-cliente` (y opciones de hwcodec/vram/etc. si aplican).  
  - Agente: `python3 build.py --flutter --marvadesk-agente`.  
  - Con --flutter, es obligatorio pasar una variante; si no, build.py termina con error. “genérico” sin variante (comportamiento anterior; en MarvaDesk conviene exigir siempre una variante).

- **Variable de entorno MARVADESK_VARIANT**  
  - Valores: `cliente` | `agente`.  
  - Uso: scripts que no reciben argumentos (ndk_*.sh, ios_*.sh, run.sh, build_fdroid.sh) leen `MARVADESK_VARIANT` y añaden la feature `marvadesk_${MARVADESK_VARIANT}`.  
  - Ejemplo: `MARVADESK_VARIANT=cliente ./flutter/ndk_arm64.sh`.

- **Cargo directo**  
  - Cliente: `cargo build --features "flutter,marvadesk_cliente" --lib --release` (y target/otros flags según plataforma).  
  - Agente: `cargo build --features "flutter,marvadesk_agente" --lib --release`.

---

## 4. Archivos a modificar (lista exacta)

| Archivo | Cambio |
|---------|--------|
| **Cargo.toml** (raíz) | En `[features]`, añadir `marvadesk_cliente = ["hbb_common/marvadesk_cliente"]` y `marvadesk_agente = ["hbb_common/marvadesk_agente"]`. |
| **build.py** | En `make_parser()`, añadir `--marvadesk-cliente` y `--marvadesk-agente` (store_true, mutuamente excluyentes en uso). En `get_features(args)`, si `args.marvadesk_cliente` añadir `'marvadesk_cliente'`; si `args.marvadesk_agente` añadir `'marvadesk_agente'`. |
| **flutter/ndk_arm64.sh** | Construir string de features incluyendo `marvadesk_${MARVADESK_VARIANT}` cuando `MARVADESK_VARIANT` esté definida. |
| **flutter/ndk_arm.sh** | Idem. |
| **flutter/ndk_x64.sh** | Idem. |
| **flutter/ndk_x86.sh** | Idem. |
| **flutter/ios_arm64.sh** | Idem. |
| **flutter/ios_x64.sh** | Idem. |
| **flutter/run.sh** | Idem para `cargo build --features ...`. |
| **flutter/build_fdroid.sh** | Después de asignar `RUSTDESK_FEATURES` por ABI, si `MARVADESK_VARIANT` está definida, `RUSTDESK_FEATURES="${RUSTDESK_FEATURES},marvadesk_${MARVADESK_VARIANT}"`. |

No se modifican en esta fase: logos, package ids (Android/iOS), ni workflows de GitHub (solo se documenta cómo añadir la variante cuando se use CI propio).  
**Nota:** La fase de branding (package id, nombres visibles, etc.) se describe en **docs/MARVADESK_BRANDING_AND_IDS.md**.

---

## 5. Comandos exactos de build por plataforma (Cliente y Agente)

### Windows (Flutter)
- Cliente: `python3 build.py --flutter --marvadesk-cliente` (opcional: `--hwcodec`, `--vram`).  
- Agente: `python3 build.py --flutter --marvadesk-agente` (idem opcionales).

### Linux (Flutter, deb)
- Cliente: `python3 build.py --flutter --marvadesk-cliente` (en entorno Debian/Ubuntu; opcional `--hwcodec`).  
- Agente: `python3 build.py --flutter --marvadesk-agente`.

### Linux (Arch/Manjaro)
- Cliente: `python3 build.py --flutter --marvadesk-cliente`.  
- Agente: `python3 build.py --flutter --marvadesk-agente`.

### macOS (Flutter, DMG)
- Cliente: `python3 build.py --flutter --marvadesk-cliente` (opcional `--screencapturekit`).  
- Agente: `python3 build.py --flutter --marvadesk-agente`.

### Android (local, todas las ABIs)
- **Recomendado (acopla Rust + flavor):** usar el script único que garantiza que la variante Rust y el flavor Android coincidan:
  - Cliente: `bash flutter/build_android_marvadesk.sh cliente` (genera libs con MARVADESK_VARIANT=cliente y luego `flutter build apk --flavor cliente`).
  - Agente: `bash flutter/build_android_marvadesk.sh agente`.
  - Opcional: pasar ABIs concretos, p. ej. `bash flutter/build_android_marvadesk.sh cliente arm64-v8a armeabi-v7a`.
- Manual (asumir riesgo de desacople): precompilar libs con `MARVADESK_VARIANT=cliente bash flutter/ndk_arm64.sh` (y el resto de ndk_*.sh), luego `cd flutter && flutter build apk --flavor cliente --release`. Ver **docs/MARVADESK_VALIDATION_AND_RELEASE.md**.

### iOS (local)
- **Recomendado (acopla Rust + variante):** usar el script único:
  - Cliente: `bash flutter/build_ios_marvadesk.sh cliente`.
  - Agente: `bash flutter/build_ios_marvadesk.sh agente`.
- Manual: `MARVADESK_VARIANT=cliente bash flutter/ios_arm64.sh` (y ios_x64.sh si hace falta). Luego `cd flutter && flutter build ios --release`. Ver **docs/MARVADESK_VALIDATION_AND_RELEASE.md**.

### F-Droid / script build_fdroid.sh
- Cliente: `MARVADESK_VARIANT=cliente bash flutter/build_fdroid.sh` (con las env que ese script ya use).  
- Agente: `MARVADESK_VARIANT=agente bash flutter/build_fdroid.sh`.

### Desarrollo local (run)
- Cliente: `MARVADESK_VARIANT=cliente bash flutter/run.sh` (o desde `flutter/`: `MARVADESK_VARIANT=cliente cargo build --features "flutter,marvadesk_cliente"` y `flutter run`).  
- Agente: `MARVADESK_VARIANT=agente bash flutter/run.sh`.

---

## 6. Riesgos por plataforma

| Plataforma | Riesgo | Mitigación |
|------------|--------|------------|
| **Windows** | Sin pasar la feature se construye sin variante MarvaDesk (nombre/servidores por defecto de hbb_common sin init). | Con `--flutter`, build.py **exige** `--marvadesk-cliente` o `--marvadesk-agente`; sin uno de ellos el script termina con error. |
| **Linux** | Múltiples distribuciones (deb, Arch, etc.); mismo script build.py. | Misma convención; comprobar que en todas las ramas de build.py que llaman a `cargo build` se use `get_features(args)` (ya incluye la feature MarvaDesk si se pasó el flag). |
| **macOS** | build_flutter_dmg usa `get_features(args)`; mismo riesgo que Windows si no se pasa el flag. | Igual que Windows. |
| **Android** | Si se olvida MARVADESK_VARIANT al ejecutar ndk_*.sh, la lib se construye sin variante. Flutter build apk no invoca cargo; usa las .so ya generadas. | Documentar que para MarvaDesk hay que ejecutar los ndk_*.sh con MARVADESK_VARIANT antes de `flutter build apk`. Opcional: comprobar en el script que MARVADESK_VARIANT esté definida y salir con error si no. |
| **iOS** | Mismo esquema que Android: las scripts construyen la lib; si no se pasa MARVADESK_VARIANT, la lib no tendrá la variante. | Misma documentación; opcional validación en ios_*.sh. |
| **F-Droid** | build_fdroid.sh puede ejecutarse en CI; la variable debe estar definida en el entorno de CI. | En el workflow que llame a build_fdroid.sh, definir `MARVADESK_VARIANT=cliente` o `agente` en `env`. |
| **CI (.github)** | Los workflows actuales no pasan ninguna feature MarvaDesk. | Para builds de MarvaDesk, añadir en los jobs correspondientes la feature (o un input que la seleccione) en cada `cargo build` / `cargo ndk`. |

---

## 7. Aviso anti-estafa (scam): opción 3 aplicada

Se aplica **opción 3 (quitar de raíz)** en `flutter/lib/mobile/pages/server_page.dart`:

- Se elimina la clase **ScamWarningDialog** y la función **showScamWarning**.
- En **ServiceNotRunningNotification** y **PermissionChecker**, donde se llamaba a `showScamWarning(context, serverModel)` antes de permitir iniciar el servicio o activar permisos, se llama directamente a la acción correspondiente (p. ej. `serverModel.toggleService()` o el callback que ya se usaba en el ramal “no mostrar aviso”).

Así no se depende de `get_app_name() != "RustDesk"` para ningún comportamiento; el aviso desaparece por eliminación del código, no por condición.
