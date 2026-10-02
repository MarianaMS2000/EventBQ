/* =============================================
   comunidad.js — Lógica de la vista "Comunidad"
   Incluye integración real con la API de Anthropic
   para responder preguntas académicas con IA.
   ============================================= */

/* ── VARIABLES GLOBALES ── */

/** Lista de etiquetas que el usuario ha agregado al formulario */
var tagActuales = [];

/** Contador para asignar IDs únicos a las preguntas nuevas */
var contadorPreguntas = 4;

/** Pregunta que está esperando respuesta de la IA (para el modal de API key) */
var preguntaPendienteIA = null;

/* ══════════════════════════════════════════════
   INICIALIZACIÓN
   ══════════════════════════════════════════════ */

document.addEventListener('DOMContentLoaded', function () {
  inicializarTagsInput();
  inicializarAskTextarea();
});

/* ══════════════════════════════════════════════
   INPUT DE TAGS / ETIQUETAS
   Permite agregar y eliminar chips de etiquetas
   ══════════════════════════════════════════════ */

/**
 * Configura el comportamiento del campo de etiquetas:
 * - Presionar Enter agrega un chip
 * - Hacer click en "×" dentro del chip lo elimina
 */
function inicializarTagsInput() {
  var tagsInput = document.getElementById('tagsInput');
  var tagsField = document.getElementById('tagsField');
  if (!tagsInput || !tagsField) return;

  /* Al presionar Enter, convertimos el texto en un chip */
  tagsInput.addEventListener('keydown', function (e) {
    if (e.key === 'Enter') {
      e.preventDefault(); /* Evitamos salto de línea */
      var texto = tagsInput.value.trim();
      if (texto && !tagActuales.includes(texto) && tagActuales.length < 5) {
        agregarTag(texto);
        tagsInput.value = '';
      } else if (tagActuales.includes(texto)) {
        /* Indicamos que ya existe con un parpadeo */
        tagsInput.style.color = '#ef4444';
        setTimeout(function () { tagsInput.style.color = ''; }, 600);
        tagsInput.value = '';
      }
    }
    /* Backspace sobre campo vacío elimina el último tag */
    if (e.key === 'Backspace' && tagsInput.value === '' && tagActuales.length > 0) {
      eliminarTag(tagActuales[tagActuales.length - 1]);
    }
  });

  /* Hacer click en el contenedor lleva el foco al input */
  tagsField.addEventListener('click', function () {
    tagsInput.focus();
  });
}

/**
 * Crea y agrega un chip de etiqueta visible al campo de tags.
 * @param {string} texto - Texto de la etiqueta a agregar
 */
function agregarTag(texto) {
  tagActuales.push(texto);

  var tagsInput = document.getElementById('tagsInput');
  var tagsField = document.getElementById('tagsField');

  /* Creamos el chip HTML */
  var chip = document.createElement('span');
  chip.className = 'tag-chip';
  chip.setAttribute('data-tag', texto);
  chip.innerHTML = texto + ' <button class="tag-chip-remove" onclick="eliminarTag(\'' +
                   texto.replace(/'/g, "\\'") + '\')" aria-label="Eliminar etiqueta">×</button>';

  /* Insertamos el chip antes del input de texto */
  tagsField.insertBefore(chip, tagsInput);
}

/**
 * Elimina un chip de etiqueta del campo de tags.
 * @param {string} texto - Texto de la etiqueta a eliminar
 */
function eliminarTag(texto) {
  tagActuales = tagActuales.filter(function (t) { return t !== texto; });

  var chip = document.querySelector('[data-tag="' + CSS.escape(texto) + '"]');
  if (chip) chip.remove();
}

/* ══════════════════════════════════════════════
   TEXTAREA AUTO-EXPANDIBLE
   El campo de pregunta crece al escribir
   ══════════════════════════════════════════════ */

/**
 * Hace que el textarea de la pregunta crezca automáticamente
 * según el contenido escrito por el usuario.
 */
function inicializarAskTextarea() {
  var textarea = document.getElementById('askTextarea');
  if (!textarea) return;

  textarea.addEventListener('input', function () {
    /* Reseteamos la altura para calcular la real */
    this.style.height = '52px';
    var scrollH = this.scrollHeight;
    this.style.height = Math.min(scrollH, 120) + 'px';
    this.style.overflowY = scrollH > 120 ? 'auto' : 'hidden';
  });

  /* Ctrl+Enter también publica la pregunta */
  textarea.addEventListener('keydown', function (e) {
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
      e.preventDefault();
      publicarPregunta();
    }
  });
}

