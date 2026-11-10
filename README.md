# I Love LSC — La Seña Universal para el Cambio

Prototipo **1.0.1** (producto mínimo viable) de la app para aprender Lengua de Señas Colombiana (LSC).
Flutter + Dart · Riverpod · go_router · Firebase (Auth, Firestore, Storage, Messaging, Analytics).

---

## 1. Qué incluye

| #   | Característica de la ficha                                                                    | Dónde está                                                                                                     |
| --- | --------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| 1   | Mapa por unidades con desbloqueo progresivo                                                   | `features/learn`, `features/content/domain/course_catalog.dart`                                                |
| 2   | Lecciones con video en LSC (pausar y repetir)                                                 | `features/lessons/presentation/widgets/sign_video_player.dart`                                                 |
| 3   | Ejercicios «Ver y elegir», «Palabra a seña» y «Parejas»                                       | `features/lessons`                                                                                             |
| 4   | XP, racha diaria, vidas y repaso de errores                                                   | `features/progress/domain/gamification_rules.dart`                                                             |
| 5   | Seguimiento del progreso                                                                      | `features/progress`                                                                                            |
| 6   | Recordatorios de práctica (Cloud Messaging)                                                   | `features/notifications`                                                                                       |
| 7   | Constancia o insignia digital (no es certificado académico)                                   | `features/progress/presentation/badge_screen.dart`                                                             |
| 8   | Contenido co-creado con personas sordas: solicitud de colaboradores, validación y publicación | `features/collaborators`, `features/admin`                                                                     |
| 9   | Accesibilidad (WCAG 2.1 AA como referencia)                                                   | contraste en `core/theme`, etiquetas `Semantics`, objetivos táctiles ≥ 48 px, el color nunca es la única señal |
| 10  | Uso gratuito en el prototipo                                                                  | —                                                                                                              |

También: registro con foto opcional y autorización de datos (Ley 1581), bienvenida, encuesta de experiencia,
eliminación de cuenta y datos, reglas de seguridad de Firebase y Analytics para el piloto.

---

## 2. Lo que necesitas instalar

1. **Flutter SDK** (canal _stable_): <https://docs.flutter.dev/get-started/install> (incluye Dart; se requiere Dart ≥ 3.6).
2. **Android Studio**: trae el _Android SDK_ y el **emulador**. Instala también el plugin _Flutter_ si quieres abrir el proyecto allí.
3. **Visual Studio Code** con las extensiones **Dart** y **Flutter**.
4. **Node.js LTS** (para la herramienta de línea de comandos de Firebase).
5. Una cuenta de Google (para Firebase).

Comprueba que todo quedó bien:

```bash
flutter doctor
flutter doctor --android-licenses     # acepta todas las licencias con "y"
```

`flutter doctor` debe mostrar ✔ en _Flutter_, _Android toolchain_, _Android Studio_ y _VS Code_.

---

## 3. Puesta en marcha paso a paso

### Paso 1 — Abrir el proyecto en VS Code

1. Descomprime el `.zip`.
2. VS Code → **File ▸ Open Folder…** → elige la carpeta `I-LOVE-LSC`.
3. Si VS Code propone instalar las extensiones recomendadas (Dart y Flutter), acepta.
4. Abre la terminal integrada: **Terminal ▸ New Terminal**. Todos los comandos siguientes se ejecutan ahí, en la carpeta del proyecto.

### Paso 2 — Generar la carpeta `android/`

El `.zip` trae el código de la app pero no los archivos nativos de Android (los genera Flutter):

```bash
flutter create --platforms=android --org com.ilovelsc --project-name i_love_lsc .
flutter pub get
```

- Este comando **no toca** `lib/`, `test/` ni `pubspec.yaml`; solo agrega `android/` y archivos auxiliares.
- El identificador de la app queda como `com.ilovelsc.i_love_lsc` (lo usará Firebase).

Abre `android/app/src/main/AndroidManifest.xml` y, dentro de `<manifest …>` (antes de `<application`), agrega:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

(`INTERNET` hace falta para las versiones _release_; `POST_NOTIFICATIONS` para los recordatorios en Android 13 o superior.)

