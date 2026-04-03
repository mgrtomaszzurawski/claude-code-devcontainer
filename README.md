# Claude Code Dev Container

Docker container z Claude Code (Max x20) + full-stack dev tools.

## Co jest w srodku

- **Claude Code** z `--dangerously-skip-permissions` (domyslnie)
- **Java 17** + Maven 3.9.9
- **Node.js 20** + TypeScript, Angular CLI 19
- **DB clients**: PostgreSQL, MySQL
- **Git** + GitHub CLI
- Dostep do hosta przez `host.docker.internal` (SonarQube itp.)

## Szybki start

```bash
# 1. Skopiuj plik konfiguracyjny
cp .env.example .env
# Edytuj .env - ustaw GIT_USER_NAME, GIT_USER_EMAIL

# 2. Zbuduj i uruchom
docker compose up -d --build

# 3. Podlacz sie do kontenera (pierwsze logowanie)
docker attach claude-dev
# -> Kontener odpali `claude login` - otworz URL w przegladarce

# 4. Gotowe - Claude Code startuje automatycznie
```

## Codzienne uzycie

```bash
# Uruchom kontener
docker compose up -d

# Podlacz sie do sesji Claude Code
docker attach claude-dev

# Odlacz sie BEZ zatrzymywania: Ctrl+P, Ctrl+Q

# Otworz drugi terminal (bash)
docker exec -it claude-dev bash

# Zatrzymaj
docker compose down
```

## Praca z kodem

Folder `./workspace/` jest zamontowany jako `/workspace` w kontenerze.

```bash
# Sklonuj repo do workspace/ na hoscie
cd workspace
git clone git@github.com:your-org/your-repo.git

# Albo sklonuj z wnetrza kontenera
docker exec -it claude-dev bash
cd /workspace
git clone https://github.com/your-org/your-repo.git
```

## Dostep do SonarQube (lub innych lokalnych serwisow)

SonarQube dzialajacy na hoscie jest dostepny z kontenera pod adresem:
```
http://host.docker.internal:9000
```

Domyslne dane w `.env`:
```
SONAR_HOST_URL=http://host.docker.internal:9000
SONAR_LOGIN=admin
SONAR_PASSWORD=admin
```

## Transfer plikow

```bash
# Z kontenera na host
docker cp claude-dev:/workspace/file.txt ./file.txt

# Z hosta do kontenera
docker cp ./file.txt claude-dev:/workspace/file.txt
```

Ale lepiej - korzystaj z git push/pull przez workspace.

## Wolumeny (persistentne)

| Wolumen | Sciezka w kontenerze | Cel |
|---------|---------------------|-----|
| `claude-config` | `/home/dev/.claude` | Sesja logowania, config Claude |
| `maven-repo` | `/home/dev/.m2` | Cache Maven (nie sciaga od nowa) |
| `npm-cache` | `/home/dev/.npm` | Cache npm |
| `./workspace` | `/workspace` | Twoj kod (bind mount) |

## Reset sesji Claude

```bash
docker volume rm docker-image-setup_claude-config
```
