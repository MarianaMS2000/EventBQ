/* =============================================
   panel_estudiante.js — Lógica del panel principal
   del estudiante. Chat con Manzanita usando la
   API REAL de Anthropic (claude-sonnet-4-20250514)
   ============================================= */

/* ── HISTORIAL DE CONVERSACIÓN ──
   Guardamos todos los mensajes para mantener el
   contexto en las llamadas a la API */
var conversacionHistorial = [];

/* ── ESTADO DEL CHAT ──
   Flag para evitar enviar mientras se espera respuesta */
var esperandoRespuesta = false;

/* ══════════════════════════════════════════════
   EVENTOS DE INICIALIZACIÓN
   ══════════════════════════════════════════════ */
document.addEventListener('DOMContentLoaded', function () {
  /* Escuchamos Enter en el input del chat */
  var chatInput = document.getElementById('chatInput');
  if (chatInput) {
    chatInput.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        enviarMensaje();
      }
    });
  }
});

/* ══════════════════════════════════════════════
   CHAT CON MANZANITA — INTERFAZ DE USUARIO
   ══════════════════════════════════════════════ */

/**
 * Maneja el click en los chips de opciones rápidas.
 * El texto del chip se envía como si fuera un mensaje del usuario.
 * @param {HTMLElement} btn - El chip que fue presionado
 */
function sendChip(btn) {
  var text = btn.textContent.trim();
  /* Ocultamos los chips para que no se repitan */
  var chips = btn.closest('.chat-chips');
  if (chips) chips.style.display = 'none';
  procesarMensajeUsuario(text);
}

/**
 * Compatibilidad con el atributo onclick="sendMessage()" del HTML.
 */
function sendMessage() {
  enviarMensaje();
}

/**
 * Recoge el texto del input, lo valida y lo procesa.
 */
function enviarMensaje() {
  if (esperandoRespuesta) return;
  var input = document.getElementById('chatInput');
  var text = input ? input.value.trim() : '';
  if (!text) return;
  input.value = '';
  procesarMensajeUsuario(text);
}

/**
 * Muestra el mensaje del usuario en la burbuja verde,
 * lo agrega al historial y solicita respuesta a la IA.
 * @param {string} text - Texto del mensaje del usuario
 */
function procesarMensajeUsuario(text) {
  conversacionHistorial.push({ role: 'user', content: text });
  agregarBurbujaUsuario(text);
  pedirRespuestaManzanita();
}

/**
 * Inserta una burbuja de mensaje del usuario (verde) en el chat.
 * @param {string} text - Texto a mostrar
 */
function agregarBurbujaUsuario(text) {
  var body = document.getElementById('chatBody');
  if (!body) return;
  var row = document.createElement('div');
  row.style.cssText = 'display:flex;justify-content:flex-end;margin-bottom:10px;';
  row.innerHTML =
    '<div style="background:#e8f5e9;border-radius:12px 12px 2px 12px;' +
    'padding:10px 12px;font-size:.83rem;max-width:200px;line-height:1.4;">' +
    escapeHtmlChat(text) + '</div>';
  body.appendChild(row);
  body.scrollTop = body.scrollHeight;
}

/* ══════════════════════════════════════════════
   INTEGRACIÓN REAL CON LA API DE ANTHROPIC
   Usa claude-sonnet-4-20250514 para generar
   respuestas contextuales como Manzanita
   ══════════════════════════════════════════════ */

/**
 * Llama a la API de Anthropic para obtener la respuesta de Manzanita.
 * Muestra indicador de escritura mientras espera.
 * Maneja errores de red y de autenticación.
 */
