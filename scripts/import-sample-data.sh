#!/bin/bash
# Importa los datasets de ejemplo de MongoDB (neelabalan/mongodb-sample-dataset)
# en tu MongoDB local en Docker.
#
# Uso: ./scripts/import-sample-data.sh
#
# Requisitos: Docker en marcha. El script levanta los servicios si hace falta.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_URL="https://github.com/neelabalan/mongodb-sample-dataset.git"
DATA_DIR="$PROJECT_ROOT/data/mongodb-sample-dataset"
CONTAINER="mi-mongo-dev"
MONGO_USER="${MONGO_USER:-root}"
MONGO_PASS="${MONGO_PASS:-password123}"

echo "==> Datos de ejemplo MongoDB → Docker local"
echo "    Origen: $REPO_URL"
echo "    Destino: $CONTAINER (localhost:27017)"
echo ""

# 1. Descargar / actualizar el repo
if [ -d "$DATA_DIR/.git" ]; then
  echo "==> Actualizando datos existentes en $DATA_DIR ..."
  (cd "$DATA_DIR" && git pull --ff-only 2>/dev/null || true)
elif [ -d "$DATA_DIR" ]; then
  echo "==> $DATA_DIR existe pero no es un clon git (p. ej. vacío). Clonando dentro..."
  rmdir "$DATA_DIR" 2>/dev/null || { echo "ERROR: $DATA_DIR no está vacío. Elimínalo o muévelo."; exit 1; }
  mkdir -p "$(dirname "$DATA_DIR")"
  git clone --depth 1 "$REPO_URL" "$DATA_DIR"
else
  echo "==> Clonando $REPO_URL en $DATA_DIR ..."
  mkdir -p "$(dirname "$DATA_DIR")"
  git clone --depth 1 "$REPO_URL" "$DATA_DIR"
fi

# 2. Asegurar que Docker tiene el volumen montado y el contenedor en marcha
echo "==> Comprobando Docker (docker compose up -d)..."
(cd "$PROJECT_ROOT" && docker compose up -d)

until docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; do
  echo "    Esperando a que $CONTAINER esté listo..."
  sleep 2
done
sleep 1

# 3. Importar cada dataset (carpetas sample_*)
echo ""
echo "==> Importando colecciones (mongoimport)..."

for dir in "$DATA_DIR"/sample_*; do
  if [ ! -d "$dir" ]; then
    continue
  fi
  db="$(basename "$dir")"
  echo "    DB: $db"
  for file in "$dir"/*.json; do
    [ -f "$file" ] || continue
    coll="$(basename "$file" .json)"
    echo "      → $coll"
    docker exec "$CONTAINER" mongoimport \
      --drop \
      --host localhost \
      --port 27017 \
      -u "$MONGO_USER" \
      -p "$MONGO_PASS" \
      --authenticationDatabase admin \
      --db "$db" \
      --collection "$coll" \
      --file "/import-data/$(basename "$dir")/$(basename "$file")"
  done
done

echo ""
echo "==> Importación terminada."
echo "    Conectar: docker exec -it $CONTAINER mongosh -u $MONGO_USER -p $MONGO_PASS --authenticationDatabase admin"
echo "    Ejemplo:  use sample_mflix; db.movies.findOne();"