Si al compilar aparece un error sobre `minSdkVersion`, abre `android/app/build.gradle.kts` (o `build.gradle`) y fija `minSdk = 24`.

### Paso 3 — Crear y arrancar un emulador (Android Studio)

1. Abre **Android Studio** (sin abrir ningún proyecto basta con la pantalla de bienvenida) → **More Actions ▸ Virtual Device Manager** (o **Tools ▸ Device Manager**).
2. **Create Device** → por ejemplo _Pixel 7_ → una imagen de sistema reciente que diga **Google Play** (la necesitan las notificaciones) → _Finish_.
3. Pulsa el botón ▶ junto al dispositivo. Se abre la ventana del emulador: **ahí verás la app**.

### Paso 4 — Primera ejecución (sin Firebase todavía)

1. En VS Code, abajo a la derecha, pulsa el selector de dispositivo y elige tu emulador.
2. Pulsa **F5** (o **Run ▸ Start Debugging**). La primera compilación tarda varios minutos.
3. Debe abrirse la pantalla **«Falta conectar Firebase»**. Es lo esperado: confirma que tu entorno funciona. Sigue con el paso 5.

### Paso 5 — Conectar Firebase

1. Entra a <https://console.firebase.google.com> → **Agregar proyecto** (por ejemplo `i-love-lsc`). Deja activado Google Analytics: la app envía los eventos del piloto (lecciones iniciadas y completadas, encuesta, etc.) y los verás en la consola.
2. **Authentication ▸ Comenzar ▸ Método de acceso ▸ Correo electrónico/contraseña ▸ Habilitar.**
3. **Firestore Database ▸ Crear base de datos** → elige una ubicación (por ejemplo `southamerica-east1` o `nam5`) → modo **producción**.
4. **Storage ▸ Comenzar.**
   > Según el momento y el tipo de proyecto, Firebase puede pedir cambiar al plan **Blaze** (pago por uso, con cupo gratuito) para activar Storage. Revísalo en la consola antes de decidir. Si no lo activas, la app sigue funcionando, pero no podrán subirse fotos de perfil ni videos desde Storage (los videos pueden usar direcciones `https://…` directas en el campo `videoPath`).
