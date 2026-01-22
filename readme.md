# Mongo DB course

## Comandos

### Conectar con mongosh

```sh
docker exec -it mi-mongo-dev mongosh -u root -p password123 --authenticationDatabase admin
```

### Levantar MongoDB en Docker

```sh
docker compose up -d
```

## Fuentes de datos para prácticas

| Fuente | Uso |
|--------|-----|
| **[A. MongoDB Sample Dataset](#datos-de-ejemplo-mongodb-sample-dataset)** | AirBnB, películas, analíticas, etc. (clon + script) |
| **[B. Mockaroo](#b-mockaroo-datos-sintéticos-masivos)** | "Data basura" masiva (ESR, `userId`, `status`, `createdAt`) |
| **[C. Kaggle](#c-kaggle-ecommerce-redes-sociales-etc)** | Ecommerce, Twitter/X, catálogos (descarga + `import-json.sh` o CSV) |

---

## Datos de ejemplo (MongoDB Sample Dataset)

Datasets de [neelabalan/mongodb-sample-dataset](https://github.com/neelabalan/mongodb-sample-dataset) para prácticas locales (AirBnB, películas, analíticas, etc.).

### Importar datos en tu MongoDB local

1. **Requisitos:** Docker en marcha, `git` instalado.

2. **Ejecutar el script de importación:**

   ```sh
   chmod +x scripts/import-sample-data.sh
   ./scripts/import-sample-data.sh
   ```

   El script:
   - Clona el repo en `data/mongodb-sample-dataset` (o actualiza si ya existe).
   - Levanta `docker compose` si hace falta.
   - Importa todas las colecciones con `mongoimport` en tu contenedor `mi-mongo-dev`.

3. **Probar los datos** (ejemplo con `sample_mflix`):

   ```sh
   docker exec -it mi-mongo-dev mongosh -u root -p password123 --authenticationDatabase admin
   ```

   ```js
   use sample_mflix
   db.movies.findOne()
   ```

### Datasets disponibles

| Dataset | Descripción | Colecciones |
|--------|-------------|-------------|
| `sample_airbnb` | Listados AirBnB | listingsAndReviews |
| `sample_analytics` | App financiera de ejemplo | accounts, customers, transactions |
| `sample_geospatial` | Datos de naufragios | shipwrecks |
| `sample_mflix` | Películas y cines | comments, movies, theaters, users |
| `sample_supplies` | Tienda de material de oficina | sales |
| `sample_training` | Servicios de formación | companies, grades, inspection, posts, routes, stories, trips, tweets, zips |
| `sample_weatherdata` | Informes meteorológicos | data |

---

## B. Mockaroo (datos sintéticos masivos)

[Mockaroo](https://www.mockaroo.com) sirve para generar **"data basura"** a gran escala (p. ej. miles de registros) y probar reglas como **ESR** u otros patrones con datos controlados.

### Configuración recomendada para ESR

1. Entra en **mockaroo.com** y crea un esquema con campos como:
   - `userId` (o `user_id`) — Number o UUID
   - `status` — Custom list: `active`, `inactive`
   - `createdAt` (o `created_at`) — Date
2. Elige **format: JSON** y genera miles de filas (p. ej. 5.000–50.000).
3. Descarga el archivo (Mockaroo devuelve un **array de objetos**).

### Importar en MongoDB

Guarda el JSON (p. ej. en `data/mockaroo/users.json` o en tu `Downloads`) y ejecuta:

```sh
chmod +x scripts/import-json.sh
./scripts/import-json.sh ~/Downloads/users.json --db esr_test --collection users --array --drop
```

- `--array`: necesario porque Mockaroo exporta un **JSON array** de objetos.
- `--drop`: borra la colección antes de importar (opcional).
- `--db` / `--collection`: el nombre de la base y la colección donde quieres los datos.

Luego en `mongosh`:

```js
use esr_test
db.users.createIndex({ status: 1, createdAt: -1 })
db.users.find({ status: "active" }).sort({ createdAt: -1 }).limit(5)
```

---

## C. Kaggle (Ecommerce, redes sociales, etc.)

En [Kaggle Datasets](https://www.kaggle.com/datasets) hay muchos datasets de **Ecommerce**, **Twitter/X** y otros. MongoDB funciona muy bien con catálogos y datos sociales.

### Sugerencia: Ecommerce

- Busca **"Ecommerce"** en [kaggle.com/datasets](https://www.kaggle.com/datasets).
- Ejemplos útiles: **Ecommerce Data**, **Retail/E-commerce**, **E-commerce Dataset** (productos, pedidos, usuarios).

### Cómo usarlos

1. **Descarga manual**: entra en el dataset, **Download** y descomprime (suelen ser CSV).
2. **Si es JSON**: usa `import-json.sh`:
   ```sh
   ./scripts/import-json.sh data/kaggle/ecommerce.json --db kaggle --collection products --array
   ```
3. **Si es CSV**: importa con `mongoimport` dentro del contenedor:
   ```sh
   docker cp ruta/al/archivo.csv mi-mongo-dev:/tmp/data.csv
   docker exec mi-mongo-dev mongoimport -u root -p password123 --authenticationDatabase admin \
     --db kaggle --collection sales --type csv --headerline --file /tmp/data.csv
   ```
4. **Kaggle CLI** (opcional): `pip install kaggle`, configura `~/.kaggle/kaggle.json` y luego:
   ```sh
   kaggle datasets download -d autor/nombre-dataset -p data/kaggle --unzip
   ```
   Después importa los JSON/CSV como arriba.

### Temas útiles en Kaggle

| Búsqueda | Uso típico |
|----------|------------|
| **Ecommerce** | Catálogos, pedidos, recomendaciones |
| **Twitter** / **X** | Tweets, engagement, redes sociales |
| **E-commerce Dataset** | Productos, transacciones, usuarios |