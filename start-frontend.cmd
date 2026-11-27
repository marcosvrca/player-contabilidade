@echo off
set "PATH=C:\Users\marco\flutter\bin;%PATH%"
cd /d "%~dp0gerenciamento-obrigacoes-frontend"
flutter run -d chrome %*
