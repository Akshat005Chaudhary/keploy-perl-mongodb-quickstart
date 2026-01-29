# Perl-MongoDB Quickstart

### Clone
```bash
```

### Install Keploy Agent
```bash
curl --silent -O -L https://keploy.io/install.sh && source install.sh
```

## Option 1: Run Without Docker

> App runs locally, DB still in Docker

#### Prerequisites

- Perl installed
- Docker installed
- Keploy installed

### Install cpanm

Ubuntu:
```bash
sudo apt update
sudo apt install cpanminus -y
```
MacOS:
```bash
brew install cpanminus
```
Windows:
```bash
cpan App::cpanminus
```

### Install Dependencies

```bash
cpanm --installdeps .
```

### Start MongoDB
```bash
docker compose up -d mongo
```

### Check Server Health
```bash
perl app.pl daemon -l http://localhost:5000
```
Should say:
```bash
Web application available at http://localhost:5000
```

### Record Tests using Keploy
Before running this command, make sure the server is stopped using `ctrl+C`
```bash
keploy record -c "perl app.pl daemon -l http://localhost:5000"
```

### Testing the APIs (Generate Traffic)

**1. POST /shorten**
```bash
curl -X POST http://localhost:5000/shorten \
  -H "Content-Type: application/json" \
  -d '{"url":"https://keploy.io"}'
```

**2. Redirect Call**

Suppose the received code is `QWERTY`

```bash
curl -v http://localhost:5000/QWERTY
```

**3. Check Stats**
```bash
curl http://localhost:5000/stats/QWERTY
```

**4. Negative Case**
```bash
curl http://localhost:5000/XXXXXX
```

Now stop recording with `ctrl+C`

### Replay Tests using Keploy
```bash
keploy test -c "perl app.pl daemon -l http://localhost:5000"
```

---

## Option 2: With Docker

#### Prerequisite

- Docker
- Keploy

### Run with Docker

When running with Docker Compose, the app must connect to MongoDB using mongo as hostname, not localhost.

```bash
keploy record -c "docker compose up" --container-name=perl-app
```

### Testing the APIs (Generate Traffic)

You can run the same curl commands as above.

### Replay Command

Do not forget to stop with record server first.

```bash
keploy test -c "docker compose up" --container-name=perl-app --delay 10
```

