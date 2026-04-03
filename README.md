# Claude Code Dev Container

Docker container z Claude Code (Max x20) + full-stack dev tools.

## Co jest w srodku

- **Claude Code** z `--dangerously-skip-permissions` (domyslnie)
- **Java 17** + Maven 3.9.9
- **Node.js 20** + TypeScript, Angular CLI 19
- **DB clients**: PostgreSQL, MySQL
- **Git** + GitHub CLI (z wrapperem blokujacym destrukcyjne komendy)
- Dostep do hosta przez `host.docker.internal` (SonarQube itp.)

## Szybki start (pierwszy raz)

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
# Ponowne uruchomienie (bez budowania - obraz juz jest)
docker compose up -d
docker attach claude-dev

# Albo jesli kontener jest zatrzymany ale nie usuniety (po exit z claude)
docker compose start
docker attach claude-dev

# Odlacz sie BEZ zatrzymywania: Ctrl+P, Ctrl+Q

# Otworz drugi terminal (bash) OBOK dzialajacego claude
docker exec -it claude-dev bash

# Zatrzymaj kontener
docker compose stop           # zatrzymuje, kontener zostaje (start go wznowi)
docker compose down           # zatrzymuje i usuwa kontener (wolumeny zostaja)
```

### Roznica miedzy stop/down/start/up

| Komenda | Co robi | Kiedy uzywac |
|---------|---------|--------------|
| `docker compose stop` | Zatrzymuje kontener, nie usuwa | Przerwa w pracy |
| `docker compose start` | Wznawia zatrzymany kontener | Wracasz do pracy |
| `docker compose down` | Zatrzymuje i usuwa kontener | Chcesz czysty start |
| `docker compose up -d` | Tworzy i startuje kontener | Po `down` lub pierwszy raz |
| `docker compose up -d --build` | Przebudowuje obraz i startuje | Po zmianach w Dockerfile |

## Wiele terminali naraz

Glowny proces kontenera to Claude Code. Ale mozesz otworzyc dowolna ilosc
dodatkowych sesji bash obok:

```bash
# Terminal 1 - claude (attach do glownego procesu)
docker attach claude-dev

# Terminal 2 - bash (nowy proces w tym samym kontenerze)
docker exec -it claude-dev bash

# Terminal 3 - kolejny bash
docker exec -it claude-dev bash
```

Kazdy `docker exec` to nowy proces w tym samym kontenerze - wspoldzieli
system plikow, siec, zmienne srodowiskowe. Mozna odpalac testy, ogladac logi,
klonowac repo - wszystko rownolegle z claude.

## Czym jest ten kontener

To izolowany Linux (Debian) z zainstalowanymi narzedziami. Nie ma GUI,
pulpitu zdalnego, menadzerow okien. To czyste jadro + shell + narzedzia CLI.
Wchodzisz przez terminal, pracujesz w terminalu.

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

## Wolumeny (persistentne - przezywaja restart i down)

| Wolumen | Sciezka w kontenerze | Cel |
|---------|---------------------|-----|
| `claude-config` | `/home/node/.claude` | Sesja logowania, config Claude |
| `maven-repo` | `/home/node/.m2` | Cache Maven (nie sciaga od nowa) |
| `npm-cache` | `/home/node/.npm` | Cache npm |
| `./workspace` | `/workspace` | Twoj kod (bind mount na dysk hosta) |

## Reset sesji Claude

```bash
docker volume rm claude-code-devcontainer_claude-config
```
