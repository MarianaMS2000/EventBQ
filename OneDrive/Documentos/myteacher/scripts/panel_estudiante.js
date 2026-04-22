/* =============================================
   panel_estudiante.js — Lógica del panel principal
   del estudiante (chat con Manzanita)
   ============================================= */

/* ── CHAT CON MANZANITA ──
   Funciones para enviar mensajes y mostrar respuestas */

/* Cuando el usuario hace click en uno de los chips de opciones rápidas */
function sendChip(btn) {
  var text = btn.textContent;
  /* Ocultamos los chips para que no se vean después de seleccionar uno */
  btn.closest('.chat-chips').style.display = 'none';
  appendUserMessage(text);
  showTyping();
}

/* Cuando el usuario hace click en el botón de enviar */
function sendMessage() {
  var input = document.getElementById('chatInput');
  var text = input.value.trim();
  if (!text) return; /* Si no hay texto, no hacemos nada */
  input.value = ''; /* Limpiamos el input */
  appendUserMessage(text);
  showTyping();
}

/* Escuchamos la tecla Enter en el input del chat */
document.addEventListener('DOMContentLoaded', function () {
  var chatInput = document.getElementById('chatInput');
  if (chatInput) {
    chatInput.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') sendMessage();
    });
  }
});

/* Agrega el mensaje del usuario al chat (burbuja verde) */
function appendUserMessage(text) {
  var body = document.getElementById('chatBody');
  var row = document.createElement('div');
  row.style.cssText = 'display:flex;justify-content:flex-end;margin-bottom:10px;';
  row.innerHTML = '<div style="background:#e8f5e9;border-radius:12px 12px 2px 12px;padding:10px 12px;font-size:.83rem;max-width:200px;">' + text + '</div>';
  body.appendChild(row);
  body.scrollTop = body.scrollHeight; /* Scroll automático hacia abajo */
}

/* Muestra los tres puntitos mientras "Manzanita escribe..." */
function showTyping() {
  var body = document.getElementById('chatBody');
  var typing = document.createElement('div');
  typing.className = 'chat-bubble-row';
  typing.id = 'typingIndicator';
  typing.innerHTML =
    '<div class="chat-bubble-apple"><img src="images/manzana.png" onerror="this.textContent=\'🍎\'"></div>' +
    '<div class="chat-bubble"><div class="typing"><span></span><span></span><span></span></div></div>';
  body.appendChild(typing);
  body.scrollTop = body.scrollHeight;
  /* Después de 1.8 segundos, reemplazamos los puntitos con la respuesta */
  setTimeout(removeTyping, 1800);
}

/* Reemplaza los puntitos de carga con la respuesta de Manzanita */
function removeTyping() {
  var t = document.getElementById('typingIndicator');
  if (t) {
    t.innerHTML =
      '<div class="chat-bubble-apple"><img src="images/manzana.png" onerror="this.textContent=\'🍎\'"></div>' +
      '<div>' +
        '<div style="font-size:.72rem;color:#6b7280;margin-bottom:4px;">Manzanita</div>' +
        '<div class="chat-bubble">Claro, puedo ayudarte con eso. ¿Qué materia te interesa? 📚</div>' +
      '</div>';
    t.removeAttribute('id');
    var body = document.getElementById('chatBody');
    body.scrollTop = body.scrollHeight;
  }
}
