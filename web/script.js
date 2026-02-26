const canvas = document.getElementById('graph');
const ctx = canvas.getContext('2d');

// Rysowanie wykresu i wpisywanie danych
function drawFake(hp, torque) {
  const w = canvas.width, h = canvas.height;
  ctx.clearRect(0, 0, w, h);

  // Osie wykresu
  ctx.strokeStyle = "rgba(255, 255, 255, 0.2)";
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(40, 20);
  ctx.lineTo(40, h - 30);
  ctx.lineTo(w - 20, h - 30);
  ctx.stroke();

  // Krzywa mocy (symulowana funkcja falowa)
  ctx.strokeStyle = "rgba(255, 80, 80, 0.9)";
  ctx.lineWidth = 3;
  ctx.beginPath();
  for (let x = 0; x <= w - 80; x += 4) {
    const t = x / (w - 80);
    const y = (Math.sin(t * Math.PI) * 0.8 + 0.1) * (h - 80);
    const px = 40 + x;
    const py = (h - 30) - y;
    if (x === 0) ctx.moveTo(px, py);
    else ctx.lineTo(px, py);
  }
  ctx.stroke();

  // Wypisujemy faktyczne dane wyliczone przez grę w Lua
  document.getElementById('hp').textContent = String(hp);
  document.getElementById('nm').textContent = String(torque);
}

// ==========================================
// KOMUNIKACJA NUI Z GRĄ (LUA)
// ==========================================

// Odbieranie danych z gry do interfejsu przeglądarki
window.addEventListener('message', function(event) {
    if (event.data.type === 'showDyno') {
        document.getElementById('app').style.display = 'grid'; // Pokaż interfejs
        drawFake(event.data.hp, event.data.torque); // Przekaż zmienne
    }
});

// Zamykanie okna pod klawiszem ESC
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        document.getElementById('app').style.display = 'none'; // Ukryj interfejs
        
        // Wysyłamy sygnał zwrotny do Lua, żeby gra odzyskała focus kamery/myszki
        // Wymagane użycie Backticks (` `) zamiast zwykłych apostrofów!
        fetch(`https://${GetParentResourceName()}/closeDyno`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({})
        }).catch(err => console.error("Błąd podczas zamykania Dyno: ", err));
    }
});