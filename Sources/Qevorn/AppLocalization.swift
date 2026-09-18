import Foundation

enum L10nKey: String, CaseIterable {
    // Brand and navigation
    case brandSubtitle
    case tabContent
    case tabDesign
    case tabLogo
    case tabExport
    case tabProject

    // Common controls and labels
    case preview
    case download
    case save
    case open
    case add
    case remove
    case reset
    case choose
    case cancel
    case done
    case language
    case contentType

    // QR content kinds
    case kindURL
    case kindText
    case kindWiFi
    case kindEmail
    case kindPhone
    case kindSMS
    case kindVCard
    case kindEvent
    case kindLocation

    // Content fields
    case url
    case text
    case networkName
    case password
    case encryption
    case noPassword
    case hiddenNetwork
    case recipient
    case subject
    case message
    case phoneNumber
    case fullName
    case company
    case jobTitle
    case emailAddress
    case website
    case eventTitle
    case startDate
    case endDate
    case eventLocation
    case latitude
    case longitude

    // Design and presets
    case qrStyle
    case presets
    case presetClassic
    case presetMidnight
    case presetOcean
    case presetForest
    case presetSunset
    case qrColor
    case backgroundColor
    case transparentBackground
    case moduleShape
    case shapeSquare
    case shapeRounded
    case shapeDots
    case shapeDiamond
    case finderShape
    case finderSquare
    case finderRounded
    case finderCircle
    case separateFinderColor
    case finderColor
    case errorCorrection
    case quietZone
    case frame
    case noFrame
    case frameText
    case frameColor

    // Logo controls
    case chooseLogo
    case logoFileHint
    case selectedLogo
    case removeLogo
    case logoScale
    case logoPadding
    case logoCard
    case logoCardColor
    case cardRadius
    case circularLogoCard

    // Export and project
    case format
    case fileName
    case size
    case customSize
    case addSize
    case exportQR
    case saveProject
    case openProject
    case resetDefaults
    case csvBatch
    case uploadCSV

    // Quality and statistics
    case qualityControl
    case noCriticalRisk
    case technicalSummary
    case modules
    case darkModules
    case density
    case payloadCharacters
    case pngMemoryEstimate
    case scanReliability

    // Status and starter values
    case statusReady
    case statusUpdatingPreview
    case statusPreviewUpdated
    case statusPreparingExport
    case statusProjectSaved
    case statusProjectOpened
    case statusDecodePassed
    case statusDecodeFailed
    case defaultText
    case defaultEmailSubject
    case defaultEventLocation
    case defaultFileName
}

