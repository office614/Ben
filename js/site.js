/* National Capital Cleaning — small site behaviours (no dependencies) */
(function () {
  document.documentElement.classList.remove('no-js');

  // Sticky header shadow
  var header = document.querySelector('.site-header');
  function onScroll() { if (header) header.classList.toggle('scrolled', window.scrollY > 10); }
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  // Mobile menu
  var toggle = document.querySelector('.menu-toggle');
  var nav = document.querySelector('.nav');
  if (toggle && nav) {
    toggle.addEventListener('click', function () {
      var open = nav.classList.toggle('open');
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
  }

  // Reveal on scroll
  var items = document.querySelectorAll('.reveal');
  if ('IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });
    items.forEach(function (el) { io.observe(el); });
  } else {
    items.forEach(function (el) { el.classList.add('in'); });
  }

  // Hero video: fall back to the poster image if the video can't play
  var vid = document.querySelector('.hero-media video');
  if (vid) {
    var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (reduce) { vid.removeAttribute('autoplay'); vid.pause(); }
    vid.addEventListener('error', function () { vid.style.display = 'none'; }, true);
  }

  // Project filters
  var filterBtns = document.querySelectorAll('.filters button');
  filterBtns.forEach(function (btn) {
    btn.addEventListener('click', function () {
      var f = btn.getAttribute('data-filter');
      filterBtns.forEach(function (b) { b.classList.toggle('on', b === btn); });
      document.querySelectorAll('.gallery .tile').forEach(function (t) {
        var show = f === 'all' || (t.getAttribute('data-cat') || '').indexOf(f) !== -1;
        t.classList.toggle('hide', !show);
      });
    });
  });

  // Lightbox
  var lb = document.querySelector('.lightbox');
  if (lb) {
    var lbImg = lb.querySelector('img');
    var lbCap = lb.querySelector('p');
    document.querySelectorAll('.gallery .tile').forEach(function (t) {
      t.setAttribute('tabindex', '0');
      function open() {
        var img = t.querySelector('img');
        lbImg.src = img.getAttribute('src');
        lbImg.alt = img.alt;
        var s = t.querySelector('.cap strong');
        lbCap.textContent = s ? s.textContent : '';
        lb.classList.add('open');
      }
      t.addEventListener('click', open);
      t.addEventListener('keydown', function (e) { if (e.key === 'Enter') open(); });
    });
    function close() { lb.classList.remove('open'); }
    lb.addEventListener('click', function (e) { if (e.target === lb || e.target.tagName === 'BUTTON') close(); });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') close(); });
  }

  // Quote form: opens the visitor's email app with the enquiry filled in
  var form = document.querySelector('#quote-form');
  if (form) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      if (!form.reportValidity()) return;
      var d = new FormData(form);
      var services = d.getAll('service').join(', ') || 'Not specified';
      var body = [
        'Name: ' + d.get('name'),
        'Business: ' + (d.get('business') || '-'),
        'Email: ' + d.get('email'),
        'Phone: ' + (d.get('phone') || '-'),
        'Premises type: ' + d.get('premises'),
        'Services: ' + services,
        '',
        d.get('message') || ''
      ].join('\n');
      var to = form.getAttribute('data-to');
      window.location.href = 'mailto:' + to + '?subject=' + encodeURIComponent('Quote request - ' + d.get('name')) + '&body=' + encodeURIComponent(body);
      document.querySelector('.form-ok').classList.add('show');
    });
  }

  // Footer year
  var y = document.querySelector('[data-year]');
  if (y) y.textContent = new Date().getFullYear();
})();
