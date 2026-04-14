# Challenge 1 — Sistema de Notificaciones con n8n + FastAPI

## Descripcion

Sistema de automatizacion de notificaciones que integra tres componentes orquestados con Docker Compose:

- **PostgreSQL** — base de datos donde se generan los eventos de notificacion.
- **n8n** — orquestador de flujos de trabajo que escucha eventos en la base de datos y los enruta hacia el procesador.
- **Processor (FastAPI)** — microservicio Python que actua como "Lambda": recibe los eventos, los formatea y devuelve una respuesta estructurada con el estado, mensaje, canal y telefono del usuario.

El flujo general es: un evento ocurre en PostgreSQL → n8n lo detecta y hace un HTTP POST al procesador → el procesador transforma el payload y responde.

## Estructura del proyecto

```
challenge_1/
├── docker-compose.yaml       # Orquestacion de los tres servicios
├── processor/
│   ├── main.py               # API FastAPI con el endpoint /process
│   ├── Dockerfile            # Imagen Python 3.11
│   └── requirements.txt      # Dependencias: fastapi, uvicorn
├── postgres_data/            # Volumen persistente de PostgreSQL
└── n8n_data/                 # Volumen persistente de n8n
```

## Requisitos

- [Docker](https://www.docker.com/) y Docker Compose instalados.

## Uso

### 1. Levantar los servicios

```bash
docker compose up --build
```

Esto inicia los tres contenedores en la red `n8n_network`:

| Servicio   | URL / Puerto          |
|------------|-----------------------|
| PostgreSQL | `localhost:5432`      |
| n8n        | http://localhost:5678 |
| Processor  | http://localhost:8080 |

### 2. Configurar la base de datos

Conéctate a PostgreSQL y ejecuta los scripts SQL **uno por uno**, respetando el siguiente orden:

#### Paso 1 — Crear las tablas (archivo `tables`)

Ejecuta cada sentencia del archivo `tables` de forma individual y en el orden en que aparecen:

1. `CREATE TABLE IF NOT EXISTS public.channels ...`
2. `CREATE TABLE IF NOT EXISTS public.event_users ...`
3. `CREATE TABLE IF NOT EXISTS public.events ...`

> Asegúrate de que cada `CREATE TABLE` finalice correctamente antes de pasar al siguiente, ya que `events` tiene claves foráneas que dependen de `channels` y `event_users`.

#### Paso 2 — Crear la función y el trigger (archivo `trigger`)

Una vez que las tres tablas existan, ejecuta cada sentencia del archivo `trigger` de forma individual y en el orden en que aparecen:

1. `DROP TRIGGER IF EXISTS trg_n8n_trigger ON public.events;`
2. `CREATE OR REPLACE FUNCTION public.notify_n8n_event() ...` (toda la función hasta el `$$ LANGUAGE plpgsql;`)
3. `CREATE TRIGGER trg_n8n_trigger ...`

> No ejecutes el trigger antes de que exista la función, ni la función antes de que existan las tablas.

### 3. Configurar el flujo en n8n

1. Abre http://localhost:5678 en tu navegador.
2. Ve a **Settings → Import** y selecciona el archivo `challenge_1.json` para importar el flujo completo.
3. Una vez importado, configura las credenciales de cada canal directamente en los nodos correspondientes:

   - **PostgreSQL** — ingresa el host (`postgres`), puerto (`5432`), nombre de base de datos (`notifications_system`), usuario y contraseña configurados en el `docker-compose.yaml`.
   - **WhatsApp** — ingresa el token y el número de teléfono de tu cuenta de WhatsApp Business.
   - **Twilio** — ingresa tu `Account SID`, `Auth Token` y el número Twilio desde el que se envían los SMS.
   - **Slack** — ingresa el `Bot Token` y el canal de destino de tu workspace.

4. Activa el flujo con el toggle **Active** en la esquina superior derecha.

### 3. Endpoint del procesador

**POST** `http://localhost:8080/process`

#### Body (JSON)

```json
{
  "channel": {
    "id": 1,
    "name": "whatsapp"
  },
  "user": {
    "phone": "+521234567890"
  },
  "message": "Hola, tu pedido fue confirmado."
}
```

#### Respuesta exitosa

```json
{
  "status": "success",
  "formatted_message": "Hola, tu pedido fue confirmado.",
  "channel": 1,
  "phone": "+521234567890"
}
```

### 4. Detener los servicios

```bash
docker compose down
```

Para eliminar tambien los volumenes de datos:

```bash
docker compose down -v
```

## Variables de entorno (PostgreSQL / n8n)

| Variable                      | Valor por defecto       |
|-------------------------------|-------------------------|
| `POSTGRES_USER`               | `user_admin`            |
| `POSTGRES_PASSWORD`           | `secure_password`       |
| `POSTGRES_DB`                 | `notifications_system`  |
| `N8N_HOST`                    | `localhost`             |
| `N8N_PORT`                    | `5678`                  |

> Cambia las credenciales antes de usar en produccion.
