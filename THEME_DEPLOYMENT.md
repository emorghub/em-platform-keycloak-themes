# Deploying the ReplenixAI Keycloak Theme

This guide covers how to deploy the `replenix` custom login theme to a Keycloak instance
that is already running in Docker but was not originally configured with theme support.

---

## Theme File Structure

```
themes/
└── replenix/
    └── login/
        ├── theme.properties          ← declares parent theme
        ├── login.ftl                 ← custom HTML/FreeMarker login template
        └── resources/
            ├── css/
            │   └── login.css         ← all styling
            └── img/
                └── logo.svg          ← ReplenixAI logo
```

---

## Option A — Mount via Docker Volume (Recommended)

This is the cleanest approach. It mounts the `themes/` folder from your host machine
into the container, so any edits are picked up immediately without rebuilding.

### 1. Copy the `themes/` folder to your server

```bash
scp -r ./themes user@your-server:/opt/keycloak-deploy/themes
```

Or clone/pull your repository on the server if the theme is version-controlled.

### 2. Update your `docker-compose.yml`

Add a volume mount under the `keycloak` service:

```yaml
services:
  keycloak:
    image: quay.io/keycloak/keycloak:26.1.4
    volumes:
      - ./themes:/opt/keycloak/themes   # ← add this line
    # ... rest of your existing config
```

### 3. Recreate the container

```bash
docker compose up -d keycloak
```

> Keycloak automatically discovers any theme folder placed in `/opt/keycloak/themes/`.
> No build step or restart flag is required.

---

## Option B — Copy Files Directly into a Running Container

Use this if you cannot modify the `docker-compose.yml` or need a quick one-off deployment.

### 1. Copy the theme folder into the running container

```bash
docker cp ./themes/replenix <container_name>:/opt/keycloak/themes/replenix
```

Replace `<container_name>` with your actual container name (check with `docker ps`).

### 2. Verify the files landed correctly

```bash
docker exec <container_name> ls /opt/keycloak/themes/replenix/login/
```

Expected output:
```
login.ftl  resources  theme.properties
```

> **Note:** No restart is needed if Keycloak is running in `start-dev` mode (theme cache is
> disabled by default). If running in production mode (`start`), you must restart the
> container after copying — see the Production Mode section below.

---

## Option C — Bake the Theme into a Custom Docker Image

Use this for fully self-contained deployments where you don't want host-mounted volumes.

### 1. Create a `Dockerfile` next to your `themes/` folder

```dockerfile
FROM quay.io/keycloak/keycloak:26.1.4

COPY themes/replenix /opt/keycloak/themes/replenix
```

### 2. Build and tag the image

```bash
docker build -t replenix-keycloak:latest .
```

### 3. Use it in your `docker-compose.yml`

```yaml
services:
  keycloak:
    image: replenix-keycloak:latest
    # ... rest of your existing config
```

### 4. Redeploy

```bash
docker compose up -d keycloak
```

---

## Activating the Theme on a Realm

After the theme files are in place, you must tell Keycloak which realm should use it.

### Via Admin Console (Manual)

1. Open **http://your-server:8080**
2. Log in as admin
3. Select your realm from the top-left dropdown
4. Go to **Realm Settings → Themes**
5. Set **Login Theme** to `replenix`
6. Click **Save**

### Via Keycloak Admin CLI (Scripted)

```bash
# Authenticate
docker exec <container_name> /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin \
  --password <admin_password>

# Apply to the master realm (replace 'master' with your realm name)
docker exec <container_name> /opt/keycloak/bin/kcadm.sh update realms/master \
  -s loginTheme=replenix
```

> **Windows users:** prefix `docker exec` commands with `MSYS_NO_PATHCONV=1` to prevent
> Git Bash from converting the `/opt/keycloak/...` path to a Windows path.

---

## Production Mode Considerations

If the target Keycloak runs in **production mode** (`start` instead of `start-dev`),
theme caching is enabled by default. You have two options:

### Option 1 — Disable theme cache (development/staging only)

Add these environment variables to your `docker-compose.yml`:

```yaml
environment:
  KC_SPI_THEME_CACHE_THEMES: "false"
  KC_SPI_THEME_CACHE_TEMPLATES: "false"
```

### Option 2 — Rebuild Keycloak's optimized image (production)

Keycloak recommends running a `build` step for production to bake in configuration:

```bash
# Inside your Dockerfile or as a build step:
docker run --rm \
  -v ./themes/replenix:/opt/keycloak/themes/replenix \
  quay.io/keycloak/keycloak:26.1.4 build

# Then start with:
docker run ... quay.io/keycloak/keycloak:26.1.4 start
```

