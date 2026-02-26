# Скрипт для коммита и пуша в GitHub
# Запуск: .\git-commit-push.ps1
# Перед запуском: создайте репозиторий на GitHub и замените YOUR_USERNAME/YOUR_REPO на свой URL

$repoPath = "c:\myJts\my_new_project"
Set-Location $repoPath

# Инициализация (если ещё не репозиторий)
if (-not (Test-Path ".git")) {
    git init
}

# Добавить remote (замените на свой URL)
# git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Добавить файлы
git add .

# Коммит
git commit -m "Документация проекта: API, BACKEND, README, FEATURES, .gitignore"

# Пуш (первый раз: git push -u origin main)
# git push -u origin main
