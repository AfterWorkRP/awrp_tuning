Locales = Locales or {}

Locales['pl'] = {
    -- ==========================================
    -- OGÓLNE I POWIADOMIENIA
    -- ==========================================
    ok = 'OK',
    cancel = 'Anulowano',
    yes = 'Tak',
    no = 'Nie',
    loading = 'Ładowanie...',
    done = 'Sukces',
    error = 'Błąd',
    error_title = 'Błąd',
    busy = 'Montowanie',

    -- ==========================================
    -- TUNING (MONTOWANIE I MENU)
    -- ==========================================
    part_missing = 'Brak przedmiotu: %s',
    install_success = 'Zamontowano część pomyślnie!',
    install_cancel = 'Przerwano montaż.',
    remove_part = 'Zdemontuj część (%s)',
    install_part = 'Wymaga: %s',
    variant = 'Wariant',
    no_options_title = 'Brak opcji',
    no_options_desc = 'Ten pojazd nie posiada modyfikacji tego typu.',
    zone = 'Strefa',
    orders_title = 'Warsztat',
    
    -- Kategorie Menu: Silnik i Przód
    menu_engine = 'Silnik (Ulepszenie)',
    menu_transmission = 'Skrzynia biegów',
    menu_turbo = 'Turbosprężarka',
    hood = 'Maska',
    grille = 'Kratka chłodnicy (Grille)',
    horn = 'Klakson',
    menu_swap = 'Swap Silnika',
    
    -- Kategorie Menu: Koła i Zawieszenie
    menu_suspension = 'Zawieszenie',
    brakes = 'Hamulce',
    menu_wheels = 'Felgi (Sportowe)',
    bulletproof_tires = 'Załóż Opony Kuloodporne',
    menu_drift_tires = 'Załóż Opony do Driftu',
    stock_tires = 'Przywróć Opony Standardowe',
    
    -- Kategorie Menu: Tył
    rear_bumper = 'Zderzak tylny',
    spoiler = 'Spoiler',
    exhaust = 'Wydech',
    roof = 'Dach / Bagażnik',
    
    -- Kategorie Menu: Karoseria i RGB
    front_bumper = 'Zderzak przedni',
    side_skirts = 'Progi (Side Skirts)',
    fenders = 'Błotniki (Fenders)',
    frame = 'Klatka / Podwozie',
    armor = 'Opancerzenie',
    
    window_tint = 'Przyciemnianie szyb',
    tint_level = 'Wybierz poziom folii',
    tint_none = 'Brak (Stock)',
    tint_dark = 'Ciemne (Dark Smoke)',
    tint_medium = 'Średnie (Light Smoke)',
    tint_limo = 'Limo (Najciemniejsze)',
    
    respray = 'Lakierowanie (RGB)',
    respray_menu = 'Mieszalnia lakieru',
    respray_color = 'Nowy kolor główny (Primary)',

    -- ==========================================
    -- TUNER TABLET (ZARZĄDZANIE)
    -- ==========================================
    tablet_title = 'TunerOS - System Zarządzania',
    
    -- Diagnostyka / Hamownia
    tablet_dyno = 'Diagnostyka i Hamownia (OBD)',
    tablet_dyno_desc = 'Podłącz tablet do komputera najbliższego pojazdu, aby zbadać jego osiągi.',
    no_veh_nearby = 'Brak pojazdu w zasięgu Bluetooth/Kabla.',
    
    -- Kalkulator Kosztorysów
    tablet_calc = 'Kalkulator Kosztorysów',
    tablet_calc_desc = 'Oblicz sugerowaną cenę dla klienta na podstawie trudności modyfikacji.',
    calc_parts_cost = 'Łączny koszt części hurtowych ($)',
    calc_difficulty = 'Poziom skomplikowania montażu',
    calc_easy = 'Łatwy (np. Zmiana felg, lakier) - ',
    calc_medium = 'Średni (np. Hamulce, zderzaki)',
    calc_hard = 'Trudny (np. Turbo, zawieszenie)',
    calc_expert = 'Ekspert (np. Engine Swap) - Max ',
    calc_amount = 'Ilość montowanych części',
    calc_summary = '**Koszt samych części:** $%d\n**Sugerowana robocizna:** $%d\n\n**RAZEM DO ZAPŁATY:** $%d',
    calc_result = 'Kosztorys dla Klienta',
    
    -- Zamówienia Hurtowe
    tablet_orders = 'Panel Zamówień Hurtowych',
    tablet_orders_desc = 'Złóż zamówienie na części. System wyśle zlecenie do kurierów/mechaników.',
    order_title = 'Zamówienie Części',
    order_name = 'Nazwa lub Kod Części (np. engine_v8)',
    order_amount = 'Ilość sztuk',
    order_sent = 'Zamówienie wysłane',
    order_sent_desc = 'Zlecenie na %dx %s zostało przekazane do realizacji.',
}