/* ══════════════════════════════════════════════
   PUBLICAR PREGUNTA
   Crea una nueva card en la lista de preguntas
   ══════════════════════════════════════════════ */

/**
 * Recoge el texto de la pregunta y las etiquetas,
 * valida que no estén vacíos y crea una card nueva
 * al inicio de la lista de preguntas.
 */
function publicarPregunta() {
  var textarea = document.getElementById('askTextarea');
  var texto = textarea ? textarea.value.trim() : '';

  if (!texto) {
    textarea.focus();
    textarea.style.border = '2px solid #ef4444';
    setTimeout(function () { textarea.style.border = ''; }, 2000);
    return;
  }

  /* Obtenemos el nombre del usuario guardado o usamos uno genérico */
  var stored = JSON.parse(localStorage.getItem('mt_user') || '{}');
  var nombreUsuario = stored.nombre || 'Tú';
  var iniciales = nombreUsuario.split(' ').map(function (p) { return p[0]; }).join('').slice(0, 2).toUpperCase();

  /* Incrementamos el contador de preguntas */
  contadorPreguntas++;
  var nuevoId = 'q-' + contadorPreguntas;

  /* Construimos los chips de tags en HTML */
  var tagsHTML = tagActuales.map(function (t) {
    return '<span class="q-tag">' + escapeHtml(t) + '</span>';
  }).join('');

  /* Creamos la card completa */
  var card = document.createElement('div');
  card.className = 'question-card new-question';
  card.id = nuevoId;
  card.innerHTML =
    '<div class="question-card-header">' +
      '<div class="question-user-avatar" style="background:linear-gradient(135deg,#1e4620,#4a7a30);">' +
        iniciales +
      '</div>' +
      '<div class="question-user-info">' +
        '<div class="question-user-name">' + escapeHtml(nombreUsuario) + '</div>' +
        '<div class="question-time"><i class="fa-regular fa-clock"></i> Ahora mismo</div>' +
      '</div>' +
    '</div>' +
    '<div class="question-text">' + escapeHtml(texto) + '</div>' +
    (tagsHTML ? '<div class="question-tags">' + tagsHTML + '</div>' : '') +
    '<div class="question-card-footer">' +
      '<button class="btn-like" onclick="toggleLike(this)">' +
        '<i class="fa-regular fa-heart"></i> <span class="like-count">0</span>' +
      '</button>' +
      '<button class="btn-see-answers" onclick="verRespuestas(\'' + nuevoId + '\', this, \'' +
        escapeJs(texto) + '\')">' +
        '<i class="fa-regular fa-comment-dots"></i> Ver respuestas (IA)' +
      '</button>' +
    '</div>' +
    '<div class="answers-section" id="answers-' + nuevoId + '"></div>';

  /* Insertamos la card al inicio de la lista */
  var lista = document.getElementById('questionsList');
  lista.insertBefore(card, lista.firstChild);

  /* Actualizamos el contador de preguntas visibles */
  actualizarContadorPreguntas();

  /* Limpiamos el formulario */
  textarea.value = '';
  textarea.style.height = '52px';
  tagActuales.forEach(function (t) { eliminarTag(t); });
  tagActuales = [];

  /* Desplazamos la vista hacia la nueva card */
  card.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

/**
 * Actualiza el texto del contador de preguntas mostrado al usuario.
 */
function actualizarContadorPreguntas() {
  var cards = document.querySelectorAll('#questionsList .question-card');
  var contEl = document.getElementById('questionsCount');
  if (contEl) {
    contEl.textContent = cards.length + ' preguntas';
  }
}

/* ══════════════════════════════════════════════
   SISTEMA DE LIKES
   ══════════════════════════════════════════════ */

/**
 * Alterna el estado de "me gusta" en una card de pregunta.
 * Incrementa o decrementa el contador numérico.
 * @param {HTMLElement} btn - El botón de like que fue presionado
 */
function toggleLike(btn) {
  var yaLikeado = btn.classList.toggle('liked');
  var countEl = btn.querySelector('.like-count');
  if (!countEl) return;

  var actual = parseInt(countEl.textContent) || 0;
  countEl.textContent = yaLikeado ? actual + 1 : Math.max(0, actual - 1);

  /* Cambiamos el ícono según el estado */
  var icon = btn.querySelector('i');
  if (icon) {
    icon.className = yaLikeado ? 'fa-solid fa-heart' : 'fa-regular fa-heart';
  }
}

/* ══════════════════════════════════════════════
   VER RESPUESTAS CON IA (FUNCIONALIDAD REAL)
   Llama a la API de Anthropic para responder
   la pregunta académica del estudiante
   ══════════════════════════════════════════════ */

/**
 * Despliega la sección de respuestas de una pregunta.
 * Si ya hay respuesta guardada, la muestra directamente.
 * Si no, llama a la IA de Anthropic para generar una respuesta real.
 *
 * @param {string}      questionId    - ID de la card (ej: 'q-1')
 * @param {HTMLElement} btn           - Botón "Ver respuestas" que activó la acción
 * @param {string}      questionText  - Texto de la pregunta a responder
 */
function verRespuestas(questionId, btn, questionText) {
  var answersDiv = document.getElementById('answers-' + questionId);
  if (!answersDiv) return;

  /* Si la sección ya está abierta, la cerramos (toggle) */
  if (answersDiv.classList.contains('open')) {
    answersDiv.classList.remove('open');
    btn.innerHTML = '<i class="fa-regular fa-comment-dots"></i> Ver respuestas';
    return;
  }

  /* Abrimos la sección */
  answersDiv.classList.add('open');
  btn.innerHTML = '<i class="fa-solid fa-chevron-up"></i> Ocultar respuestas';

  /* Si ya tiene contenido (respuesta anterior), no volvemos a llamar la API */
  if (answersDiv.innerHTML.trim() !== '') return;

  /* Verificamos que haya una API key configurada */
  var apiKey = localStorage.getItem('mt_api_key');
  if (!apiKey) {
    /* Guardamos la pregunta pendiente y mostramos el modal de API key */
    preguntaPendienteIA = { questionId: questionId, btn: btn, questionText: questionText };
    document.getElementById('apiKeyModal').classList.add('open');
    return;
  }

  /* Llamamos a la IA con la pregunta */
  pedirRespuestaIA(questionId, questionText, answersDiv);
}

/**
 * Realiza la llamada real a la API de Anthropic (claude-sonnet-4-20250514)
 * para obtener una respuesta educativa a la pregunta del estudiante.
 *
 * @param {string}      questionId   - ID de la card para almacenar la respuesta
 * @param {string}      questionText - Pregunta a responder
 * @param {HTMLElement} answersDiv   - Contenedor donde se mostrará la respuesta
 */
async function pedirRespuestaIA(questionId, questionText, answersDiv) {
  var apiKey = localStorage.getItem('mt_api_key');

  /* Mostramos el indicador de carga */
  answersDiv.innerHTML =
    '<div class="ai-typing-indicator">' +
      '<div class="typing-dots"><span></span><span></span><span></span></div>' +
      '<span>Manzanita está generando una respuesta...</span>' +
    '</div>';

  try {
    /* Llamada real a la API de Anthropic */
    var response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        /* Header requerido para llamadas desde el navegador */
        'anthropic-dangerous-direct-browser-access': 'true'
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 400,
        /* System prompt que define el rol del asistente educativo */
        system: 'Eres un asistente académico experto de myTeacher, una plataforma de tutorías. ' +
                'Responde preguntas académicas de forma clara, didáctica y motivadora en español. ' +
                'Usa ejemplos sencillos cuando sea posible. ' +
                'Mantén las respuestas concisas (máximo 3 párrafos cortos). ' +
                'Al final, anima al estudiante a practicar o profundizar el tema.',
        messages: [
          {
            role: 'user',
            content: questionText
          }
        ]
      })
    });

    /* Verificamos que la respuesta sea exitosa */
    if (!response.ok) {
      var errorData = await response.json();
      throw new Error(errorData.error ? errorData.error.message : 'Error en la API');
    }

    var data = await response.json();

    /* Extraemos el texto de la respuesta */
    var respuestaTexto = '';
    if (data.content && data.content.length > 0) {
      data.content.forEach(function (block) {
        if (block.type === 'text') {
          respuestaTexto += block.text;
        }
      });
    }

    if (!respuestaTexto) throw new Error('Respuesta vacía de la IA');

    /* Mostramos la respuesta de la IA en la card */
    mostrarRespuestaIA(answersDiv, respuestaTexto);

  } catch (error) {
    /* Si hay error, mostramos un mensaje de error amigable */
    answersDiv.innerHTML =
      '<div class="ai-answer-card" style="border-color:#fca5a5;background:#fff5f5;">' +
        '<div class="ai-badge" style="background:#fee2e2;color:#dc2626;">' +
          '<i class="fa-solid fa-triangle-exclamation"></i> Error' +
        '</div>' +
        '<div class="ai-answer-text" style="margin-top:8px;color:#6b7280;">' +
          'No pudimos obtener una respuesta. Verifica tu clave API o intenta de nuevo. ' +
          '<button onclick="localStorage.removeItem(\'mt_api_key\')" ' +
          'style="color:#dc2626;text-decoration:underline;background:none;border:none;cursor:pointer;">' +
          'Cambiar clave API</button>' +
        '</div>' +
      '</div>';

    console.error('Error llamando la API de Anthropic:', error);
  }
}

