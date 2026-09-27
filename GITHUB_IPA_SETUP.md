# Настройка GitHub для настоящего подписанного IPA

Для `Build signed iOS IPA (Ad Hoc)` нужны Apple Developer credentials. Эти данные **не нужно** помещать в репозиторий.

GitHub Secrets:

- `APPLE_TEAM_ID` — Team ID Apple Developer
- `IOS_CERTIFICATE_P12_BASE64` — Base64 от distribution certificate `.p12`
- `IOS_CERTIFICATE_PASSWORD` — пароль `.p12`
- `IOS_PROVISION_PROFILE_BASE64` — Base64 от Ad Hoc `.mobileprovision`
- `KEYCHAIN_PASSWORD` — произвольный пароль временной связки ключей GitHub runner

Пример Base64 на Mac:

```bash
base64 -i certificate.p12 | pbcopy
base64 -i profile.mobileprovision | pbcopy
```

Затем:

1. GitHub → Settings → Secrets and variables → Actions.
2. Создать указанные Secrets.
3. Проверить, что provisioning profile содержит Bundle ID `com.podgotovka.test2026`.
4. GitHub → Actions → **Build signed iOS IPA (Ad Hoc)** → Run workflow.
5. После успешной сборки открыть Artifacts → `PodgotovkaTestiOS-IPA`.

Ad Hoc IPA устанавливается только на устройства, включённые в provisioning profile.
