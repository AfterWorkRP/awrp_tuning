-- ==========================================
-- FUNKCJE NARZĘDZIOWE (SHARED)
-- ==========================================

AWRPUtils = {}

--- Funkcja usuwająca białe znaki (spacje) z początku i końca stringa.
--- Bardzo przydatna przy tablicach rejestracyjnych w ESX, które często mają ukryte spacje (np. " ABC 123 ").
--- @param s string Ciąg znaków do wyczyszczenia
--- @return string Wyczyszczony ciąg znaków
function AWRPUtils.Trim(s)
    if type(s) ~= 'string' then return s end
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

--- Funkcja do zrzucania zawartości tabel (tzw. dump).
--- Używaj tylko do debugowania, gdy chcesz zobaczyć co zwraca baza danych.
--- @param o any Zmienna/Tabela do wypisania
--- @return string Sformatowany tekst
function AWRPUtils.DumpTable(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. AWRPUtils.DumpTable(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

--- Wypisuje ładnie sformatowany log w konsoli
--- @param msg string Wiadomość
--- @param type string 'info', 'error', 'success'
function AWRPUtils.Log(msg, type)
    local prefix = '^5[awrp_tuning]^7'
    if type == 'error' then
        prefix = '^1[awrp_tuning - BŁĄD]^7'
    elseif type == 'success' then
        prefix = '^2[awrp_tuning - SUKCES]^7'
    end
    
    print(prefix .. ' ' .. tostring(msg))
end