/**
 * Construye y muestra visualmente la card de respuesta de la IA
 * dentro de la sección de respuestas de la pregunta.
 *
 * @param {HTMLElement} container     - Contenedor donde insertar la respuesta
 * @param {string}      respuestaText - Texto de la respuesta generada por la IA
 */
function mostrarRespuestaIA(container, respuestaText) {
  /* Convertimos saltos de línea en párrafos HTML */
  var parrafos = respuestaText.split('\n').filter(function (p) { return p.trim(); });
  var htmlParrafos = parrafos.map(function (p) {
    return '<p style="margin-bottom:8px;">' + escapeHtml(p) + '</p>';
  }).join('');

  container.innerHTML =
    '<div class="ai-answer-card">' +
      '<div class="ai-answer-header">' +
        '<img src="images/manzana.png" alt="IA" ' +
          'style="width:28px;height:28px;border-radius:50%;object-fit:cover;" ' +
          'onerror="this.style.display=\'none\'">' +
        '<span class="ai-badge">' +
          '<i class="fa-solid fa-robot"></i> Manzanita IA' +
        '</span>' +
      '</div>' +
      '<div class="ai-answer-text">' + htmlParrafos + '</div>' +
    '</div>';
}

/* ══════════════════════════════════════════════
   MODAL: CONFIGURAR API KEY
   ══════════════════════════════════════════════ */