5. Instala las herramientas de línea de comandos (una sola vez):

   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   ```

   En Windows, si `flutterfire` no se reconoce, agrega `%LOCALAPPDATA%\Pub\Cache\bin` a la variable de entorno `Path` y abre una terminal nueva.

6. Vincula la app con tu proyecto (elige el proyecto creado y deja marcado solo **android**):

   ```bash
   flutterfire configure --platforms=android
   ```

   Esto **reemplaza** `lib/firebase_options.dart` y deja listo el plugin de Google Services en Android.

7. **Reglas de seguridad** (obligatorio): copia el contenido de estos archivos y pégalo en la consola, pulsando **Publicar**:
   - `firebase/firestore.rules` → _Firestore Database ▸ Reglas_
   - `firebase/storage.rules` → _Storage ▸ Reglas_

### Paso 6 — Ejecutar la app de verdad

Detén la app (⏹) y vuelve a ejecutarla con **F5**. Ahora aparece el inicio de sesión. Pulsa **Crear una cuenta**, completa el formulario, acepta los términos y entra. Verás la bienvenida y luego el mapa de aprendizaje (vacío por ahora).

### Paso 7 — Volverte administrador y cargar contenido de ejemplo

1. En la consola de Firebase: **Firestore Database ▸ Datos ▸ colección `users`** → abre el documento con tu cuenta → **Agregar campo**: `role` (tipo _string_) = `admin`.
   (El rol de administrador solo se asigna aquí, nunca desde la app.)
2. En la app: **Perfil ▸ Administración de contenidos ▸ Cargar contenido de ejemplo**:
   - **Modo pruebas**: marca todo como validado/publicado y usa un video de muestra (un video de internet, **no es una seña real**). Es la forma más rápida de ver la app completa funcionando.
   - **Borrador**: crea las lecciones sin validar ni publicar; luego las publicas una a una con los interruptores (una lección solo se puede publicar si está validada).
3. Vuelve a **Aprender** y desliza hacia abajo para refrescar.

### Paso 8 — Videos reales en LSC

Los videos deben ser grabados o validados por personas sordas o intérpretes certificados (ver ficha). Súbelos a **Storage** con la ruta que indica cada seña: `videos/<carpeta>/<id>.mp4` (por ejemplo `videos/saludos/hola.mp4`). La lista de rutas está en `lib/features/content/data/seed_content.dart`. Usa MP4 con códec H.264. Los videos **no se guardan en el repositorio** (ver `.gitignore`).

### Paso 9 — Probar los recordatorios

1. En la app: **Perfil ▸ Recordatorios de práctica** → permite las notificaciones.
2. En la consola: **Messaging ▸ Crear campaña ▸ Mensajes de notificación de Firebase** → _Destino_: **Tema** `recordatorios_practica`.
3. Si la app está abierta, el mensaje aparece como aviso dentro de la app; si está en segundo plano, como notificación del sistema.

---

## 4. Verlo con Android Studio

- **Ver la app corriendo:** el emulador de Android Studio (paso 3) es la pantalla donde se ve. Puedes trabajar el código en VS Code y mirar el resultado ahí; con **r** (recarga rápida) o **R** (reinicio) en la terminal, o guardando el archivo, los cambios se reflejan al instante.
- **Abrir el proyecto en Android Studio** (opcional): _File ▸ Open_ → carpeta `I-LOVE-LSC` (requiere el plugin Flutter). Elige el emulador en la barra superior y pulsa ▶ _Run_. También puedes abrir solo la subcarpeta `android/` si necesitas tareas de Gradle.
- **Teléfono real:** activa _Opciones de desarrollador ▸ Depuración por USB_, conéctalo y selecciónalo en el selector de dispositivos.

---

## 5. Pruebas y calidad

```bash
flutter analyze     # análisis estático
flutter test        # pruebas automáticas
```

Las pruebas cubren las reglas de gamificación (vidas, racha, XP, repaso), el generador de ejercicios, el desbloqueo
progresivo del mapa, la sesión de práctica, los validadores y dos pruebas de widgets.
`.github/workflows/ci.yml` ejecuta ambos comandos en GitHub Actions si algún día suben el proyecto a un repositorio.

---

## 6. Estructura del proyecto

Arquitectura por capas y por funcionalidades (como indica la ficha):

```
lib/
  core/            tema, router, constantes, validadores, textos legales, widgets compartidos
  features/
    auth/          cuentas y perfil           (domain · data · application · presentation)
    content/       unidades, lecciones, señas (domain · data · application)
    lessons/       motor de lecciones y los 3 ejercicios
    progress/      reglas de gamificación, progreso, insignia
    learn/         mapa de aprendizaje
    notifications/ recordatorios (FCM)
    analytics/     eventos del piloto
    collaborators/ solicitudes de personas sordas colaboradoras
    survey/        encuesta de experiencia
    admin/         validar y publicar lecciones
    profile/ onboarding/ home/
