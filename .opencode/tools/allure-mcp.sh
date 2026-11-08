#!/usr/bin/env bash
# Локальный MCP-сервер для системы управления тестами (в примере — Allure TestOps),
# запускаемый opencode по stdio.
#
# В скрипте нет ни адреса инсталляции, ни токена: адрес приходит из файла
# окружения или переменной, токен читается из файла с правами 600. Поэтому скрипт
# безопасно хранить в репозитории.
#
# Локальные значения берутся из файла, который в репозиторий не попадает:
#   ~/.config/opencode/mcp.env     (путь переопределяется MCP_ALLURE_ENV_FILE)
#
# Переопределяемые переменные:
#   ALLURE_URL            — адрес инсталляции (обязателен)
#   MCP_ALLURE_BIN        — исполняемый файл allure-testops-mcp
#   ALLURE_SECRETS_DIR    — каталог с файлом токена
#   MCP_ALLURE_TOKEN_FILE — файл с API-токеном
#   ALLURE_SSL_VERIFY     — false для самоподписанных сертификатов
#   ALLURE_ENABLE_WRITE   — true включает инструменты записи (по умолчанию true:
#                           они нужны этапу публикации, а кому можно писать,
#                           решают права агентов в .opencode/agents/*.md)
set -euo pipefail

LOCAL_ENV="${MCP_ALLURE_ENV_FILE:-$HOME/.config/opencode/mcp.env}"
if [ -r "$LOCAL_ENV" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$LOCAL_ENV"
    set +a
fi

MCP_ALLURE_BIN="${MCP_ALLURE_BIN:-$HOME/.local/share/mcp/testops/venv/bin/allure-testops-mcp}"
SECRETS_DIR="${ALLURE_SECRETS_DIR:-$HOME/.config/opencode/secrets}"
TOKEN_FILE="${MCP_ALLURE_TOKEN_FILE:-$SECRETS_DIR/testops.token}"

fail() { echo "allure-mcp: $*" >&2; exit 1; }

[ -x "$MCP_ALLURE_BIN" ] || fail "не найден MCP-сервер: $MCP_ALLURE_BIN (установите allure-testops-mcp или задайте MCP_ALLURE_BIN)"
[ -r "$TOKEN_FILE" ] || fail "нет файла токена: $TOKEN_FILE"
[ -n "${ALLURE_URL:-}" ] || fail "не задан адрес системы управления тестами: пропишите ALLURE_URL в $LOCAL_ENV или в окружении"

export ALLURE_URL
export ALLURE_TOKEN="$(tr -d '\r\n' < "$TOKEN_FILE")"
export ALLURE_SSL_VERIFY="${ALLURE_SSL_VERIFY:-true}"
export ALLURE_ENABLE_WRITE="${ALLURE_ENABLE_WRITE:-true}"

exec "$MCP_ALLURE_BIN" "$@"
