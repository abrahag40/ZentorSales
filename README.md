# ZentorSales · La Biblia del Vendedor

App de campo (un solo archivo HTML, mobile-first, offline) para que los vendedores
de Zentor aprendan el negocio y a vender. Incluye **cuentas de usuario**, **avances
guardados en la nube** y un **panel de equipo** para el administrador.

- `index.html` — la app completa (vanilla JS, sin build).
- `supabase/schema.sql` — base de datos + seguridad para Supabase.

---

## ¿Cómo funciona?

- **Sin configurar nada**, la app funciona igual que antes: 100% offline, los avances
  se guardan solo en ese dispositivo (`localStorage`).
- **Configurando Supabase** (gratis), cada vendedor entra con su correo (enlace mágico,
  sin contraseña), sus avances se sincronizan entre dispositivos, y tú como
  administrador ves el progreso de todo el equipo.

El guardado es **offline-first**: aunque no haya internet, la app sigue funcionando y
sincroniza cuando vuelve la conexión. Lo estudiado nunca se pierde (se fusiona, no se
sobreescribe).

---

## Puesta en marcha (≈10 minutos)

### 1) Crea el proyecto en Supabase
1. Entra a <https://supabase.com> y crea un proyecto gratis.
2. Ve a **SQL Editor → New query**, pega TODO el contenido de
   [`supabase/schema.sql`](supabase/schema.sql) y dale **Run**.

### 2) Conecta la app
1. En Supabase, ve a **Project Settings → API**.
2. Copia **Project URL** y la llave **anon public**.
3. Ábrelas en `index.html`, busca `ZENTOR_CONFIG` (al inicio del `<script>`) y pégalas:
   ```js
   const ZENTOR_CONFIG = {
     SUPABASE_URL:      'https://xxxxxxxx.supabase.co',
     SUPABASE_ANON_KEY: 'eyJhbGci...'
   };
   ```

### 3) Configura el correo de acceso (magic link)
1. En Supabase: **Authentication → Providers → Email** y deja habilitado el acceso por
   enlace (Email OTP / Magic Link).
2. En **Authentication → URL Configuration**, agrega la URL donde publicarás la app
   (la **Site URL** y en **Redirect URLs**), por ejemplo
   `https://tudominio.com/` o tu URL de GitHub Pages.
   > El enlace del correo regresa a esa misma página; por eso debe estar en la lista.

### 4) Publica la app en Vercel
1. Entra a <https://vercel.com> → **Add New → Project** → importa el repo `abrahag40/ZentorSales`.
2. Framework Preset: **Other** (no requiere build; es estático). Deja todo por defecto y **Deploy**.
3. En **Settings → Domains** confirma el dominio `zentor-sales.vercel.app`.
4. Producción se sirve desde la rama **main**, así que asegúrate de fusionar los cambios
   a `main` (o cambia la *Production Branch* en Settings → Git).

> Importante para el acceso por correo: en Supabase → **Authentication → URL Configuration**
> pon **Site URL** = `https://zentor-sales.vercel.app` y en **Redirect URLs** agrega
> `https://zentor-sales.vercel.app/**` (el `**` permite que el enlace regrese con `?nombre=`).

### Links personalizados (saludo "Bienvenido, …")
Agrega `?nombre=` al final del dominio. El nombre se muestra en el inicio y se usa como
nombre del vendedor en tu panel de CEO:

- Alexis  → `https://zentor-sales.vercel.app/?nombre=Alexis`
- Javier  → `https://zentor-sales.vercel.app/?nombre=Javier`
- Gabriela→ `https://zentor-sales.vercel.app/?nombre=Gabriela`

Cada quien entra con su propio correo (magic link); el nombre solo personaliza la
experiencia y el panel.

### 5) Conviértete en administrador
1. Abre la app publicada y entra **una vez** con tu correo (para que se cree tu perfil).
2. En Supabase **SQL Editor**, corre:
   ```sql
   update public.profiles set role = 'admin'
   where email = 'abrahag40@gmail.com';
   ```
3. Recarga la app → en **Mi cuenta** (ícono de persona, arriba a la derecha) verás la
   sección **Equipo** con el avance de cada vendedor.

---

## Datos que se guardan

Tabla `progress`, una fila por usuario:
- `studied` — capítulos estudiados `{ "capId": true }`
- `checks`  — checklist de cierre
- `roi`     — valores de la calculadora de ROI

Tabla `profiles`: `email`, `full_name`, `role` (`vendedor` | `admin`).

La seguridad (RLS) garantiza que cada vendedor solo lee/escribe lo suyo y que **solo
el admin** puede ver a todo el equipo. Un vendedor no puede auto-ascenderse a admin.

---

## Notas
- ¿Cambiar de admin o agregar más? Repite el `update ... set role='admin'` con otro correo.
- ¿Quieres evaluaciones/quizzes por capítulo más adelante? La base ya está lista para
  extenderse (se añadiría una tabla `quiz_results` y vistas de calificación).