enum L10n {
    // Columns are English, Turkish, German, Spanish, Danish, Norwegian, Italian, Russian.
    private static let translations: [L10nKey: [String]] = [
        .brandSubtitle: ["Native QR code studio", "Mac için yerel QR stüdyosu", "Natives QR-Studio", "Estudio QR nativo", "Indbygget QR-studie", "Innebygd QR-studio", "Studio QR nativo", "Нативная QR-студия"],
        .tabContent: ["Content", "İçerik", "Inhalt", "Contenido", "Indhold", "Innhold", "Contenuto", "Контент"],
        .tabDesign: ["Design", "Tasarım", "Design", "Diseño", "Design", "Design", "Design", "Дизайн"],
        .tabLogo: ["Logo", "Logo", "Logo", "Logotipo", "Logo", "Logo", "Logo", "Логотип"],
        .tabExport: ["Export", "Dışa aktar", "Export", "Exportar", "Eksportér", "Eksporter", "Esporta", "Экспорт"],
        .tabProject: ["Project", "Proje", "Projekt", "Proyecto", "Projekt", "Prosjekt", "Progetto", "Проект"],
        .preview: ["Preview", "Önizleme", "Vorschau", "Vista previa", "Forhåndsvisning", "Forhåndsvisning", "Anteprima", "Предпросмотр"],
        .download: ["Download", "İndir", "Herunterladen", "Descargar", "Hent", "Last ned", "Scarica", "Скачать"],
        .save: ["Save", "Kaydet", "Sichern", "Guardar", "Gem", "Lagre", "Salva", "Сохранить"],
        .open: ["Open", "Aç", "Öffnen", "Abrir", "Åbn", "Åpne", "Apri", "Открыть"],
        .add: ["Add", "Ekle", "Hinzufügen", "Añadir", "Tilføj", "Legg til", "Aggiungi", "Добавить"],
        .remove: ["Remove", "Kaldır", "Entfernen", "Quitar", "Fjern", "Fjern", "Rimuovi", "Удалить"],
        .reset: ["Reset", "Sıfırla", "Zurücksetzen", "Restablecer", "Nulstil", "Tilbakestill", "Ripristina", "Сбросить"],
        .choose: ["Choose…", "Seç…", "Auswählen …", "Elegir…", "Vælg…", "Velg…", "Scegli…", "Выбрать…"],
        .cancel: ["Cancel", "İptal", "Abbrechen", "Cancelar", "Annuller", "Avbryt", "Annulla", "Отмена"],
        .done: ["Done", "Bitti", "Fertig", "Listo", "Færdig", "Ferdig", "Fine", "Готово"],
        .language: ["Language", "Dil", "Sprache", "Idioma", "Sprog", "Språk", "Lingua", "Язык"],
        .contentType: ["Content type", "İçerik türü", "Inhaltstyp", "Tipo de contenido", "Indholdstype", "Innholdstype", "Tipo di contenuto", "Тип контента"],

        .kindURL: ["Website URL", "Web adresi", "Webadresse", "Dirección web", "Webadresse", "Nettadresse", "Indirizzo web", "Веб-адрес"],
        .kindText: ["Plain text", "Düz metin", "Klartext", "Texto", "Almindelig tekst", "Vanlig tekst", "Testo semplice", "Обычный текст"],
        .kindWiFi: ["Wi-Fi", "Wi-Fi", "WLAN", "Wi-Fi", "Wi-Fi", "Wi-Fi", "Wi-Fi", "Wi-Fi"],
        .kindEmail: ["Email", "E-posta", "E-Mail", "Correo", "E-mail", "E-post", "Email", "Эл. почта"],
        .kindPhone: ["Phone", "Telefon", "Telefon", "Teléfono", "Telefon", "Telefon", "Telefono", "Телефон"],
        .kindSMS: ["SMS", "SMS", "SMS", "SMS", "SMS", "SMS", "SMS", "SMS"],
        .kindVCard: ["Contact card", "Kişi kartı", "Kontaktkarte", "Tarjeta de contacto", "Kontaktkort", "Kontaktkort", "Biglietto da visita", "Визитка"],
        .kindEvent: ["Event", "Etkinlik", "Termin", "Evento", "Begivenhed", "Arrangement", "Evento", "Событие"],
        .kindLocation: ["Location", "Konum", "Standort", "Ubicación", "Placering", "Posisjon", "Posizione", "Местоположение"],

        .url: ["URL", "URL", "URL", "URL", "URL", "URL", "URL", "URL"],
        .text: ["Text", "Metin", "Text", "Texto", "Tekst", "Tekst", "Testo", "Текст"],
        .networkName: ["Network name", "Ağ adı", "Netzwerkname", "Nombre de red", "Netværksnavn", "Nettverksnavn", "Nome rete", "Имя сети"],
        .password: ["Password", "Şifre", "Passwort", "Contraseña", "Adgangskode", "Passord", "Password", "Пароль"],
        .encryption: ["Security", "Güvenlik", "Sicherheit", "Seguridad", "Sikkerhed", "Sikkerhet", "Sicurezza", "Защита"],
        .noPassword: ["No password", "Şifresiz", "Kein Passwort", "Sin contraseña", "Ingen adgangskode", "Uten passord", "Senza password", "Без пароля"],
        .hiddenNetwork: ["Hidden network", "Gizli ağ", "Verstecktes Netzwerk", "Red oculta", "Skjult netværk", "Skjult nettverk", "Rete nascosta", "Скрытая сеть"],
        .recipient: ["Recipient", "Alıcı", "Empfänger", "Destinatario", "Modtager", "Mottaker", "Destinatario", "Получатель"],
        .subject: ["Subject", "Konu", "Betreff", "Asunto", "Emne", "Emne", "Oggetto", "Тема"],
        .message: ["Message", "Mesaj", "Nachricht", "Mensaje", "Besked", "Melding", "Messaggio", "Сообщение"],
        .phoneNumber: ["Phone number", "Telefon numarası", "Telefonnummer", "Número de teléfono", "Telefonnummer", "Telefonnummer", "Numero di telefono", "Номер телефона"],
        .fullName: ["Full name", "Ad soyad", "Vollständiger Name", "Nombre completo", "Fulde navn", "Fullt navn", "Nome completo", "Полное имя"],
        .company: ["Company", "Şirket", "Unternehmen", "Empresa", "Virksomhed", "Firma", "Azienda", "Компания"],
        .jobTitle: ["Job title", "Unvan", "Berufsbezeichnung", "Cargo", "Jobtitel", "Stilling", "Qualifica", "Должность"],
        .emailAddress: ["Email address", "E-posta adresi", "E-Mail-Adresse", "Correo electrónico", "E-mailadresse", "E-postadresse", "Indirizzo email", "Адрес эл. почты"],
        .website: ["Website", "Web sitesi", "Webseite", "Sitio web", "Websted", "Nettsted", "Sito web", "Сайт"],
        .eventTitle: ["Event title", "Etkinlik adı", "Termintitel", "Título del evento", "Begivenhedstitel", "Arrangementstittel", "Titolo evento", "Название события"],
        .startDate: ["Starts", "Başlangıç", "Beginn", "Inicio", "Start", "Start", "Inizio", "Начало"],
        .endDate: ["Ends", "Bitiş", "Ende", "Fin", "Slut", "Slutt", "Fine", "Окончание"],
        .eventLocation: ["Event location", "Etkinlik konumu", "Veranstaltungsort", "Lugar del evento", "Begivenhedssted", "Arrangementssted", "Luogo evento", "Место события"],
        .latitude: ["Latitude", "Enlem", "Breitengrad", "Latitud", "Breddegrad", "Breddegrad", "Latitudine", "Широта"],
        .longitude: ["Longitude", "Boylam", "Längengrad", "Longitud", "Længdegrad", "Lengdegrad", "Longitudine", "Долгота"],

        .qrStyle: ["QR style", "QR stili", "QR-Stil", "Estilo QR", "QR-stil", "QR-stil", "Stile QR", "Стиль QR"],
        .presets: ["Presets", "Hazır tasarımlar", "Vorlagen", "Estilos", "Forudindstillinger", "Forhåndsinnstillinger", "Preimpostazioni", "Пресеты"],
        .presetClassic: ["Classic", "Klasik", "Klassisch", "Clásico", "Klassisk", "Klassisk", "Classico", "Классический"],
        .presetMidnight: ["Midnight", "Gece", "Mitternacht", "Medianoche", "Midnat", "Midnatt", "Mezzanotte", "Полночь"],
        .presetOcean: ["Ocean", "Okyanus", "Ozean", "Océano", "Hav", "Hav", "Oceano", "Океан"],
        .presetForest: ["Forest", "Orman", "Wald", "Bosque", "Skov", "Skog", "Foresta", "Лес"],
        .presetSunset: ["Sunset", "Gün batımı", "Sonnenuntergang", "Atardecer", "Solnedgang", "Solnedgang", "Tramonto", "Закат"],
        .qrColor: ["QR color", "QR rengi", "QR-Farbe", "Color del QR", "QR-farve", "QR-farge", "Colore QR", "Цвет QR"],
        .backgroundColor: ["Background", "Arka plan", "Hintergrund", "Fondo", "Baggrund", "Bakgrunn", "Sfondo", "Фон"],
        .transparentBackground: ["Transparent background", "Şeffaf arka plan", "Transparenter Hintergrund", "Fondo transparente", "Gennemsigtig baggrund", "Gjennomsiktig bakgrunn", "Sfondo trasparente", "Прозрачный фон"],
        .moduleShape: ["Module shape", "Modül şekli", "Modulform", "Forma de módulo", "Modulform", "Modulform", "Forma moduli", "Форма модулей"],
        .shapeSquare: ["Square", "Kare", "Quadratisch", "Cuadrado", "Firkantet", "Kvadratisk", "Quadrato", "Квадрат"],
        .shapeRounded: ["Rounded", "Yuvarlak köşeli", "Abgerundet", "Redondeado", "Afrundet", "Avrundet", "Arrotondato", "Скруглённый"],
        .shapeDots: ["Dots", "Noktalar", "Punkte", "Puntos", "Prikker", "Prikker", "Punti", "Точки"],
        .shapeDiamond: ["Diamond", "Elmas", "Raute", "Rombo", "Diamant", "Diamant", "Diamante", "Ромб"],
        .finderShape: ["Finder shape", "Bulucu şekli", "Suchmuster", "Forma del localizador", "Søgeform", "Finnerform", "Forma del rilevatore", "Форма маркера"],
        .finderSquare: ["Square", "Kare", "Quadratisch", "Cuadrado", "Firkantet", "Kvadratisk", "Quadrato", "Квадрат"],
        .finderRounded: ["Rounded", "Yuvarlak köşeli", "Abgerundet", "Redondeado", "Afrundet", "Avrundet", "Arrotondato", "Скруглённый"],
        .finderCircle: ["Circle", "Daire", "Kreis", "Círculo", "Cirkel", "Sirkel", "Cerchio", "Круг"],
        .separateFinderColor: ["Use separate finder color", "Bulucu rengini ayrı kullan", "Separate Suchfarbe verwenden", "Usar color de localizador distinto", "Brug separat søgefarve", "Bruk egen finnerfarge", "Usa un colore distinto per il rilevatore", "Отдельный цвет маркера"],
        .finderColor: ["Finder color", "Bulucu rengi", "Suchfarbe", "Color del localizador", "Søgefarve", "Finnerfarge", "Colore del rilevatore", "Цвет маркера"],
        .errorCorrection: ["Error correction", "Hata düzeltme", "Fehlerkorrektur", "Corrección de errores", "Fejlkorrektion", "Feilretting", "Correzione errori", "Коррекция ошибок"],
        .quietZone: ["Quiet zone", "Sessiz alan", "Ruhezone", "Zona de silencio", "Stillezone", "Stilleområde", "Area di rispetto", "Свободная зона"],
        .frame: ["Frame", "Çerçeve", "Rahmen", "Marco", "Ramme", "Ramme", "Cornice", "Рамка"],
        .noFrame: ["None", "Yok", "Ohne", "Ninguno", "Ingen", "Ingen", "Nessuna", "Нет"],
        .frameText: ["Frame text", "Çerçeve metni", "Rahmentext", "Texto del marco", "Rammetekst", "Rammetekst", "Testo cornice", "Текст рамки"],
        .frameColor: ["Frame color", "Çerçeve rengi", "Rahmenfarbe", "Color del marco", "Rammefarve", "Rammefarge", "Colore cornice", "Цвет рамки"],

        .chooseLogo: ["Choose logo", "Logo seç", "Logo auswählen", "Elegir logotipo", "Vælg logo", "Velg logo", "Scegli logo", "Выбрать логотип"],
        .logoFileHint: ["PNG, JPG or WebP image", "PNG, JPG veya WebP görseli", "PNG-, JPG- oder WebP-Bild", "Imagen PNG, JPG o WebP", "PNG-, JPG- eller WebP-billede", "PNG-, JPG- eller WebP-bilde", "Immagine PNG, JPG o WebP", "Изображение PNG, JPG или WebP"],
        .selectedLogo: ["Selected logo", "Seçili logo", "Ausgewähltes Logo", "Logotipo seleccionado", "Valgt logo", "Valgt logo", "Logo selezionato", "Выбранный логотип"],
        .removeLogo: ["Remove logo", "Logoyu kaldır", "Logo entfernen", "Quitar logotipo", "Fjern logo", "Fjern logo", "Rimuovi logo", "Удалить логотип"],
        .logoScale: ["Logo scale", "Logo boyutu", "Logo-Größe", "Tamaño del logotipo", "Logostørrelse", "Logostørrelse", "Dimensione logo", "Размер логотипа"],
        .logoPadding: ["Logo padding", "Logo boşluğu", "Logo-Abstand", "Margen del logotipo", "Logomargen", "Logomarg", "Spaziatura logo", "Отступ логотипа"],
        .logoCard: ["Logo card", "Logo kartı", "Logokarte", "Tarjeta del logotipo", "Logokort", "Logokort", "Scheda logo", "Подложка логотипа"],
        .logoCardColor: ["Logo card color", "Logo kartı rengi", "Farbe der Logokarte", "Color de la tarjeta", "Logokortfarve", "Logokortfarge", "Colore scheda logo", "Цвет подложки"],
        .cardRadius: ["Card radius", "Kart köşe yarıçapı", "Kartenradius", "Radio de tarjeta", "Kortradius", "Kortradius", "Raggio scheda", "Скругление подложки"],
        .circularLogoCard: ["Circular logo card", "Dairesel logo kartı", "Runde Logokarte", "Tarjeta circular", "Rundt logokort", "Rundt logokort", "Scheda logo circolare", "Круглая подложка логотипа"],

        .format: ["Format", "Biçim", "Format", "Formato", "Format", "Format", "Formato", "Формат"],
        .fileName: ["File name", "Dosya adı", "Dateiname", "Nombre de archivo", "Filnavn", "Filnavn", "Nome file", "Имя файла"],
        .size: ["Size", "Boyut", "Größe", "Tamaño", "Størrelse", "Størrelse", "Dimensione", "Размер"],
        .customSize: ["Custom size", "Özel boyut", "Eigene Größe", "Tamaño personalizado", "Brugerdefineret størrelse", "Egendefinert størrelse", "Dimensione personalizzata", "Свой размер"],
        .addSize: ["Add size", "Boyut ekle", "Größe hinzufügen", "Añadir tamaño", "Tilføj størrelse", "Legg til størrelse", "Aggiungi dimensione", "Добавить размер"],
        .exportQR: ["Export QR code", "QR kodunu dışa aktar", "QR-Code exportieren", "Exportar código QR", "Eksportér QR-kode", "Eksporter QR-kode", "Esporta codice QR", "Экспортировать QR-код"],
        .saveProject: ["Save project", "Projeyi kaydet", "Projekt sichern", "Guardar proyecto", "Gem projekt", "Lagre prosjekt", "Salva progetto", "Сохранить проект"],
        .openProject: ["Open project", "Proje aç", "Projekt öffnen", "Abrir proyecto", "Åbn projekt", "Åpne prosjekt", "Apri progetto", "Открыть проект"],
        .resetDefaults: ["Reset to defaults", "Varsayılanlara dön", "Auf Standard zurücksetzen", "Restablecer valores", "Nulstil standarder", "Tilbakestill standardvalg", "Ripristina valori predefiniti", "Сбросить настройки"],
        .csvBatch: ["CSV batch export", "CSV toplu dışa aktarma", "CSV-Stapel-Export", "Exportación por lotes CSV", "CSV-eksport i batch", "CSV-eksport i grupper", "Esportazione CSV in blocco", "Пакетный экспорт CSV"],
        .uploadCSV: ["Upload CSV", "CSV yükle", "CSV hochladen", "Subir CSV", "Upload CSV", "Last opp CSV", "Carica CSV", "Загрузить CSV"],

        .qualityControl: ["Quality control", "Kalite kontrolü", "Qualitätskontrolle", "Control de calidad", "Kvalitetskontrol", "Kvalitetskontroll", "Controllo qualità", "Контроль качества"],
        .noCriticalRisk: ["No critical risk detected.", "Kritik bir risk tespit edilmedi.", "Kein kritisches Risiko erkannt.", "No se detectaron riesgos críticos.", "Ingen kritisk risiko fundet.", "Ingen kritisk risiko funnet.", "Nessun rischio critico rilevato.", "Критических рисков не обнаружено."],
        .technicalSummary: ["Technical summary", "Teknik özet", "Technische Übersicht", "Resumen técnico", "Teknisk oversigt", "Teknisk sammendrag", "Riepilogo tecnico", "Техническая сводка"],
        .modules: ["Modules", "Modüller", "Module", "Módulos", "Moduler", "Moduler", "Moduli", "Модули"],
        .darkModules: ["Dark modules", "Koyu modüller", "Dunkle Module", "Módulos oscuros", "Mørke moduler", "Mørke moduler", "Moduli scuri", "Тёмные модули"],
        .density: ["Density", "Yoğunluk", "Dichte", "Densidad", "Tæthed", "Tetthet", "Densità", "Плотность"],
        .payloadCharacters: ["Payload characters", "Veri karakter sayısı", "Payload-Zeichen", "Caracteres de datos", "Datategn", "Datategn", "Caratteri del payload", "Символы данных"],
        .pngMemoryEstimate: ["Estimated PNG memory", "Tahmini PNG belleği", "Geschätzter PNG-Speicher", "Memoria PNG estimada", "Anslået PNG-hukommelse", "Beregnet PNG-minne", "Memoria PNG stimata", "Оценка памяти PNG"],
        .scanReliability: ["Scan reliability", "Tarama güvenilirliği", "Scan-Zuverlässigkeit", "Fiabilidad de lectura", "Scanningspålidelighed", "Skannesikkerhet", "Affidabilità di scansione", "Надёжность сканирования"],

        .statusReady: ["Ready", "Hazır", "Bereit", "Listo", "Klar", "Klar", "Pronto", "Готово"],
        .statusUpdatingPreview: ["Updating preview…", "Önizleme güncelleniyor…", "Vorschau wird aktualisiert …", "Actualizando vista previa…", "Opdaterer forhåndsvisning…", "Oppdaterer forhåndsvisning…", "Aggiornamento anteprima…", "Обновление предпросмотра…"],
        .statusPreviewUpdated: ["Preview updated", "Önizleme güncellendi", "Vorschau aktualisiert", "Vista previa actualizada", "Forhåndsvisning opdateret", "Forhåndsvisning oppdatert", "Anteprima aggiornata", "Предпросмотр обновлён"],
        .statusPreparingExport: ["Preparing export…", "Dışa aktarma hazırlanıyor…", "Export wird vorbereitet …", "Preparando exportación…", "Forbereder eksport…", "Klargjør eksport…", "Preparazione esportazione…", "Подготовка экспорта…"],
        .statusProjectSaved: ["Project saved", "Proje kaydedildi", "Projekt gespeichert", "Proyecto guardado", "Projekt gemt", "Prosjekt lagret", "Progetto salvato", "Проект сохранён"],
        .statusProjectOpened: ["Project opened", "Proje açıldı", "Projekt geöffnet", "Proyecto abierto", "Projekt åbnet", "Prosjekt åpnet", "Progetto aperto", "Проект открыт"],
        .statusDecodePassed: ["QR scan test passed", "QR tarama testi başarılı", "QR-Scan-Test bestanden", "Prueba de lectura QR superada", "QR-scantest bestået", "QR-skannetest bestått", "Test di scansione QR superato", "Проверка QR пройдена"],
        .statusDecodeFailed: ["QR scan test failed", "QR tarama testi başarısız", "QR-Scan-Test fehlgeschlagen", "Falló la prueba de lectura QR", "QR-scantest mislykkedes", "QR-skannetest mislyktes", "Test di scansione QR non superato", "Проверка QR не пройдена"],
        .defaultText: ["A QR code made with Qevorn.", "Qevorn ile oluşturulan QR kodu.", "Ein mit Qevorn erstellter QR-Code.", "Un código QR creado con Qevorn.", "En QR-kode lavet med Qevorn.", "En QR-kode laget med Qevorn.", "Un codice QR creato con Qevorn.", "QR-код, созданный в Qevorn."],
        .defaultEmailSubject: ["Hello", "Merhaba", "Hallo", "Hola", "Hej", "Hei", "Ciao", "Здравствуйте"],
        .defaultEventLocation: ["Istanbul", "İstanbul", "Istanbul", "Estambul", "Istanbul", "Istanbul", "Istanbul", "Стамбул"],
        .defaultFileName: ["qevorn-qr", "qevorn-qr", "qevorn-qr", "qevorn-qr", "qevorn-qr", "qevorn-qr", "qevorn-qr", "qevorn-qr"],
    ]

