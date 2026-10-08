// @ts-nocheck
(function() {
  document.getElementById('yr').textContent = new Date().getFullYear();

  var TOKEN = new URLSearchParams(window.location.search).get('token');
  var API_BASE = window.location.origin;

  if (!TOKEN) {
    document.getElementById('formWrap').style.display = 'none';
    document.getElementById('invalidState').classList.add('show');
    return;
  }

  function toggleField(inputId, eyeId) {
    var input = document.getElementById(inputId);
    var eye = document.getElementById(eyeId);
    var isShown = input.type === 'text';
    input.type = isShown ? 'password' : 'text';
    eye.innerHTML = isShown
      ? '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>'
      : '<path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/>';
  }

  document.getElementById('togglePw').onclick = function() { toggleField('pw', 'eyePw'); };
  document.getElementById('togglePw2').onclick = function() { toggleField('pw2', 'eyePw2'); };

  document.getElementById('pw').addEventListener('input', function() {
    var v = this.value;
    var score = 0;
    if (v.length >= 8) score++;
    if (/[A-Z]/.test(v)) score++;
    if (/[0-9]/.test(v)) score++;
    if (/[^A-Za-z0-9]/.test(v)) score++;

    var map = [
      { pct: '0%', color: 'transparent', text: 'Enter a password' },
      { pct: '25%', color: '#ef4444', text: 'Too weak' },
      { pct: '50%', color: '#f97316', text: 'Could be stronger' },
      { pct: '75%', color: '#eab308', text: 'Almost there' },
      { pct: '100%', color: '#16a34a', text: 'Strong password ✓' },
    ];
    document.getElementById('strengthFill').style.width = map[score].pct;
    document.getElementById('strengthFill').style.background = map[score].color;
    document.getElementById('strengthLabel').textContent = map[score].text;
    document.getElementById('strengthLabel').style.color = map[score].color === 'transparent' ? 'var(--light)' : map[score].color;
  });

  function resetButton(btn) {
    btn.disabled = false;
    btn.innerHTML = '<svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path d="M20 6L9 17l-5-5"/></svg> Reset Password';
  }

  function showError(msg) {
    var el = document.getElementById('alertError');
    el.innerHTML = '<svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><path d="M12 8v4m0 4h.01"/></svg>' + (msg || 'Something went wrong');
    el.classList.add('show');
  }

  function clearAlerts() {
    document.getElementById('alertError').classList.remove('show');
    document.getElementById('alertError').innerHTML = '';
    document.getElementById('alertSuccess').classList.remove('show');
    document.getElementById('alertSuccess').innerHTML = '';
  }

  function handleReset() {
    clearAlerts();

    var pw = document.getElementById('pw').value.trim();
    var pw2 = document.getElementById('pw2').value.trim();

    if (!pw || pw.length < 8) {
      showError('Password must be at least 8 characters.');
      return;
    }
    if (pw !== pw2) {
      document.getElementById('pw2').classList.add('field-error');
      showError('Passwords do not match.');
      return;
    }
    document.getElementById('pw2').classList.remove('field-error');

    var btn = document.getElementById('submitBtn');
    btn.disabled = true;
    btn.innerHTML = '<div class="spinner"></div>&nbsp;Resetting…';

    fetch(API_BASE + '/api/auth/reset', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: TOKEN, password: pw }),
    })
    .then(function(res) {
      return res.json().then(function(data) {
        return { ok: res.ok, status: res.status, data: data };
      });
    })
    .then(function(result) {
      if (result.ok) {
        document.getElementById('formWrap').style.display = 'none';
        document.getElementById('successState').classList.add('show');
      } else {
        var msg = (result.data && result.data.error && result.data.error.message)
              || (result.data && result.data.message)
              || 'Reset failed. The link may have expired.';
        showError(msg);
        resetButton(btn);
      }
    })
    .catch(function() {
      showError('Network error — please check your connection and try again.');
      resetButton(btn);
    });
  }

  document.getElementById('submitBtn').addEventListener('click', handleReset);
})();