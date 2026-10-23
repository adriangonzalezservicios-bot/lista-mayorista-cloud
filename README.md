# Lista Mayorista — catálogo sincronizado

Versión preparada a partir del HTML recibido. Conserva los 12 productos originales, sus códigos, precios, cantidades y fotos. Incorpora el WhatsApp **+54 9 11 3367-2920**, armado de pedidos, panel privado de administración, sincronización en tiempo real, almacenamiento de imágenes y backup JSON.

## Qué incluye

- `index.html`: catálogo público y panel de administrador.
- `products.json`: catálogo inicial de 12 productos.
- `assets/`: fotos originales extraídas del HTML y mantenidas como archivos independientes.
- `supabase-schema.sql`: tablas, políticas de seguridad, historial automático de cambios y almacenamiento de imágenes.
- `.github/workflows/pages.yml`: publicación automática con GitHub Pages.

## 1. Crear el proyecto de Supabase

1. Entrá en https://supabase.com/ y creá una cuenta/proyecto nuevo.
2. Guardá en un lugar seguro la contraseña de la base de datos.
3. En el proyecto, abrí **SQL Editor → New query**.
4. Abrí `supabase-schema.sql`, copiá todo el contenido y ejecutalo.
5. En **Project Settings → API** (o Connect, según la interfaz), copiá el **Project URL** y la clave pública **anon/publishable**. Nunca uses `service_role` en este HTML ni la compartas.
6. Editá `index.html` y reemplazá:
   - `PEGAR_SUPABASE_PROJECT_URL` por la URL del proyecto.
   - `PEGAR_SUPABASE_ANON_KEY` por la clave pública anon/publishable.

La clave pública es apta para el navegador solo porque las políticas RLS de la base de datos limitan las escrituras a administradores autorizados. No desactives RLS ni publiques claves secretas.

## 2. Crear tu usuario administrador

1. En Supabase, abrí **Authentication → Users → Add user**.
2. Creá el usuario con tu email y una contraseña fuerte. Desactivá el registro público de usuarios si la opción está habilitada; los revendedores no necesitan cuentas.
3. Copiá el UUID del usuario creado.
4. En **SQL Editor**, ejecutá reemplazando el ejemplo por el UUID real:

```sql
insert into public.admin_users(user_id) values ('UUID_REAL_DEL_USUARIO');
```

Solo los UUID agregados a `admin_users` pueden modificar el catálogo. Si un usuario inicia sesión pero no está en esa tabla, no tendrá acceso al panel.

## 3. Publicar en GitHub Pages

1. En GitHub, creá un repositorio nuevo llamado `lista-mayorista-cloud`.
2. Subí todos los archivos y carpetas de este proyecto a la raíz del repositorio (no subas solo el HTML).
3. Abrí **Settings → Pages** y elegí publicar desde **GitHub Actions** si no queda activado automáticamente.
4. El workflow publica `index.html`, `products.json` y `assets/` en la URL de GitHub Pages.
5. Abrí la URL publicada, probá el catálogo y entrá a Administrador.

La configuración de Supabase queda en el archivo `index.html`, por eso el archivo debe estar configurado antes de publicarlo. Si cambiás la URL o la clave pública, actualizá el archivo y subilo de nuevo.

## 4. Importar el catálogo original

Una vez configurado Supabase y creado tu usuario administrador:

1. Abrí la URL publicada.
2. Entrá a **Administrador** e iniciá sesión.
3. Tocá **Importar catálogo original** únicamente si la tabla de productos está vacía.

La aplicación no sobrescribe productos existentes durante la importación inicial, para evitar reemplazar precios que ya hayas editado.

## 5. Edición y sincronización

En el panel podés agregar productos, editar nombre/código/precio/stock, cargar una imagen o indicar una URL, y eliminar artículos. Los productos se guardan en Supabase. Los navegadores que tengan abierta la lista reciben los cambios mediante Realtime; otros dispositivos los ven al cargar o actualizar la página.

La cantidad `units` se conserva como stock/disponibilidad y también limita las unidades seleccionables en el pedido, igual que en el catálogo original.

## 6. Backup

- **Backup manual:** en el panel, tocá `Descargar backup JSON`. Guardá el archivo en tu computadora y en otra ubicación segura.
- **Historial automático:** el trigger SQL registra cada alta, modificación y eliminación en `product_backups`, incluyendo los valores anteriores y nuevos. Este historial está en el mismo proyecto Supabase; no reemplaza una copia independiente.
- Para ver los registros, en Supabase abrí Table Editor → `product_backups`. No borres la tabla si querés conservar el historial.

Recomendación: descargá un backup JSON después de cada cambio grande y antes de modificar muchos precios.

## Notas importantes

- El HTML funciona en modo local con los datos iniciales si todavía no completaste Supabase, pero en ese modo no hay login funcional ni sincronización. Eso es intencional: no simula guardar datos en la nube.
- El teléfono de pedidos está fijado a `5491133672920` para WhatsApp.
- La lista original dice octubre de 2026; revisá el texto de vigencia cuando cambies los precios.
- Si la página se publica bajo una subruta de GitHub Pages, las rutas `assets/...` y `products.json` son relativas y deberían funcionar desde esa página.
