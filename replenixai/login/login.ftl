<#-- ── Dynamic branding from client attributes -->
<#assign brandName    = (client.attributes['brand.name']!        'EnablerMinds')>
<#assign brandColor   = (client.attributes['brand.primaryColor']! 'rgb(253, 98, 98)')>
<#assign brandSub     = (client.attributes['brand.subtitle']!     '')>
<#assign brandLogo    = (client.attributes['brand.logoUrl']!      url.resourcesPath + '/img/logo.svg')>
<!DOCTYPE html>
<html lang="${locale.currentLanguageTag!'en'}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${brandName} – Sign In</title>
  <link rel="stylesheet" href="${url.resourcesPath}/css/login.css">
  <style>
    :root {
      --primary:       ${brandColor};
      --primary-hover: color-mix(in srgb, ${brandColor} 85%, #000);
      --bg-url: url('${url.resourcesPath}/img/bg-pattern-em.png');
    }
  </style>
</head>
<body>
<div class="login-card">

  <div class="logo">
    <img src="${brandLogo}" alt="${brandName} logo">
  </div>

  <#-- ── Language selector (top-right corner) ── -->
  <#if locale?has_content && locale.supported?has_content && (locale.supported?size > 1)>
  <div class="locale-selector">
    <button class="locale-trigger" aria-haspopup="listbox" aria-expanded="false" id="locale-btn">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="12" cy="12" r="10"/>
        <line x1="2" y1="12" x2="22" y2="12"/>
        <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>
      </svg>
      <span>${locale.current}</span>
      <svg class="chevron" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="6 9 12 15 18 9"/>
      </svg>
    </button>
    <ul class="locale-dropdown" role="listbox" aria-labelledby="locale-btn">
      <#list locale.supported as loc>
      <li role="option" <#if loc.label == locale.current>aria-selected="true"</#if>>
        <a href="${loc.url}">${loc.label}</a>
      </li>
      </#list>
    </ul>
  </div>
  </#if>

  <div class="brand">
    <h1>${brandName}</h1>
  </div>

  <#if message?has_content>
    <div class="alert alert-${message.type}">
      ${kcSanitize(message.summary)?no_esc}
    </div>
  </#if>

  <form action="${url.loginAction}" method="post">

    <div class="form-group">
      <label for="username">${msg("username")}</label>
      <div class="input-wrapper">
        <input
          type="text"
          id="username"
          name="username"
          value="${(login.username!'')}"
          placeholder="${msg("username")}"
          autocomplete="username"
          autofocus
        >
        <span class="input-icon">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
            <circle cx="12" cy="7" r="4"/>
          </svg>
        </span>
      </div>
    </div>

    <div class="form-group">
      <label for="password">${msg("password")}</label>
      <div class="input-wrapper">
        <input
          type="password"
          id="password"
          name="password"
          placeholder="${msg("password")}"
          autocomplete="current-password"
        >
        <span class="input-icon">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
            <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
          </svg>
        </span>
      </div>
    </div>

    <input type="hidden" name="credentialId"
      <#if auth?has_content && auth.selectedCredential?has_content>value="${auth.selectedCredential}"</#if>
    />

    <button type="submit" class="btn-login">
      ${msg("doLogIn")}
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/>
        <polyline points="10 17 15 12 10 7"/>
        <line x1="15" y1="12" x2="3" y2="12"/>
      </svg>
    </button>

  </form>

  <#-- ── SSO / Identity providers ── -->
  <#if social?has_content && social.providers?has_content>
  <div class="sso-section">
    <div class="sso-divider">
      <span>${msg("identity-provider-login-label")}</span>
    </div>
    <div class="sso-providers">
      <#list social.providers as provider>
      <a href="${provider.loginUrl}" class="sso-btn" title="${provider.displayName}">
        <#-- Icon by alias (Google, Microsoft, GitHub, etc.) -->
        <#if provider.alias == 'google'>
          <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true">
            <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
            <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
            <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"/>
            <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
          </svg>
        <#elseif provider.alias == 'microsoft' || provider.alias == 'azure'>
          <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true">
            <path fill="#F25022" d="M1 1h10v10H1z"/>
            <path fill="#7FBA00" d="M13 1h10v10H13z"/>
            <path fill="#00A4EF" d="M1 13h10v10H1z"/>
            <path fill="#FFB900" d="M13 13h10v10H13z"/>
          </svg>
        <#elseif provider.alias == 'github'>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0 1 12 6.844a9.59 9.59 0 0 1 2.504.337c1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.02 10.02 0 0 0 22 12.017C22 6.484 17.522 2 12 2z"/>
          </svg>
        <#else>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M18 8h1a4 4 0 0 1 0 8h-1"/>
            <path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z"/>
            <line x1="6" y1="1" x2="6" y2="4"/>
            <line x1="10" y1="1" x2="10" y2="4"/>
            <line x1="14" y1="1" x2="14" y2="4"/>
          </svg>
        </#if>
        <span>${provider.displayName}</span>
      </a>
      </#list>
    </div>
  </div>
  </#if>

</div>

<script>
  const localeBtn = document.getElementById('locale-btn');
  if (localeBtn) {
    const dropdown = localeBtn.closest('.locale-selector').querySelector('.locale-dropdown');
    localeBtn.addEventListener('click', function(e) {
      e.stopPropagation();
      const open = localeBtn.getAttribute('aria-expanded') === 'true';
      localeBtn.setAttribute('aria-expanded', String(!open));
      dropdown.classList.toggle('open', !open);
    });
    document.addEventListener('click', function() {
      localeBtn.setAttribute('aria-expanded', 'false');
      dropdown.classList.remove('open');
    });
  }
</script>
</body>
</html>
