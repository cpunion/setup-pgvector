@echo off
setlocal

set PG_VERSION=%1
set PGVECTOR_VERSION=%2
set VS_VERSION=%3

if "%VS_VERSION%"=="2019" (
    call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
) else (
    call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
)

cd %TEMP%
git clone --branch v%PGVECTOR_VERSION% https://github.com/pgvector/pgvector.git
cd pgvector
set PATH=C:\Program Files\PostgreSQL\%PG_VERSION%\bin;C:\Program Files\PostgreSQL\%PG_VERSION%\lib;%PATH%
nmake /NOLOGO /F Makefile.win
nmake /NOLOGO /F Makefile.win install
