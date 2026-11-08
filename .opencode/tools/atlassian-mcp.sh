#!/usr/bin/env bash
# Локальный MCP-сервер для системы документации и трекера задач (в примере —
# Jira и Confluence), запускаемый opencode по stdio.
#
# В скрипте нет ни адресов инсталляций, ни токенов: адреса приходят из файла
# окружения или переменных, токены читаются из файлов с правами 600. Поэтому
# скрипт безопасно хранить в репозитории.
#
# Локальные значения берутся из файла, который в репозиторий не попадает:
#   ~/.config/opencode/mcp.env     (путь переопределяется MCP_ATLASSIAN_ENV_FILE)
#
# Переопределяемые переменные:
#   JIRA_URL, CONFLUENCE_URL                       — адреса инсталляций (обязательны)
#   MCP_ATLASSIAN_BIN                              — исполняемый файл mcp-atlassian
#   ATLASSIAN_SECRETS_DIR                          — каталог с файлами токенов
#   MCP_JIRA_TOKEN_FILE, MCP_CONFLUENCE_TOKEN_FILE  — файлы с токенами
#   TOOLSETS                                       — наборы инструментов сервера
#   JIRA_SSL_VERIFY, CONFLUENCE_SSL_VERIFY         — false для самоподписанных сертификатов
set -euo pipefail

LOCAL_ENV="${MCP_ATLASSIAN_ENV_FILE:-$HOME/.config/opencode/mcp.env}"
if [ -r "$LOCAL_ENV" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$LOCAL_ENV"
    set +a
fi

MCP_ATLASSIAN_BIN="${MCP_ATLASSIAN_BIN:-$HOME/.local/share/mcp/atlassian/venv/bin/mcp-atlassian}"
SECRETS_DIR="${ATLASSIAN_SECRETS_DIR:-$HOME/.config/opencode/secrets}"
JIRA_TOKEN_FILE="${MCP_JIRA_TOKEN_FILE:-$SECRETS_DIR/jira.token}"
CONFLUENCE_TOKEN_FILE="${MCP_CONFLUENCE_TOKEN_FILE:-$SECRETS_DIR/confluence.token}"

fail() { echo "atlassian-mcp: $*" >&2; exit 1; }

[ -x "$MCP_ATLASSIAN_BIN" ] || fail "не найден MCP-сервер: $MCP_ATLASSIAN_BIN (установите mcp-atlassian или задайте MCP_ATLASSIAN_BIN)"
[ -r "$JIRA_TOKEN_FILE" ] || fail "нет файла токена трекера: $JIRA_TOKEN_FILE"
[ -r "$CONFLUENCE_TOKEN_FILE" ] || fail "нет файла токена документации: $CONFLUENCE_TOKEN_FILE"
[ -n "${JIRA_URL:-}" ] || fail "не задан адрес трекера: пропишите JIRA_URL в $LOCAL_ENV или в окружении"
[ -n "${CONFLUENCE_URL:-}" ] || fail "не задан адрес документации: пропишите CONFLUENCE_URL в $LOCAL_ENV или в окружении"

export JIRA_URL CONFLUENCE_URL
export JIRA_PERSONAL_TOKEN="$(tr -d '\r\n' < "$JIRA_TOKEN_FILE")"
export CONFLUENCE_PERSONAL_TOKEN="$(tr -d '\r\n' < "$CONFLUENCE_TOKEN_FILE")"

# Наборы инструментов перечислены явно, чтобы состав не менялся при обновлении
# пакета. Нужны только этапам QA: чтение требований, поиск, задачи, комментарии,
# переходы по статусам. Agile-доски, ворклоги, вложения и аналитика не нужны.
export TOOLSETS="${TOOLSETS:-jira_issues,jira_fields,jira_comments,jira_transitions,jira_projects,confluence_pages,confluence_comments}"

exec "$MCP_ATLASSIAN_BIN" "$@"
