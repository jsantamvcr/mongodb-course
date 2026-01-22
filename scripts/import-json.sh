#!/bin/bash
# Importa un archivo JSON (Mockaroo, Kaggle, etc.) en tu MongoDB local.
#
# Uso:
#   ./scripts/import-json.sh <archivo.json> [--db nombre_db] [--collection nombre_coll] [--array] [--drop]
#
# Opciones:
#   --db          Base de datos (default: mockaroo si nombre contiene "mockaroo", sino "imported")
#   --collection  Colección (default: nombre del archivo sin .json)
#   --array       El JSON es un array de objetos (típico de Mockaroo). Usa mongoimport --jsonArray.
#   --drop        Borrar la colección antes de importar.
#
# Ejemplos:
#   ./scripts/import-json.sh ~/Downloads/users.json --db esr_test --collection users --array --drop
#   ./scripts/import-json.sh data/kaggle/ecommerce.json --db kaggle --collection products

set -e

CONTAINER="mi-mongo-dev"
MONGO_USER="${MONGO_USER:-root}"
MONGO_PASS="${MONGO_PASS:-password123}"
DB=""
COLL=""
JSON_ARRAY=""
DROP=""
FILE=""

usage() {
  echo "Uso: $0 <archivo.json> [--db NAME] [--collection NAME] [--array] [--drop]"
  echo ""
  echo "  --db          Base de datos (default: mockaroo o imported)"
  echo "  --collection  Colección (default: nombre del archivo sin .json)"
  echo "  --array       JSON es array de objetos (Mockaroo). Usa --jsonArray."
  echo "  --drop        Borrar colección antes de importar."
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --db)        DB="$2"; shift 2 ;;
    --collection) COLL="$2"; shift 2 ;;
    --array)     JSON_ARRAY="--jsonArray"; shift ;;
    --drop)      DROP="--drop"; shift ;;
    -h|--help)   usage ;;
    -*)          echo "Opción desconocida: $1"; usage ;;
    *)
      if [[ -n "$FILE" ]]; then echo "Solo se admite un archivo."; usage; fi
      FILE="$1"
      shift
      ;;
  esac
done

[[ -z "$FILE" ]] && echo "Falta <archivo.json>." && usage
[[ ! -f "$FILE" ]] && echo "No existe el archivo: $FILE" && exit 1

BASE=$(basename "$FILE" .json)
if [[ -z "$DB" ]]; then
  if [[ "$FILE" == *"mockaroo"* ]] || [[ "$(basename "$(dirname "$FILE")")" == *"mockaroo"* ]]; then
    DB="mockaroo"
  else
    DB="imported"
  fi
fi
[[ -z "$COLL" ]] && COLL="$BASE"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "ERROR: El contenedor '$CONTAINER' no está en ejecución. Ejecuta: docker compose up -d"
  exit 1
fi

REMOTE="/tmp/import-json-$$.json"
echo "==> Importando $FILE → $DB.$COLL"
docker cp "$FILE" "$CONTAINER:$REMOTE"

if docker exec "$CONTAINER" mongoimport \
  --host localhost --port 27017 \
  -u "$MONGO_USER" -p "$MONGO_PASS" --authenticationDatabase admin \
  --db "$DB" --collection "$COLL" \
  --file "$REMOTE" $JSON_ARRAY $DROP; then
  echo "==> Listo. Conectar: docker exec -it $CONTAINER mongosh -u $MONGO_USER -p $MONGO_PASS --authenticationDatabase admin"
  echo "    use $DB; db.$COLL.countDocuments();"
else
  docker exec "$CONTAINER" rm -f "$REMOTE" 2>/dev/null || true
  exit 1
fi
docker exec "$CONTAINER" rm -f "$REMOTE" 2>/dev/null || true