    private static let warningTranslations: [String: [String]] = [
        "quiet-zone-low": ["Quiet zone is below 4 modules. Some cameras may struggle to scan it.", "Sessiz alan 4 modülün altında. Bazı kameralar kodu okumakta zorlanabilir.", "Die Ruhezone ist kleiner als 4 Module. Einige Kameras können den Code möglicherweise schwer lesen.", "La zona de silencio tiene menos de 4 módulos. Algunas cámaras podrían tener dificultades para leerlo.", "Stillezonen er under 4 moduler. Nogle kameraer kan have svært ved at scanne koden.", "Stilleområdet er under 4 moduler. Noen kameraer kan få problemer med å skanne koden.", "L'area di rispetto è inferiore a 4 moduli. Alcune fotocamere potrebbero avere difficoltà a leggerlo.", "Свободная зона меньше 4 модулей. Некоторым камерам может быть сложно считать код."],
        "contrast-low": ["Foreground and background contrast is low. Try darker or lighter colors.", "Ön plan ve arka plan kontrastı düşük. Daha koyu veya açık renkler deneyin.", "Der Kontrast zwischen Vorder- und Hintergrund ist gering. Verwende dunklere oder hellere Farben.", "Hay poco contraste entre el primer plano y el fondo. Prueba con colores más claros u oscuros.", "Kontrasten mellem forgrund og baggrund er lav. Prøv mørkere eller lysere farver.", "Kontrasten mellom forgrunn og bakgrunn er lav. Prøv mørkere eller lysere farger.", "Il contrasto tra primo piano e sfondo è basso. Prova colori più scuri o più chiari.", "Контраст переднего плана и фона низкий. Попробуйте более тёмные или светлые цвета."],
        "logo-needs-high-ec": ["Large logos are safer with high error correction.", "Büyük logolar için yüksek hata düzeltme düzeyi daha güvenlidir.", "Große Logos sind mit hoher Fehlerkorrektur sicherer.", "Los logotipos grandes son más seguros con una corrección de errores alta.", "Store logoer er mere sikre med høj fejlkorrektion.", "Store logoer er tryggere med høy feilretting.", "I loghi grandi sono più sicuri con un livello elevato di correzione degli errori.", "Для крупных логотипов безопаснее выбрать высокий уровень коррекции ошибок."],
        "logo-too-large": ["The logo covers too much of the QR code and may make it harder to scan.", "Logo QR kodun çok büyük bir bölümünü kaplıyor ve taramayı zorlaştırabilir.", "Das Logo verdeckt zu viel vom QR-Code und kann das Scannen erschweren.", "El logotipo cubre demasiado el código QR y puede dificultar su lectura.", "Logoet dækker for meget af QR-koden og kan gøre den sværere at scanne.", "Logoen dekker for mye av QR-koden og kan gjøre den vanskeligere å skanne.", "Il logo copre una parte eccessiva del codice QR e potrebbe renderne difficile la scansione.", "Логотип закрывает слишком большую часть QR-кода и может затруднить его сканирование."],
        "payload-dense": ["The payload is dense. A shorter URL or less data will make a cleaner QR code.", "Veri yoğun. Daha kısa bir URL veya daha az veri daha temiz bir QR kodu oluşturur.", "Der Payload ist umfangreich. Eine kürzere URL oder weniger Daten ergeben einen übersichtlicheren QR-Code.", "Hay muchos datos. Una URL más corta o menos información dará lugar a un código QR más limpio.", "Datamængden er stor. En kortere URL eller færre data giver en renere QR-kode.", "Datamengden er stor. En kortere URL eller mindre data gir en renere QR-kode.", "Il payload è denso. Un URL più breve o meno dati produrranno un codice QR più pulito.", "Данных много. Более короткий URL или меньший объём данных сделают QR-код чётче."],
        "raster-size-high": ["This is above the raster export limit. SVG is a better choice at this size.", "Bu boyut, raster dışa aktarma sınırını aşıyor. Bu boyutta SVG daha uygundur.", "Diese Größe überschreitet das Raster-Exportlimit. SVG ist hier besser geeignet.", "Este tamaño supera el límite de exportación rasterizada. SVG es más adecuado.", "Størrelsen overskrider grænsen for rastereksport. SVG er bedre egnet her.", "Størrelsen overskrider grensen for rastereksport. SVG passer bedre her.", "Questa dimensione supera il limite di esportazione raster. SVG è più adatto.", "Размер превышает ограничение растрового экспорта. Для него лучше подходит SVG."],
        "frame-small-output": ["Frame text and borders may be too small below 512 px.", "512 pikselin altındaki çıktılarda çerçeve metni ve kenarlıklar çok küçük olabilir.", "Bei Ausgaben unter 512 px können Rahmentext und Ränder zu klein sein.", "El texto y los bordes del marco pueden ser demasiado pequeños por debajo de 512 px.", "Rammetekst og kanter kan være for små ved størrelser under 512 px.", "Rammetekst og kanter kan bli for små ved størrelser under 512 px.", "Il testo e i bordi della cornice potrebbero essere troppo piccoli sotto i 512 px.", "При размере меньше 512 px текст и границы рамки могут оказаться слишком мелкими."],
        "pdf-size-clamped": ["PDF rendering was limited to 4096 px and embedded at high quality.", "PDF oluşturma 4096 piksel ile sınırlandırıldı ve yüksek kalitede eklendi.", "Das PDF-Rendering wurde auf 4096 px begrenzt und in hoher Qualität eingebettet.", "El renderizado PDF se limitó a 4096 px y se incrustó con alta calidad.", "PDF-gengivelsen blev begrænset til 4096 px og indlejret i høj kvalitet.", "PDF-gjengivelsen ble begrenset til 4096 px og lagt inn i høy kvalitet.", "Il rendering PDF è stato limitato a 4096 px e incorporato ad alta qualità.", "Рендеринг PDF ограничен размером 4096 px и встроен с высоким качеством."],
    ]

