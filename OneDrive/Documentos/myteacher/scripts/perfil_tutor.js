/* =============================================
   perfil_tutor.js — Lógica de la página de perfil del tutor
   ============================================= */

/* Cuando la página carga completamente, ejecutamos esto */
document.addEventListener('DOMContentLoaded', function () {
  /* Por ahora esta página no necesita mucha lógica extra
     porque los datos del tutor están en el HTML directamente.
     En el futuro aquí se podría cargar la info del tutor
     desde una base de datos usando el ID de la URL */

  var params = new URLSearchParams(window.location.search);
  var tutorId = params.get('id');

  /* Si hay un ID en la URL, mostramos ese tutor específico.
     Por ahora lo dejamos como prueba con Ricardo Soler */
  if (tutorId) {
    console.log('Cargando tutor con ID:', tutorId);
  }
});