/**
 * Guarda la clave API ingresada por el usuario en localStorage
 * y retoma la pregunta que estaba pendiente de responder.
 */
function guardarApiKey() {
  var input = document.getElementById('apiKeyInput');
  var apiKey = input ? input.value.trim() : '';

  /* Validación básica del formato de la clave */
  if (!apiKey || !apiKey.startsWith('sk-ant-')) {
    input.style.borderColor = '#ef4444';
    input.placeholder = 'La clave debe comenzar con sk-ant-...';
    setTimeout(function () {
      input.style.borderColor = '';
      input.placeholder = 'sk-ant-api03-...';
    }, 2500);
    return;
  }

  /* Guardamos en localStorage */
  localStorage.setItem('mt_api_key', apiKey);
  document.getElementById('apiKeyModal').classList.remove('open');
  input.value = '';

  /* Si había una pregunta pendiente, la procesamos ahora */
  if (preguntaPendienteIA) {
    var answersDiv = document.getElementById('answers-' + preguntaPendienteIA.questionId);
    if (answersDiv) {
      pedirRespuestaIA(
        preguntaPendienteIA.questionId,
        preguntaPendienteIA.questionText,
        answersDiv
      );
    }
    preguntaPendienteIA = null;
  }
}

/**
 * Cierra el modal de API key sin guardar.
 */