    private static let translationsByEnglish: [String: [String]] = translations.reduce(into: [:]) { result, entry in
        guard let english = entry.value.first, result[english] == nil else { return }
        result[english] = entry.value
    }

    private static let exactLabels: [String: [String]] = [
        "Native QR studio": ["Native QR studio", "Yerel QR stüdyosu", "Natives QR-Studio", "Estudio QR nativo", "Indbygget QR-studie", "Innebygd QR-studio", "Studio QR nativo", "Нативная QR-студия"],
        "Start": ["Start", "Başlangıç", "Beginn", "Inicio", "Start", "Start", "Inizio", "Начало"],
        "End": ["End", "Bitiş", "Ende", "Fin", "Slut", "Slutt", "Fine", "Окончание"],
        "Title": ["Title", "Başlık", "Titel", "Título", "Titel", "Tittel", "Titolo", "Название"],
        "Payload": ["Payload", "Veri yükü", "Nutzdaten", "Carga útil", "Nyttelast", "Nyttelast", "Payload", "Полезная нагрузка"],
        "Preparing": ["Preparing", "Hazırlanıyor", "Wird vorbereitet", "Preparando", "Forbereder", "Klargjør", "Preparazione", "Подготовка"],
        "Soft": ["Soft", "Yumuşak", "Sanft", "Suave", "Blød", "Myk", "Morbido", "Мягкий"],
        "Modern": ["Modern", "Modern", "Modern", "Moderno", "Moderne", "Moderne", "Moderno", "Современный"],
        "Themes": ["Themes", "Temalar", "Themen", "Temas", "Temaer", "Temaer", "Temi", "Темы"],
        "Frame / template": ["Frame / template", "Çerçeve / şablon", "Rahmen / Vorlage", "Marco / plantilla", "Ramme / skabelon", "Ramme / mal", "Cornice / modello", "Рамка / шаблон"],
        "Project summary": ["Project summary", "Proje özeti", "Projektübersicht", "Resumen del proyecto", "Projektoversigt", "Prosjektoversikt", "Riepilogo progetto", "Сводка проекта"],
        "QR canvas": ["QR canvas", "QR tuvali", "QR-Leinwand", "Lienzo QR", "QR-lærred", "QR-lerret", "Area QR", "Холст QR"],
        "Live preview": ["Live preview", "Canlı önizleme", "Live-Vorschau", "Vista previa en vivo", "Liveforhåndsvisning", "Direkte forhåndsvisning", "Anteprima in tempo reale", "Предпросмотр в реальном времени"],
        "density": ["density", "yoğunluk", "Dichte", "densidad", "tæthed", "tetthet", "densità", "плотность"],
        "Module shape": ["Module shape", "Modül şekli", "Modulform", "Forma de módulo", "Modulform", "Modulform", "Forma moduli", "Форма модулей"],
        "Finder shape": ["Finder shape", "Bulucu şekli", "Suchmuster", "Forma del localizador", "Søgeform", "Finnerform", "Forma del rilevatore", "Форма маркера"],
        "Separate finder color": ["Separate finder color", "Bulucu rengini ayrı kullan", "Separate Suchfarbe verwenden", "Usar color de localizador distinto", "Brug separat søgefarve", "Bruk egen finnerfarge", "Usa un colore distinto per il rilevatore", "Отдельный цвет маркера"],
        "Error correction": ["Error correction", "Hata düzeltme", "Fehlerkorrektur", "Corrección de errores", "Fejlkorrektion", "Feilretting", "Correzione errori", "Коррекция ошибок"],
        "Create": ["Create", "Oluştur", "Erstellen", "Crear", "Opret", "Opprett", "Crea", "Создать"],
        "Appearance": ["Appearance", "Görünüm", "Erscheinungsbild", "Apariencia", "Udseende", "Utseende", "Aspetto", "Оформление"],
        "Output": ["Output", "Çıktı", "Ausgabe", "Salida", "Output", "Utdata", "Output", "Результат"],
        "Colors": ["Colors", "Renkler", "Farben", "Colores", "Farver", "Farger", "Colori", "Цвета"],
        "Frame": ["Frame", "Çerçeve", "Rahmen", "Marco", "Ramme", "Ramme", "Cornice", "Рамка"],
        "Logo": ["Logo", "Logo", "Logo", "Logotipo", "Logo", "Logo", "Logo", "Логотип"],
        "Export": ["Export", "Dışa aktar", "Export", "Exportar", "Eksport", "Eksport", "Esporta", "Экспорт"],
        "CSV batch": ["CSV batch", "CSV toplu işlem", "CSV-Stapel", "Lote CSV", "CSV-batch", "CSV-gruppe", "Batch CSV", "Пакет CSV"],
        "Choose logo": ["Choose logo", "Logo seç", "Logo auswählen", "Elegir logotipo", "Vælg logo", "Velg logo", "Scegli logo", "Выбрать логотип"],
        "PNG · JPEG · WebP, max 5 MB": ["PNG · JPEG · WebP, max 5 MB", "PNG · JPEG · WebP, en fazla 5 MB", "PNG · JPEG · WebP, max. 5 MB", "PNG · JPEG · WebP, máx. 5 MB", "PNG · JPEG · WebP, maks. 5 MB", "PNG · JPEG · WebP, maks. 5 MB", "PNG · JPEG · WebP, max 5 MB", "PNG · JPEG · WebP, не более 5 МБ"],
        "Embedded in QR center": ["Embedded in QR center", "QR kodunun merkezine yerleştirilir", "In der QR-Mitte eingebettet", "Integrado en el centro del QR", "Indlejres i midten af QR-koden", "Bygges inn i QR-kodens midte", "Inserito al centro del QR", "Размещается в центре QR-кода"],
        "Circular logo card": ["Circular logo card", "Dairesel logo kartı", "Runde Logokarte", "Tarjeta circular para el logotipo", "Rundt logokort", "Rundt logokort", "Scheda logo circolare", "Круглая подложка логотипа"],
        "Logo card color": ["Logo card color", "Logo kartı rengi", "Farbe der Logokarte", "Color de la tarjeta del logotipo", "Logokortfarve", "Logokortfarge", "Colore scheda logo", "Цвет подложки логотипа"],
        "Logo scale": ["Logo scale", "Logo boyutu", "Logo-Größe", "Tamaño del logotipo", "Logostørrelse", "Logostørrelse", "Dimensione logo", "Размер логотипа"],
        "Logo padding": ["Logo padding", "Logo boşluğu", "Logo-Abstand", "Margen del logotipo", "Logomargen", "Logomarg", "Spaziatura logo", "Отступ логотипа"],
        "Card radius": ["Card radius", "Kart köşe yarıçapı", "Kartenradius", "Radio de la tarjeta", "Kortradius", "Kortradius", "Raggio scheda", "Радиус скругления карточки"],
        "Place a brand mark in the center of the QR code.": ["Place a brand mark in the center of the QR code.", "QR kodunun ortasına bir marka logosu yerleştirin.", "Platziere ein Markenzeichen in der Mitte des QR-Codes.", "Coloca una marca en el centro del código QR.", "Placér et mærke i midten af QR-koden.", "Plasser en logo i midten av QR-koden.", "Inserisci un marchio al centro del codice QR.", "Разместите логотип в центре QR-кода."],
        "Export sizes": ["Export sizes", "Dışa aktarma boyutları", "Exportgrößen", "Tamaños de exportación", "Eksportstørrelser", "Eksportstørrelser", "Dimensioni esportazione", "Размеры экспорта"],
        "Add size": ["Add size", "Boyut ekle", "Größe hinzufügen", "Añadir tamaño", "Tilføj størrelse", "Legg til størrelse", "Aggiungi dimensione", "Добавить размер"],
        "Run QR decode test": ["Run QR decode test", "QR kodu çözümleme testini çalıştır", "QR-Decodiertest ausführen", "Ejecutar prueba de lectura QR", "Kør QR-afkodningstest", "Kjør QR-dekodingstest", "Esegui test di decodifica QR", "Запустить проверку QR-кода"],
        "Export selected sizes": ["Export selected sizes", "Seçili boyutları dışa aktar", "Ausgewählte Größen exportieren", "Exportar tamaños seleccionados", "Eksportér valgte størrelser", "Eksporter valgte størrelser", "Esporta le dimensioni selezionate", "Экспортировать выбранные размеры"],
        "Multiple sizes are saved together in a folder you choose.": ["Multiple sizes are saved together in a folder you choose.", "Birden fazla boyut, seçtiğiniz klasöre birlikte kaydedilir.", "Mehrere Größen werden gemeinsam in einem Ordner deiner Wahl gespeichert.", "Los tamaños seleccionados se guardan juntos en una carpeta que elijas.", "Flere størrelser gemmes samlet i en mappe, du vælger.", "Flere størrelser lagres samlet i en mappe du velger.", "Più dimensioni vengono salvate insieme in una cartella a tua scelta.", "Несколько размеров будут сохранены вместе в выбранной папке."],
        "Upload CSV": ["Upload CSV", "CSV yükle", "CSV hochladen", "Subir CSV", "Upload CSV", "Last opp CSV", "Carica CSV", "Загрузить CSV"],
        "CSV columns: name,payload or first column as payload": ["CSV columns: name,payload or first column as payload", "CSV sütunları: name,payload veya ilk sütun veri olarak kullanılır", "CSV-Spalten: name,payload oder die erste Spalte als Payload", "Columnas CSV: name,payload o la primera columna como datos", "CSV-kolonner: name,payload eller første kolonne som data", "CSV-kolonner: name,payload eller første kolonne som data", "Colonne CSV: name,payload oppure la prima colonna come payload", "Столбцы CSV: name,payload или данные в первом столбце"],
        "rows ready": ["rows ready", "satır hazır", "Zeilen bereit", "filas listas", "rækker klar", "rader klare", "righe pronte", "строк готово"],
        "Export CSV batch": ["Export CSV batch", "CSV toplu dışa aktar", "CSV-Stapel exportieren", "Exportar lote CSV", "Eksportér CSV-batch", "Eksporter CSV-gruppe", "Esporta batch CSV", "Экспортировать пакет CSV"],
        "Save project as JSON": ["Save project as JSON", "Projeyi JSON olarak kaydet", "Projekt als JSON sichern", "Guardar proyecto como JSON", "Gem projekt som JSON", "Lagre prosjekt som JSON", "Salva progetto come JSON", "Сохранить проект в JSON"],
        "Open JSON project": ["Open JSON project", "JSON projesi aç", "JSON-Projekt öffnen", "Abrir proyecto JSON", "Åbn JSON-projekt", "Åpne JSON-prosjekt", "Apri progetto JSON", "Открыть проект JSON"],
        "Reset to defaults": ["Reset to defaults", "Varsayılanlara dön", "Auf Standard zurücksetzen", "Restablecer valores", "Nulstil standarder", "Tilbakestill standardvalg", "Ripristina valori predefiniti", "Сбросить настройки"],
        "Content": ["Content", "İçerik", "Inhalt", "Contenido", "Indhold", "Innhold", "Contenuto", "Контент"],
        "Unavailable": ["Unavailable", "Kullanılamıyor", "Nicht verfügbar", "No disponible", "Utilgængelig", "Utilgjengelig", "Non disponibile", "Недоступно"],
        "sizes": ["sizes", "boyut", "Größen", "tamaños", "størrelser", "størrelser", "dimensioni", "размеров"],
        "Project files keep your content, QR styling, logo, and export settings together.": ["Project files keep your content, QR styling, logo, and export settings together.", "Proje dosyaları içeriğinizi, QR tasarımınızı, logonuzu ve dışa aktarma ayarlarınızı birlikte saklar.", "Projektdateien speichern Inhalte, QR-Design, Logo und Exporteinstellungen zusammen.", "Los archivos de proyecto guardan juntos el contenido, el diseño QR, el logotipo y los ajustes de exportación.", "Projektfiler samler indhold, QR-design, logo og eksportindstillinger.", "Prosjektfiler samler innhold, QR-design, logo og eksportinnstillinger.", "I file di progetto raccolgono contenuti, stile QR, logo e impostazioni di esportazione.", "В файле проекта вместе хранятся содержимое, оформление QR-кода, логотип и настройки экспорта."],
        "Preparing preview": ["Preparing preview", "Önizleme hazırlanıyor", "Vorschau wird vorbereitet", "Preparando vista previa", "Forbereder forhåndsvisning", "Klargjør forhåndsvisning", "Preparazione anteprima", "Подготовка предпросмотра"],
        "Rendering": ["Rendering", "Oluşturuluyor", "Wird gerendert", "Generando", "Gengiver", "Gjengir", "Rendering", "Рендеринг"],
        "Modules": ["Modules", "Modüller", "Module", "Módulos", "Moduler", "Moduler", "Moduli", "Модули"],
        "Dark modules": ["Dark modules", "Koyu modüller", "Dunkle Module", "Módulos oscuros", "Mørke moduler", "Mørke moduler", "Moduli scuri", "Тёмные модули"],
        "PNG memory estimate": ["PNG memory estimate", "PNG bellek tahmini", "PNG-Speicherschätzung", "Estimación de memoria PNG", "Anslået PNG-hukommelse", "Beregnet PNG-minne", "Stima memoria PNG", "Оценка памяти PNG"],
        "character payload": ["character payload", "karakterlik veri", "Zeichen Payload", "caracteres de datos", "tegn data", "tegn med data", "caratteri di payload", "символов данных"],
        "Ready": ["Ready", "Hazır", "Bereit", "Listo", "Klar", "Klar", "Pronto", "Готово"],
        "Preview updated": ["Preview updated", "Önizleme güncellendi", "Vorschau aktualisiert", "Vista previa actualizada", "Forhåndsvisning opdateret", "Forhåndsvisning oppdatert", "Anteprima aggiornata", "Предпросмотр обновлён"],
        "Decode test is running": ["Decode test is running", "Kod çözme testi çalışıyor", "Decodiertest läuft", "La prueba de lectura está en curso", "Afkodningstesten kører", "Dekodingstesten kjører", "Test di decodifica in corso", "Выполняется проверка кода"],
        "Decode test passed.": ["Decode test passed.", "Kod çözme testi başarılı.", "Decodiertest bestanden.", "La prueba de lectura se superó.", "Afkodningstesten bestod.", "Dekodingstesten bestått.", "Test di decodifica superato.", "Проверка кода пройдена."],
        "Decode test failed.": ["Decode test failed.", "Kod çözme testi başarısız.", "Decodiertest fehlgeschlagen.", "La prueba de lectura falló.", "Afkodningstesten mislykkedes.", "Dekodingstesten mislyktes.", "Test di decodifica non superato.", "Проверка кода не пройдена."],
        "Save cancelled": ["Save cancelled", "Kaydetme iptal edildi", "Speichern abgebrochen", "Guardado cancelado", "Lagring annulleret", "Lagring avbrutt", "Salvataggio annullato", "Сохранение отменено"],
        "Folder selection cancelled": ["Folder selection cancelled", "Klasör seçimi iptal edildi", "Ordnerauswahl abgebrochen", "Selección de carpeta cancelada", "Valg af mappe annulleret", "Mappevalg avbrutt", "Selezione cartella annullata", "Выбор папки отменён"],
        "Choose folder": ["Choose folder", "Klasör seç", "Ordner auswählen", "Elegir carpeta", "Vælg mappe", "Velg mappe", "Scegli cartella", "Выбрать папку"],
        "Pick at least one export size.": ["Pick at least one export size.", "En az bir dışa aktarma boyutu seçin.", "Wähle mindestens eine Exportgröße aus.", "Selecciona al menos un tamaño de exportación.", "Vælg mindst én eksportstørrelse.", "Velg minst én eksportstørrelse.", "Scegli almeno una dimensione di esportazione.", "Выберите хотя бы один размер экспорта."],
    ]

    private static func languageColumn(_ language: AppLanguage) -> Int {
        switch language {
        case .english: return 0
        case .turkish: return 1
        case .german: return 2
        case .spanish: return 3
        case .danish: return 4
        case .norwegian: return 5
        case .italian: return 6
        case .russian: return 7
        }
    }

    static func text(_ key: L10nKey, language: AppLanguage) -> String {
        let column = languageColumn(language)
        guard let values = translations[key], values.indices.contains(column) else {
            return translations[key]?.first ?? key.rawValue
        }
        return values[column]
    }

    static func text(_ english: String, language: AppLanguage) -> String {
        if let values = exactLabels[english] {
            let column = languageColumn(language)
            return values.indices.contains(column) ? values[column] : english
        }
        guard let values = translationsByEnglish[english] else { return english }
        let column = languageColumn(language)
        guard values.indices.contains(column) else { return english }
        return values[column]
    }

    static func warning(_ code: String, language: AppLanguage) -> String {
        guard let values = warningTranslations[code] else { return code }
        let column = languageColumn(language)
        guard values.indices.contains(column) else { return code }
        return values[column]
    }
}