firebase/          reglas de seguridad de Firestore y Storage
test/              pruebas
```

- **Dominio** (`*/domain`): modelos y reglas sin dependencia de Flutter ni Firebase (por eso se prueban fácil).
- **Datos** (`*/data`): repositorios que hablan con Firebase; el resto de la app solo conoce los repositorios.
- **Flujo de una lección:** inicio de sesión → catálogo desde Firestore → videos desde Storage → respuestas → la capa de dominio calcula XP, vidas y racha → se guarda el progreso → Analytics registra el evento.

## 7. Modelo de datos (Firestore)

| Colección                     | Contenido                                                                                            |
| ----------------------------- | ---------------------------------------------------------------------------------------------------- |
| `users/{uid}`                 | alias, correo, `role` (`aprendiz`, `colaborador`, `admin`), foto, aceptación de la política de datos |
| `units/{id}`                  | título, orden, descripción, ícono, dato cultural                                                     |
| `signs/{id}`                  | palabra, unidad, `videoPath`, contexto                                                               |
| `lessons/{id}`                | unidad, título, orden, `signIds`, `validated`, `published`                                           |
| `progress/{uid}`              | XP, racha, vidas, lecciones completadas, señas por repasar, fecha de cierre del recorrido            |
| `encuestas/{id}`              | respuestas de la encuesta de experiencia                                                             |
| `solicitudesColaborador/{id}` | solicitudes de personas sordas colaboradoras (estado: pendiente, aprobada, rechazada)                |

## 8. Reglas de la gamificación

Se pueden ajustar en `lib/core/constants/app_constants.dart`.

- **XP:** 10 por acierto, 20 por completar una lección, +10 si no hubo errores, 5 por cada seña repasada.
- **Vidas:** 5 al inicio; cada error resta una; se recupera una cada 30 minutos. Con 0 vidas la lección se detiene, pero el **repaso no gasta vidas**.
- **Racha:** suma 1 por cada día seguido con práctica; si se salta un día, vuelve a 1.
- **Repaso:** las señas falladas quedan en la lista de repaso y salen de ella cuando se aciertan sin errores.
- **Desbloqueo:** la primera lección no completada está disponible; las siguientes quedan bloqueadas.

---

## 9. Pendientes y decisiones del equipo

- **Textos legales:** los términos de uso y la política de datos (`lib/core/legal/legal_texts.dart`) son **borradores**. Tienen puntos marcados `[POR DEFINIR]` (edad mínima y menores, tiempo de conservación de datos, canal de aviso de cambios). Conviene revisarlos con asesoría jurídica antes de publicar.
- **Contenido real:** las 3 unidades y 25 señas del proyecto son de **ejemplo**. La selección definitiva se hace con personas sordas (Sprint 0). Los datos culturales de cada unidad deben ser creados o validados por ellas.
- **Colaboradores:** el plazo de verificación manual figura como «por definir» en la ficha. El acuerdo de colaboración y la autorización de imagen se gestionan por fuera de la app.
- **Seguridad del progreso:** en el prototipo, el progreso se calcula en la app y se guarda con las reglas de arriba (cada persona solo escribe el suyo). Para una versión pública conviene mover el cálculo a Cloud Functions.
- **Fuera del alcance** (fases posteriores, según la ficha): diccionario completo, sistema de logros, dactilología, ejercicios con cámara o IA, pagos y tutorías en vivo; versión para iPhone y web.

## 10. Solución de problemas

| Síntoma                                  | Qué hacer                                                                                                                    |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `flutter` no se reconoce                 | Agrega la carpeta `flutter/bin` al `Path` y abre una terminal nueva.                                                         |
| La app muestra «Falta conectar Firebase» | Falta el paso 5.6 (`flutterfire configure`). Detén y vuelve a ejecutar la app.                                               |
| Error de `minSdkVersion`                 | Fija `minSdk = 24` en `android/app/build.gradle(.kts)`.                                                                      |
| No aparece ninguna lección               | Faltan lecciones **publicadas**: paso 7 (Administración ▸ Cargar contenido de ejemplo ▸ Modo pruebas) y refresca.            |
| `permission-denied` al leer o escribir   | Publica las reglas de `firebase/` (paso 5.7) y revisa que hayas iniciado sesión.                                             |
| El video no carga                        | En modo pruebas necesita internet. Con videos propios, revisa que el archivo exista en la ruta de `videoPath` y que sea MP4. |
| El botón de Administración no aparece    | Revisa que `users/{tu uid}.role` sea exactamente `admin`.                                                                    |
| No llegan notificaciones                 | Usa un emulador con imagen _Google Play_, acepta el permiso y verifica `POST_NOTIFICATIONS` en el manifiesto.                |
| Falla la primera compilación en Gradle   | Con el proyecto cerrado ejecuta `flutter clean` y luego `flutter pub get`; vuelve a intentar con buena conexión.             |

---

## Contacto

I Love LSC · Pereira, Risaralda, Colombia · love25universal@gmail.com · +57 312 2697240
Equipo: Sandra Patricia Montoya Martínez, Santiago Ospina Calle y Cristian David Guayabo Vizcaya.
