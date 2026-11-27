@echo off
REM Requires Flutter on PATH (see README). Do not hardcode a machine-specific SDK path.
where flutter >nul 2>&1
if errorlevel 1 (
  echo Flutter nao encontrado no PATH.
  echo Instale o Flutter SDK e adicione a pasta bin ao PATH, depois reabra o terminal.
  exit /b 1
)

cd /d "%~dp0gerenciamento-obrigacoes-frontend"
if not exist "pubspec.yaml" (
  echo Pasta do frontend nao encontrada. Clone gerenciamento-obrigacoes-frontend nesta raiz.
  exit /b 1
)

flutter run -d chrome %*
