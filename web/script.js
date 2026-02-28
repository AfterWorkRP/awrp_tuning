const canvas = document.getElementById('graph');
const ctx = canvas.getContext('2d');

function resizeCanvas() {
    const rect = canvas.getBoundingClientRect();
    canvas.width = rect.width * window.devicePixelRatio;
    canvas.height = rect.height * window.devicePixelRatio;
    ctx.scale(window.devicePixelRatio, window.devicePixelRatio);
}

function drawFake(hp, torque) {
    const w = canvas.getBoundingClientRect().width;
    const h = canvas.getBoundingClientRect().height;
    ctx.clearRect(0, 0, w, h);

    // Oś
    ctx.strokeStyle = "rgba(255, 255, 255, 0.2)";
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(40, 20);
    ctx.lineTo(40, h - 30);
    ctx.lineTo(w - 20, h - 30);
    ctx.stroke();

    // Normalizacja względem 1000 koni
    const peakHp = (hp / 1000) || 0.1;
    const peakTorque = (torque / 1000) || 0.1;

    // Krzywa HP
    ctx.strokeStyle = "rgba(255, 80, 80, 0.9)";
    ctx.lineWidth = 3;
    ctx.beginPath();
    for (let x = 0; x <= w - 80; x += 4) {
        const t = x / (w - 80);
        const y = (Math.sin(t * Math.PI) * peakHp * 0.8 + 0.1) * (h - 80);
        const px = 40 + x;
        const py = (h - 30) - y;
        if (x === 0) ctx.moveTo(px, py);
        else ctx.lineTo(px, py);
    }
    ctx.stroke();

    // Krzywa momentu
    ctx.strokeStyle = "rgba(80, 180, 255, 0.9)";
    ctx.lineWidth = 2;
    ctx.beginPath();
    for (let x = 0; x <= w - 80; x += 4) {
        // Przesunięty peak dla momentu
        const t = (x + 30) / (w - 50); 
        const y = (Math.sin(t * Math.PI) * peakTorque * 0.7 + 0.1) * (h - 80);
        const px = 40 + x;
        const py = (h - 30) - Math.max(0, y);
        if (x === 0) ctx.moveTo(px, py);
        else ctx.lineTo(px, py);
    }
    ctx.stroke();

    document.getElementById('hp').textContent = String(hp);
    document.getElementById('nm').textContent = String(torque);
}

window.addEventListener('message', function(event) {
    if (event.data.type === 'showDyno') {
        const app = document.getElementById('app');
        app.style.display = 'flex'; // Zmieniono na bezpieczniejszy flex
        
        // Czekamy klatkę by wymusić przeliczenie CSS/Fade-in
        setTimeout(() => {
            app.classList.add('visible');
            resizeCanvas();
            drawFake(event.data.hp, event.data.torque);
        }, 10);
    } else if (event.data.type === 'hideDyno') {
        const app = document.getElementById('app');
        app.classList.remove('visible');
        setTimeout(() => app.style.display = 'none', 300);
    }
});

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        const app = document.getElementById('app');
        app.classList.remove('visible');
        setTimeout(() => app.style.display = 'none', 300);
        
        fetch(`https://${GetParentResourceName()}/closeDyno`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({})
        }).catch(err => console.error(err));
    }
});