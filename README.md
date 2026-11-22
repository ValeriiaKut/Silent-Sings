# HandleHero

HandleHero to mobilna aplikacja edukacyjna w formie gry, która wspiera naukę wybranych liter amerykańskiego alfabetu palcowego ASL. Użytkownik poznaje kształty dłoni, rozwiązuje krótkie ćwiczenia i może sprawdzić własny gest przy użyciu kamery telefonu.

Interfejs wykorzystuje estetykę pikselowej gry przygodowej. Nauka jest podzielona na poziomy, a poprawne odpowiedzi prowadzą przez kolejne zadania. Aplikacja zawiera również tryb ćwiczeń z kamerą, słownik znaków, profil użytkownika oraz funkcje społecznościowe.

> HandleHero jest narzędziem do nauki wybranych znaków alfabetu palcowego ASL. Nie tłumaczy pełnych wypowiedzi i nie zastępuje nauki języka migowego.

## Spis treści

- [Najważniejsze funkcje](#najważniejsze-funkcje)
- [Przebieg nauki](#przebieg-nauki)
- [Rozpoznawanie gestów](#rozpoznawanie-gestów)
- [Architektura](#architektura)
- [Technologie](#technologie)
- [Uruchomienie projektu](#uruchomienie-projektu)
- [Testowanie](#testowanie)
- [Struktura katalogów](#struktura-katalogów)
- [Ograniczenia i dalszy rozwój](#ograniczenia-i-dalszy-rozwój)

## Najważniejsze funkcje

- **Mapa nauki** z 12 poziomami: dziewięcioma zwykłymi poziomami i trzema próbami specjalnymi.
- **Fiszki** przedstawiające znaki z danego poziomu.
- **Cztery rodzaje ćwiczeń:** rozpoznawanie litery, wybór znaku dla wskazanej litery, dopasowywanie par oraz uzupełnianie brakującej litery w zdaniu.
- **Mieszana próba** łącząca różne rodzaje ćwiczeń w jednym wyzwaniu.
- **Kamera i klasyfikator gestów** umożliwiające rozpoznawanie wybranych statycznych układów dłoni.
- **System żyć i monet:** błędne odpowiedzi zmniejszają liczbę żyć, a ukończenie poziomu może przyznać monety.
- **Konto użytkownika** z logowaniem i rejestracją przez Firebase Authentication.
- **Profil i synchronizacja salda monet** z wykorzystaniem Cloud Firestore oraz lokalnego cache.
- **Słownik znaków** do przeglądania materiału.
- **Znajomi i prezenty monetowe** między użytkownikami.
- **Tryb ćwiczeń z kamerą**, w którym użytkownik może samodzielnie sprawdzać gesty.

## Przebieg nauki

1. Użytkownik loguje się lub tworzy konto.
2. Na mapie wybiera poziom. Zwykły poziom obejmuje trzy litery; poziom specjalny łączy materiał z kilku poziomów.
3. Na ekranie przeglądu użytkownik może przejrzeć fiszki.
4. Następnie przechodzi przez ćwiczenia i otrzymuje informację zwrotną o odpowiedziach.
5. Za błędy traci życia. Po ich wyczerpaniu może rozpocząć poziom ponownie, wrócić do mapy albo kontynuować, wydając monety.
6. W trybie z kamerą aplikacja pokazuje docelową literę i porównuje ją z rozpoznanym gestem.

Mieszana próba składa się z 16 zadań: po cztery zadania każdego z czterech typów. Zadania i warianty odpowiedzi są losowane na początku próby.

## Rozpoznawanie gestów

Aplikacja analizuje punkty charakterystyczne dłoni wykryte przez bibliotekę `hand_detection`. Z 21 punktów wyliczane są 42 wartości współrzędnych względnych. Cechy są normalizowane względem nadgarstka i skali dłoni; dla lewej dłoni współrzędna pozioma jest odwracana.

Model TensorFlow Lite zapisany w `assets/model.tflite` klasyfikuje gesty liter od A do Y. Wynik jest akceptowany, gdy pewność klasyfikacji osiąga próg 0,35. W strumieniu kamery kolejne predykcje są stabilizowane przez głosowanie z kilku klatek, aby ograniczyć wpływ pojedynczego błędnego odczytu.

Wynik rozpoznawania zależy między innymi od oświetlenia, ułożenia dłoni, odległości od kamery i jakości kamery urządzenia. Aplikacja nie rozpoznaje pełnych zdań w języku migowym.

## Architektura

Aplikacja jest napisana we Flutterze i korzysta z architektury opartej na BLoC do obsługi stanu oraz zdarzeń.

- `HomeBloc` obsługuje stan mapy i saldo monet. Operacje na saldzie są delegowane do `HomeRepository`, którego implementacja Firebase korzysta z Firestore i lokalnego cache.
- `LevelBloc` zarządza życiami, liczbą błędów i resetowaniem poziomu.
- `Exercise1Bloc`–`Exercise4Bloc` obsługują logikę czterech podstawowych ćwiczeń.
- `MixedChallengeBloc` zarządza zadaniami, odpowiedziami i dopasowywaniem par w próbie mieszanej.
- `CameraBloc` koordynuje kamerę, stany jej inicjalizacji, przechwytywanie zdjęcia, cykl życia aplikacji i wyniki rozpoznawania. Komunikacja ze sprzętem odbywa się przez kontrakt `CameraServiceContract`.

Widoki reagują na stany BLoC i wysyłają zdarzenia, na przykład wybór odpowiedzi lub prośbę o ponowną próbę. Firebase Authentication odpowiada za uwierzytelnianie, a Cloud Firestore za synchronizację wybranych danych użytkownika i funkcji społecznościowych.

## Technologie

- Flutter i Dart
- `flutter_bloc` do zarządzania stanem
- Firebase Authentication
- Cloud Firestore
- Shared Preferences do lokalnego cache salda
- Camera plugin do obsługi aparatu
- `hand_detection` do wykrywania dłoni i punktów charakterystycznych
- TensorFlow Lite przez `flutter_litert` do klasyfikacji gestów

## Uruchomienie projektu

### Wymagania

- Flutter SDK zgodny z wersją Dart określoną w `pubspec.yaml` (`^3.10.1`)
- skonfigurowany projekt Firebase z włączonym Firebase Authentication (logowanie e-mail/hasło) i Cloud Firestore
- skonfigurowane pliki Firebase dla Androida i iOS
- urządzenie lub emulator; do sprawdzenia gestów potrzebne jest urządzenie z kamerą

### Kroki

```bash
flutter pub get
flutter run
```

Konfiguracja platform Firebase znajduje się w `lib/firebase_options.dart`, `android/app/google-services.json` i `ios/Runner/GoogleService-Info.plist`. Przy podłączaniu własnego projektu Firebase należy wygenerować lub zaktualizować te pliki oraz upewnić się, że reguły Firestore odpowiadają konfiguracji projektu. Uprawnienie do kamery jest zadeklarowane w konfiguracji Androida i iOS.

## Testowanie

Testy jednostkowe, testy BLoC i testy widgetów można uruchomić poleceniem:

```bash
flutter test
```

Analizę statyczną kodu można uruchomić poleceniem:

```bash
flutter analyze
```

Test integracyjny poziomu należy uruchamiać na skonfigurowanym urządzeniu lub emulatorze:

```bash
flutter test integration_test/level_overview_test.dart
```

Testy nie wymagają prawdziwego konta Firebase ani aktywnej kamery tam, gdzie zewnętrzne usługi są zastępowane testowymi implementacjami. Rozpoznawanie znaków warto dodatkowo sprawdzić na fizycznych urządzeniach.

## Struktura katalogów

```text
lib/
├── bloc/          # BLoC, zdarzenia i stany
├── data/          # katalog poziomów, usługi i repozytoria
├── models/        # modele danych
├── ui/            # ekrany uwierzytelniania, domu, poziomów i ćwiczeń
├── utils/         # narzędzia i niestandardowe rysowanie
└── widgets/       # współdzielone komponenty interfejsu

assets/
├── images/        # grafiki i znaki
└── model.tflite   # model klasyfikacji gestów

test/              # testy jednostkowe, BLoC i widgetów
integration_test/  # testy scenariuszy na urządzeniu
tools/             # skrypt treningu klasyfikatora
```

## Ograniczenia i dalszy rozwój

- Obecny klasyfikator obejmuje litery A–Y. Litery wymagające ruchu, takie jak J i Z, nie są częścią tego zestawu.
- Model może działać gorzej przy słabym oświetleniu, zasłoniętej dłoni lub nietypowym kącie kamery.
- Wyniki klasyfikatora i użyteczność ćwiczeń warto ocenić z udziałem użytkowników oraz na różnych urządzeniach.
- Możliwym kierunkiem rozwoju jest rozszerzenie materiału dydaktycznego, poprawa dostępności, dodanie większej liczby testów integracyjnych oraz analiza skuteczności modelu na przygotowanym zbiorze testowym.

## Licencja

Projekt nie określa obecnie licencji publicznej. Przed dalszym rozpowszechnianiem kodu lub zasobów należy uzupełnić tę sekcję zgodnie z decyzją autorów.