function cerrarApiKeyModal() {
  document.getElementById('apiKeyModal').classList.remove('open');
  preguntaPendienteIA = null;
}

/* ══════════════════════════════════════════════
   FILTRAR POR TAGS (PANEL DERECHO)
   ══════════════════════════════════════════════ */

/**
 * Filtra las cards de preguntas según la etiqueta seleccionada
 * desde el panel derecho "Temas populares".
 * @param {string} tagTexto - Etiqueta por la que filtrar
 */
function filtrarTag(tagTexto) {
  var cards = document.querySelectorAll('#questionsList .question-card');
  var alguna = false;

  cards.forEach(function (card) {
    var tags = card.querySelectorAll('.q-tag');
    var tieneTag = false;
    tags.forEach(function (t) {
      if (t.textContent.toLowerCase().includes(tagTexto.toLowerCase())) {
        tieneTag = true;
      }
    });

    /* Ocultamos cards que no coincidan y mostramos las que sí */
    if (tieneTag) {
      card.style.display = '';
      alguna = true;
    } else {
      card.style.display = 'none';
    }
  });

  /* Si ninguna card coincide, mostramos todas nuevamente */
  if (!alguna) {
    cards.forEach(function (c) { c.style.display = ''; });
  }

  /* Actualizamos el contador */
  actualizarContadorPreguntas();
}

/* ══════════════════════════════════════════════
   CARGAR MÁS PREGUNTAS
   ══════════════════════════════════════════════ */

/**
 * Simula la carga de más preguntas desde el servidor
 * (en producción haría una petición real al backend).
 */
function cargarMas() {
  var btn = document.getElementById('btnLoadMore');
  if (!btn) return;

  /* Estado de carga */
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Cargando...';
  btn.disabled = true;

  setTimeout(function () {
    /* En un proyecto real, aquí harías fetch al backend */
    btn.innerHTML = '<i class="fa-solid fa-check"></i> No hay más preguntas por ahora';
    btn.style.background = '#f3f4f6';
    btn.style.color = '#6b7280';
    btn.disabled = true;
  }, 1500);
}

/* ══════════════════════════════════════════════
   UTILIDADES
   ══════════════════════════════════════════════ */

/**
 * Escapa caracteres especiales HTML para prevenir XSS.
 * @param {string} str - Texto a escapar
 * @returns {string} Texto seguro para insertar en el DOM
 */
function escapeHtml(str) {
  var div = document.createElement('div');
  div.appendChild(document.createTextNode(str));
  return div.innerHTML;
}

/**
 * Escapa caracteres especiales para uso dentro de strings JavaScript
 * que van dentro de atributos HTML (ej: onclick="...").
 * @param {string} str - Texto a escapar
 * @returns {string} Texto escapado para uso en atributos JS
 */
function escapeJs(str) {
  return str.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/"/g, '\\"');
}

/* Cerramos el modal de API key al hacer click en el overlay */
document.addEventListener('DOMContentLoaded', function () {
  var apiModal = document.getElementById('apiKeyModal');
  if (apiModal) {
    apiModal.addEventListener('click', function (e) {
      if (e.target === this) cerrarApiKeyModal();
    });
  }

  /* Permitimos enviar la API key con la tecla Enter */
  var apiInput = document.getElementById('apiKeyInput');
  if (apiInput) {
    apiInput.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') guardarApiKey();
    });
  }
});