---

## Verifying the Theme is Active

```bash
# Should show "replenix"
docker exec <container_name> /opt/keycloak/bin/kcadm.sh get realms/master --fields loginTheme
```

Or open the login page directly in your browser:

```
http://your-server:8080/realms/<realm-name>/protocol/openid-connect/auth?client_id=account&response_type=code&redirect_uri=http%3A%2F%2Fyour-server%3A8080%2Frealms%2F<realm-name>%2Faccount%2F
```

You should see the ReplenixAI branded login page with the dark background and logo watermark.

---

## Dynamic Branding per Client (Option 2)

The theme supports per-client branding driven entirely by **Keycloak client attributes** —
no code changes needed when onboarding a new client.

### How it works

`login.ftl` reads 4 attributes from the client and falls back to ReplenixAI defaults if
any are missing:

```freemarker
<#assign brandName  = (client.attributes['brand.name']!        'ReplenixAI')>
<#assign brandColor = (client.attributes['brand.primaryColor']! '#FD6262')>
<#assign brandSub   = (client.attributes['brand.subtitle']!     'Four steps is all it takes')>
<#assign brandLogo  = (client.attributes['brand.logoUrl']!      url.resourcesPath + '/img/logo.svg')>
```

The color is injected as a CSS variable so every accent (input focus border, icons,
button) updates automatically:

```html
<style>
  :root {
    --primary:       ${brandColor};
    --primary-hover: color-mix(in srgb, ${brandColor} 85%, #000);
  }
</style>
```

### Supported attributes

| Attribute | Description | Example |
|---|---|---|
| `brand.name` | Display name shown as the heading | `AcmeCorp` |
| `brand.primaryColor` | Hex color for button, icons, input focus | `#3B82F6` |
| `brand.subtitle` | Tagline shown below the heading | `Powering enterprise solutions` |
| `brand.logoUrl` | Full URL to an external logo image | `https://cdn.acme.com/logo.svg` |

> `brand.logoUrl` is optional. If omitted, the default ReplenixAI SVG logo is used.

---

## Managing Client Attributes via REST API

Keycloak 26's Admin Console does not expose a generic key/value editor for custom client
attributes. Use the REST API instead.

### Step 1 — Get an admin token

Run this once per session (token expires after a few minutes):

```bash
TOKEN=$(curl -s -X POST "http://<host>:8080/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=<admin_password>&grant_type=password&client_id=admin-cli" \
  | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
```

### Step 2 — Find the client's internal ID

```bash
curl -s "http://<host>:8080/admin/realms/master/clients" \
  -H "Authorization: Bearer $TOKEN" \
  | grep -o '"id":"[^"]*","clientId":"[^"]*"'
```

Note the `id` value for your target client — it is a UUID like `9d6d680e-b1ae-4c2b-82a6-7c22772c05e5`.

### Step 3 — Set brand attributes

```bash
curl -s -X PUT "http://<host>:8080/admin/realms/master/clients/<client-uuid>" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "brand.name":         "AcmeCorp",
      "brand.primaryColor": "#3B82F6",
      "brand.subtitle":     "Powering enterprise solutions"
    }
  }'
```

### Step 4 — Read attributes to verify

```bash
curl -s "http://<host>:8080/admin/realms/master/clients/<client-uuid>" \
  -H "Authorization: Bearer $TOKEN" \
  | grep -o '"brand[^}]*}'
```

Expected output:
```
"brand.name":"AcmeCorp","brand.primaryColor":"#3B82F6","brand.subtitle":"Powering enterprise solutions"
```

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Theme not listed in Admin Console | Files not in `/opt/keycloak/themes/` | Verify with `docker exec <c> ls /opt/keycloak/themes/` |
| Default Keycloak UI still shows | Realm theme not set to `replenix` | Run the `kcadm.sh update` command above |
| CSS loads but old HTML renders | Cached template from a previous deploy | Restart the container or disable theme cache |
| Blank page / FreeMarker error | Template syntax error in `login.ftl` | Check logs with `docker compose logs -f keycloak` |
| JS `${variable}` crashes the page | FreeMarker parses `${}` inside `<script>` | Wrap the script body with `<#noparse>...</#noparse>` |
| Brand attributes not showing | `client.attributes` key typo | Keys are case-sensitive: use `brand.name` not `Brand.Name` |
| `invalid_redirect_uri` error | Redirect URI not in client's allowed list | Add the URI via REST API — see Step 3 above |
| Path conversion error on Windows | Git Bash rewrites `/opt/...` paths | Prefix command with `MSYS_NO_PATHCONV=1` |
