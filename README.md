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

### 2. Configurar el flujo en n8n

1. Abre http://localhost:5678 en tu navegador.
2. Crea un nuevo flujo con un trigger de PostgreSQL (o Webhook).
3. Agrega un nodo HTTP Request que apunte a `http://processor:8080/process` con metodo POST.
4. Mapea el payload con la estructura esperada por el procesador.

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