async function pedirRespuestaManzanita() {
  esperandoRespuesta = true;

  var apiKey = localStorage.getItem('mt_api_key');
  if (!apiKey) {
    apiKey = prompt(
      'Para activar a Manzanita ingresa tu clave API de Anthropic:\n(Empieza con sk-ant-...)'
    );
    if (!apiKey || !apiKey.trim().startsWith('sk-ant-')) {
      mostrarRespuestaSimulada();
      esperandoRespuesta = false;
      return;
    }
    localStorage.setItem('mt_api_key', apiKey.trim());
  }

  var typingId = mostrarIndicadorEscritura();

  try {
    var response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-dangerous-direct-browser-access': 'true'
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 300,
        system:
          'Eres Manzanita, la asistente virtual amigable de myTeacher, ' +
          'una plataforma de tutorias en linea. Tu personalidad es calida, ' +
          'motivadora y educativa. Ayudas a estudiantes a: encontrar tutores, ' +
          'resolver dudas academicas basicas, y navegar la plataforma. ' +
          'SIEMPRE responde en espanol. ' +
          'Mantén respuestas cortas y conversacionales (maximo 2-3 oraciones). ' +
          'Usa un emoji ocasionalmente para ser mas cercana. ' +
          'Si el estudiante necesita ayuda academica profunda, recomiéndale ' +
          'buscar un tutor en la plataforma.',
        messages: conversacionHistorial
      })
    });

    if (!response.ok) {
      var errData = await response.json().catch(function () { return {}; });
      throw new Error((errData.error && errData.error.message) || 'Error HTTP ' + response.status);
    }

    var data = await response.json();
    var respuestaTexto = '';
    if (data.content && data.content.length > 0) {
      data.content.forEach(function (block) {
        if (block.type === 'text') respuestaTexto += block.text;
      });
    }
    if (!respuestaTexto) throw new Error('Respuesta vacia');

    conversacionHistorial.push({ role: 'assistant', content: respuestaTexto });
    reemplazarIndicadorEscritura(typingId, respuestaTexto);

  } catch (error) {
    console.error('Error en la API de Anthropic:', error);
    if (error.message && error.message.includes('401')) {
      localStorage.removeItem('mt_api_key');
    }
    reemplazarIndicadorEscritura(typingId,
      'Ups, tuve un problemita tecnico. Intenta de nuevo en un momento.'
    );
  }

  esperandoRespuesta = false;
}

/**
 * Fallback sin API key: respuesta genérica simulada.
 */
function mostrarRespuestaSimulada() {
  var typingId = mostrarIndicadorEscritura();
  setTimeout(function () {
    reemplazarIndicadorEscritura(typingId,
      'Claro, puedo ayudarte con eso. Que materia te interesa?'
    );
    esperandoRespuesta = false;
  }, 1400);
}

/* ══════════════════════════════════════════════
   ANIMACIONES DEL CHAT
   ══════════════════════════════════════════════ */

/**
 * Muestra el indicador de "tres puntitos" mientras espera la IA.
 * @returns {string} ID único del indicador creado
 */
function mostrarIndicadorEscritura() {
  var body = document.getElementById('chatBody');
  if (!body) return '';
  var id = 'typing-' + Date.now();
  var div = document.createElement('div');
  div.className = 'chat-bubble-row';
  div.id = id;
  div.innerHTML =
    '<div class="chat-bubble-apple">' +
      '<img src="images/manzana.png" onerror="this.textContent=\'\'>">' +
    '</div>' +
    '<div class="chat-bubble">' +
      '<div class="typing"><span></span><span></span><span></span></div>' +
    '</div>';
  body.appendChild(div);
  body.scrollTop = body.scrollHeight;
  return id;
}

/**
 * Reemplaza el indicador de escritura con la respuesta de la IA.
 * @param {string} typingId  - ID del elemento indicador
 * @param {string} respuesta - Texto de la respuesta
 */
function reemplazarIndicadorEscritura(typingId, respuesta) {
  var elem = document.getElementById(typingId);
  var body = document.getElementById('chatBody');
  if (!elem || !body) return;
  elem.innerHTML =
    '<div class="chat-bubble-apple">' +
      '<img src="images/manzana.png" onerror="this.textContent=\'\'>">' +
    '</div>' +
    '<div>' +
      '<div style="font-size:.72rem;color:#6b7280;margin-bottom:4px;">Manzanita</div>' +
      '<div class="chat-bubble">' + escapeHtmlChat(respuesta) + '</div>' +
    '</div>';
  elem.removeAttribute('id');
  body.scrollTop = body.scrollHeight;
}

/* ══════════════════════════════════════════════
   UTILIDADES
   ══════════════════════════════════════════════ */

/**
 * Escapa caracteres HTML especiales para prevenir XSS.
 * @param {string} str - Texto a escapar
 * @returns {string} Texto seguro para insertar en el DOM
 */
function escapeHtmlChat(str) {
  var d = document.createElement('div');
  d.appendChild(document.createTextNode(String(str)));
  return d.innerHTML;
}
