// html-kit prototype — page behaviour. Pages never carry their own <script>.
// - wraps every <table> in a keyboard-scrollable box
// - adds the shared arrowhead marker for <svg class="diagram">; records its viewBox width (--vbw) for doc sizing
// - loads Mermaid (only if the page has <pre class="mermaid">), themed to light/dark;
//   on body.doc each diagram keeps a min width (readable labels) and scrolls in its box
// - body.deck: builds progress bar + footer nav; arrow/space/PageUp/PageDown/Home/End;
//   #N in the URL opens slide N; .slide.backup slides sit outside the main count
(function () {
  const MERMAID = 'https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.min.js';

  document.querySelectorAll('table').forEach((t) => {
    if (t.parentElement.classList.contains('table-wrap')) return;
    const w = document.createElement('div');
    w.className = 'table-wrap';
    w.tabIndex = 0;
    t.replaceWith(w);
    w.appendChild(t);
  });

  // One shared arrowhead for every <svg class="diagram">; it takes the colour of the line it ends.
  if (document.querySelector('svg.diagram')) {
    document.body.insertAdjacentHTML('afterbegin',
      '<svg width="0" height="0" style="position:absolute" aria-hidden="true"><marker id="kit-arrow" ' +
      'viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9" markerUnits="userSpaceOnUse" ' +
      'orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10 z"/></marker></svg>');
    // Docs size each diagram from its viewBox width (kit.css: body.doc figure > svg.diagram).
    document.querySelectorAll('svg.diagram').forEach((svg) => {
      const w = svg.viewBox.baseVal && svg.viewBox.baseVal.width;
      if (w) svg.style.setProperty('--vbw', w);
      svg.toggleAttribute('data-wide', w > 600);
    });
  }

  if (document.querySelector('pre.mermaid')) {
    const s = document.createElement('script');
    s.src = MERMAID;
    s.onload = () => {
      const css = getComputedStyle(document.documentElement);
      const v = (n) => css.getPropertyValue(n).trim();
      const dark = css.colorScheme === 'dark';
      window.mermaid.initialize({
        startOnLoad: false,
        theme: 'base',
        themeVariables: {
          darkMode: dark,
          background: v('--paper'),
          primaryColor: v('--raised'),
          primaryBorderColor: v('--ink'),
          primaryTextColor: v('--ink'),
          lineColor: v('--ink'),
          secondaryColor: v('--ok-bg'),
          tertiaryColor: v('--paper'),
          edgeLabelBackground: v('--paper'),
          fontFamily: v('--display'),
          fontSize: '16px',
        },
      });
      // Mermaid can't measure hidden slides; render them all visible, then restore.
      document.body.classList.add('kit-measuring');
      window.mermaid.run({ querySelector: 'pre.mermaid' }).finally(() => {
        document.body.classList.remove('kit-measuring');
        // Docs: never shrink a diagram below ~14px labels (16px font × 0.875); its box scrolls instead.
        if (!document.body.classList.contains('doc')) return;
        document.querySelectorAll('pre.mermaid svg').forEach((svg) => {
          const w = parseFloat(svg.style.maxWidth);
          if (w) svg.style.minWidth = Math.round(w * 0.875) + 'px';
        });
      });
    };
    document.head.appendChild(s);
    const st = document.createElement('style');
    st.textContent = 'body.kit-measuring .slide{display:block!important;visibility:hidden}body.kit-measuring .slide.current{visibility:visible}';
    document.head.appendChild(st);
  }

  if (!document.body.classList.contains('deck')) return;

  const slides = Array.from(document.querySelectorAll('.slide'));
  const main = slides.filter((s) => !s.classList.contains('backup')).length;
  const title = document.title;

  const progress = document.createElement('div');
  progress.className = 'progress';
  progress.innerHTML = '<div></div>';
  document.body.prepend(progress);

  const bar = document.createElement('footer');
  bar.className = 'bar';
  bar.innerHTML =
    '<span></span><span class="keys">← → to navigate</span>' +
    '<span class="nav"><button aria-label="Previous slide">←</button>' +
    '<span class="count"></span><button aria-label="Next slide">→</button></span>';
  bar.firstChild.textContent = title;
  document.body.appendChild(bar);
  const [prev, next] = bar.querySelectorAll('button');
  const count = bar.querySelector('.count');

  let i = 0;
  slides.forEach((s) => { s.tabIndex = -1; });

  function show(n) {
    i = Math.max(0, Math.min(slides.length - 1, n));
    slides.forEach((s, j) => s.classList.toggle('current', j === i));
    count.textContent = i < main
      ? `${i + 1} / ${main}`
      : `backup ${i + 1 - main} / ${slides.length - main}`;
    progress.firstChild.style.width = (Math.min(i + 1, main) / main) * 100 + '%';
    history.replaceState?.(null, '', '#' + (i + 1));
    slides[i].focus({ preventScroll: true });
  }

  prev.addEventListener('click', () => show(i - 1));
  next.addEventListener('click', () => show(i + 1));
  document.addEventListener('keydown', (e) => {
    if (e.target instanceof Element && e.target.closest('.table-wrap')) return;
    const k = e.key;
    if (k === 'ArrowRight' || k === ' ' || k === 'PageDown') show(i + 1);
    else if (k === 'ArrowLeft' || k === 'PageUp') show(i - 1);
    else if (k === 'Home') show(0);
    else if (k === 'End') show(slides.length - 1);
    else return;
    e.preventDefault();
  });

  const h = parseInt(location.hash.slice(1), 10);
  show(Number.isFinite(h) ? h - 1 : 0);
})();
