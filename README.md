# MarvaDesk

<p align="center">
  <strong>MarvaDesk</strong> — Escritorio remoto personalizado por <strong>Soluciones Marva</strong><br>
  <a href="#construcción">Construcción</a> •
  <a href="#estructura-del-proyecto">Estructura</a> •
  <a href="#licencia-y-atribución">Licencia</a>
</p>

**MarvaDesk** es un fork independiente de [RustDesk](https://github.com/rustdesk/rustdesk), personalizado y mantenido por **Soluciones Marva**. Utiliza la misma base técnica (Rust + Flutter) y el mismo protocolo de escritorio remoto, con configuración fija de servidores y dos variantes de producto:

- **MarvaDesk Cliente** (Quick Support): solo recibe conexiones; orientado a soporte entrante.
- **MarvaDesk Agente**: permite conexiones entrantes y salientes.

Este repositorio **no está asociado operativamente** al upstream de RustDesk: no se envían PRs ni se dependen de sus servidores públicos. Los servidores de conexión, relay y API están fijados a la infraestructura de Soluciones Marva.

> **Aviso de uso indebido:** El uso de este software para accesos no autorizados, control no consentido o invasión de la privacidad es inaceptable. Los autores no se responsabilizan del mal uso de la aplicación.

---

## Características de esta versión

- **Branding MarvaDesk**: nombre, identificadores y metadatos adaptados a Soluciones Marva.
- **Servidores fijos**: configuración de red bloqueada para el usuario final (IDs, Relay, API, Key).
- **Dos variantes**:
  - **Cliente**: solo mostrar datos para recibir conexiones; no permite iniciar conexiones salientes ni modificar servidores.
  - **Agente**: conexiones entrantes y salientes; no permite modificar servidores.
- **Identificadores**:
  - Android / iOS: `com.solucionesmarva.desk`
- Se mantienen todos los avisos de **licencia** y **atribución** al proyecto original RustDesk según la AGPL-3.0.

Para el plan detallado de implementación y la auditoría del repositorio, ver **[docs/MARVADESK_AUDIT_AND_PLAN.md](docs/MARVADESK_AUDIT_AND_PLAN.md)**.

---

## Construcción

Requisitos generales: ver [CLAUDE.md](CLAUDE.md) para comandos y dependencias.

- **Submódulo obligatorio:** la configuración de red y el nombre de la app dependen de `libs/hbb_common`. Inicializar con:
  ```sh
  git submodule update --init --recursive
  ```
- **Rust (núcleo):**  
  `cargo run` (desarrollo) o `cargo build --release` (release). Con Flutter: `cargo build --release --features flutter`.
- **Flutter (desktop):**  
  `python3 build.py --flutter` o `python3 build.py --flutter --release`.
- **Android:**  
  `cd flutter && flutter build android`
- **iOS:**  
  `cd flutter && flutter build ios`

Los valores por defecto de servidores (IDs, Relay, API, Key) y la variante Cliente/Agente se configuran en el submódulo **libs/hbb_common** (repositorio: [mxmarva/hbb_common](https://github.com/mxmarva/hbb_common)).

### Clonación de este repositorio

```sh
git clone --recurse-submodules https://github.com/mxmarva/MarvaDesk
cd MarvaDesk
```

Si ya clonaste sin submódulos:

```sh
git submodule update --init --recursive
```

### Dependencias (resumen)

- Rust, C++ (y en desktop: vcpkg con libvpx, libyuv, opus, aom).
- Flutter para la interfaz de escritorio y móvil.
- Para la UI legacy (Sciter), descargar la biblioteca dinámica según plataforma (ver documentación original de RustDesk si se usa).

---

## Estructura del proyecto

- **libs/hbb_common** (submódulo): configuración, codec de vídeo, protobuf, utilidades de red y transferencia de archivos. En este fork apunta a `mxmarva/hbb_common`.
- **libs/scrap**: captura de pantalla.
- **libs/enigo**: control de teclado y ratón por plataforma.
- **libs/clipboard**: portapapeles multiplataforma.
- **src/**: núcleo Rust (cliente, servidor, rendezvous, plataforma, Flutter FFI).
- **flutter/**: interfaz Flutter para escritorio y móvil.
- **res/**: iconos, .desktop (Linux), MSI (Windows), specs de paquetes.

---

## Licencia y atribución

Este proyecto está bajo la **GNU Affero General Public License v3.0** (AGPL-3.0). Ver [LICENCE](LICENCE).

**MarvaDesk** es una versión modificada de **RustDesk**. RustDesk es Copyright © Purslane Ltd. y colaboradores. Se mantienen los avisos de copyright y licencia del proyecto original en los archivos correspondientes. No se eliminan ni ocultan las atribuciones exigidas por la licencia.

---

## Documentación adicional

- [CLAUDE.md](CLAUDE.md) — Comandos de build y arquitectura para el asistente de código.
- [docs/MARVADESK_AUDIT_AND_PLAN.md](docs/MARVADESK_AUDIT_AND_PLAN.md) — Auditoría del repositorio y plan de implementación de la personalización MarvaDesk.

---

*MarvaDesk — Soluciones Marva. Basado en RustDesk.*
