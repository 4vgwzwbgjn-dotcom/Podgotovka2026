# Сборка iOS / IPA

## Самый простой путь для личного iPhone

Откройте `PodgotovkaTestiOS.xcodeproj` на Mac в Xcode → target `PodgotovkaTestiOS` → `Signing & Capabilities` → `Team` → выберите свой Apple Account. Подключите iPhone и нажмите Run.

Это устанавливает приложение непосредственно на ваш iPhone. Платная подписка Apple Developer Program для такого личного тестирования не обязательна, но Personal Team имеет ограничения по сроку действия provisioning.

## Как получить IPA

В Xcode:

1. выберите устройство `Any iOS Device (arm64)`;
2. `Product → Archive`;
3. в Organizer выберите архив;
4. `Distribute App`;
5. для зарегистрированных устройств выберите `Ad Hoc`;
6. выполните подписание и `Export`.

Получится файл `.ipa`.

## GitHub Actions

Для автоматической сборки подписанного IPA в GitHub нужно хранить Apple signing credentials в GitHub Secrets. В репозитории нельзя коммитить `.p12`, приватные ключи или provisioning profiles.

Рекомендуемая схема:

`GitHub → macOS runner → xcodebuild archive → code signing → xcodebuild -exportArchive → IPA artifact`

Для TestFlight вместо Ad Hoc используется App Store Connect.
