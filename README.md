# codex-limit-saver

Навык для Codex: тратить меньше лимитов на ту же работу и не тормозить на слабом ноутбуке (Windows) или MacBook M5. Основано на замерах другого проекта (Claude Code): главная экономия даёт размер контекста, а не длина ответов.

## Что внутри
| Файл | Зачем |
|---|---|
| `SKILL.md` | правила: сессии (одна задача = одна сессия, когда `/compact`, когда `/new`), гигиена вывода, лёгкий контекст, effort, дисциплина промптов, обратимые эксперименты |
| `references/sessions.md` | таблица «что делать», передача состояния через `PROGRESS.md` |
| `references/weak-hardware.md` | слабый Windows-ноутбук и MacBook M5 |
| `references/experiments-rollback.md` | как менять по одному и откатывать |
| `templates/` | короткий блок для `AGENTS.md`, шаблоны `PROGRESS.md` и `EXPERIMENTS.md`, `.ignore` |
| `scripts/install.sh` | установка и удаление навыка и настроек с бэкапом |
| `scripts/checkpoint.sh` | снимок проекта перед рискованным экспериментом и откат |

## Установка
Нужны `git` и `bash`. На Windows bash есть в «Git for Windows» (Git Bash): запускайте команды в нём.

```bash
bash scripts/install.sh install --dry-run
```
```bash
bash scripts/install.sh install
```
Что делает: копирует навык в `~/.agents/skills/codex-limit-saver`, добавляет короткий блок в `~/.codex/AGENTS.md` и `tool_output_token_limit = 5000` в `~/.codex/config.toml`. Всё добавленное стоит между маркерами. Оригиналы сначала копируются в `~/.codex/backups/codex-limit-saver-<время>/`. Если ключ уже задан вами, он не трогается.

Порог авто-компакции задайте после просмотра окна модели в `/status` (примерно 40 % окна):
```bash
bash scripts/install.sh install --compact-limit 120000
```
Если ваша версия Codex ищет навыки в `~/.codex/skills`, скопируйте папку туда.

## Откат
```bash
bash scripts/install.sh uninstall
```
Убирает только наши блоки и навык. Полный возврат файлов из бэкапа: `bash scripts/install.sh restore <папка-бэкапа>`.

## Безопасные эксперименты в проекте
```bash
bash scripts/checkpoint.sh save exp-1
```
```bash
bash scripts/checkpoint.sh restore exp-1
```
Снимок не меняет ветки и рабочие файлы, включает новые (неигнорируемые) файлы. Перед откатом текущее состояние тоже сохраняется, поэтому и откат можно отменить. Остальные команды: `list`, `diff NAME`, `drop NAME`.

## Что проверено
- `install` / `uninstall` / повторная установка и `checkpoint` (save, diff, restore, отмена отката) прогнаны на macOS в песочнице с подменённым `HOME`: файлы после удаления идентичны исходным.
- Имена ключей `model_auto_compact_token_limit`, `tool_output_token_limit` сверены с документацией Codex (16.11.2026).
- Не проверено: запуск на Windows (Git Bash), реальное поведение Codex после установки, размер экономии. Измерьте по `EXPERIMENTS.md` на 3+ задачах.
- Команды `/new`, `/compact`, `/status`, `/mcp` указаны по документации; если в вашей версии отличаются, смотрите `/help`.
