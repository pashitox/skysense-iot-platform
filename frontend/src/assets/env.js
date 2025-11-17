(function(window) {
  window.__env = window.__env || {};
  window.__env.apiUrl = '/api';  // Usar proxy o relative path
  window.__env.wsUrl = 'ws://' + window.location.hostname + ':8000/ws/sensors';
  window.__env.appName = 'SkySense IoT Dashboard';
}(this));
