(function() {
  var VERSION = 'swarmz-visual@2026-11-23/section-looks';
  if (window.__swarmzVisualMode) {
    console.log('[swarmz-visual] already running:', window.__swarmzVisualMode);
    return;
  }
  window.__swarmzVisualMode = VERSION;
  var active = false; // selection listeners attached only while true
  // Comment mode reuses the same selection listeners as visual mode, but a click
  // emits swarmz:comment_element_selected (for the preview-comments feature)
  // instead of running the visual-edit selection side-effects.
  //
  // VISUAL_ON / COMMENT_ON are independent intents, each owned solely by its
  // own message type (swarmz:visual_mode / swarmz:comment_mode). The parent
  // posts both messages in one commit when switching modes, and the order
  // between them is not guaranteed to leave active correct if enable()/
  // disable() were called directly from each handler — e.g. entering Visual
  // from Comment posts visual_mode{true} then comment_mode{false}; a naive
  // "last message wins" would call disable() and leave the machine off even
  // though Visual should stay on. Deriving active from the OR of both
  // intents via syncActive() makes the end state independent of message
  // order.
  var VISUAL_ON = false;
  var COMMENT_ON = false;
  // TEXT_ON: the editor's Edit text tool (swarmz:text_mode). Same rule: its
  // own message owns it and syncActive() ORs it in.
  var TEXT_ON = false;
  console.log('[swarmz-visual] booted (idle)', VERSION);

  // -------------------------------------------------------------------------
  // Same-origin snapdom loader — the IIFE build is provisioned into the pod at
  // public/__swarmz_snapdom.js (useVisualEditMode.ensureInjected), fetched
  // same-origin and evaluated INSIDE the preview so element snapshots
  // rasterize locally with the browser's own renderer: instant, faithful to
  // the signed-in view, and immune to the modern-CSS parsing failures that
  // killed html2canvas. Loaded lazily on first snapshot.
  // -------------------------------------------------------------------------
  var __sdPromise = null;
  function loadSnapdom() {
    if (window.snapdom) return Promise.resolve(window.snapdom);
    if (__sdPromise) return __sdPromise;
    __sdPromise = fetch('/__swarmz_snapdom.js')
      .then(function(r) {
        if (!r.ok) throw new Error('snapdom fetch failed: ' + r.status);
        return r.text();
      })
      .then(function(code) {
        var s = document.createElement('script');
        s.textContent = code;
        document.head.appendChild(s);
        if (!window.snapdom) throw new Error('snapdom failed to load');
        return window.snapdom;
      });
    return __sdPromise;
  }

  // Smallest ancestor that fully contains the element PLUS its context margin.
  // Rasterizing a small container takes tens of ms; rasterizing the whole body
  // would take seconds on a long page — so walk up only as far as needed and
  // stop before regions get huge.
  function pickContextContainer(el) {
    var er = el.getBoundingClientRect();
    var padX = Math.min(80, Math.max(24, er.width * 0.3));
    var padY = Math.min(64, Math.max(20, er.height * 0.3));
    var needW = Math.max(200, er.width + padX * 2);
    var needH = Math.max(120, er.height + padY * 2);
    var best = el;
    var cur = el.parentElement;
    for (var hops = 0; cur && cur !== document.documentElement && hops < 15; hops++, cur = cur.parentElement) {
      // Never cross a SCROLLED ancestor: the rasterizer clones the DOM and a
      // clone's internal scroll state is not trustworthy, so cropping by
      // visual rect deltas across a scrolled container lands on the wrong
      // area. Stop below it — worst case we capture the element alone, which
      // is always geometrically exact.
      if (cur.scrollTop > 0 || cur.scrollLeft > 0) break;
      var r = cur.getBoundingClientRect();
      if (r.width < 1 || r.height < 1) continue;
      if (r.width * r.height > 4000000 && best !== el) break; // keep the smaller pick
      best = cur;
      if (r.width >= needW && r.height >= needH) break;
    }
    return best;
  }

  // -------------------------------------------------------------------------
  // Overlay layer (pointer-events:none so it never receives events)
  // -------------------------------------------------------------------------
  var LAYER_ID = '__swarmz_visual_layer';
  var layer = document.createElement('div');
  layer.id = LAYER_ID;
  layer.style.cssText = [
    'position:fixed','top:0','left:0','width:100vw','height:100vh',
    'pointer-events:none','z-index:2147483640','margin:0','padding:0',
  ].join(';');
  // layer is appended by enable(); while idle there is no editor DOM in the page.

  var ACCENT = '#C85A1E';
  // The editor passes its own brand colour (a white-label host's, on their
  // domain) with the mode messages, so outlines never show another brand.
  function setAccent(color) {
    if (typeof color !== 'string' || !color || color === ACCENT) return;
    try { if (window.CSS && CSS.supports && !CSS.supports('color', color)) return; } catch (_) { return; }
    ACCENT = color;
    hoverBox.style.borderColor = color;
    hoverBox.style.background = 'color-mix(in srgb, ' + color + ' 6%, transparent)';
    hoverLabel.style.background = color;
    selected.forEach(function(el) { el.style.outline = '2px solid ' + color; });
  }

  var hoverBox = document.createElement('div');
  hoverBox.style.cssText = [
    'position:absolute','box-sizing:border-box',
    'border:1.5px solid ' + ACCENT,
    'background:rgba(200,90,30,0.06)',
    'display:none','pointer-events:none',
    'will-change:transform,width,height',
  ].join(';');
  layer.appendChild(hoverBox);

  var hoverLabel = document.createElement('div');
  hoverLabel.style.cssText = [
    'position:absolute','display:none','pointer-events:none',
    'background:' + ACCENT,'color:#fff','white-space:nowrap',
    'font:600 10px/1 ui-monospace,SFMono-Regular,Menlo,Consolas,monospace',
    'padding:3px 5px','border-radius:3px 3px 3px 0',
    'letter-spacing:0.02em',
  ].join(';');
  layer.appendChild(hoverLabel);

  // -------------------------------------------------------------------------
  // Selectability — only visible HTML tag elements, never our own UI
  // -------------------------------------------------------------------------
  var IGNORED = new Set([
    'HTML','BODY','HEAD','SCRIPT','STYLE','LINK','META','TITLE','NOSCRIPT',
    'BASE','TEMPLATE','SLOT',
  ]);
  var TEXT_TAGS = new Set([
    'P','H1','H2','H3','H4','H5','H6','SPAN','A','BUTTON','LABEL','LI','TD','TH','CAPTION',
    'EM','STRONG','I','B','U','SMALL','MARK','SUB','SUP','BLOCKQUOTE','CODE','PRE','CITE',
    'Q','KBD','SAMP','VAR','TIME','ABBR','DT','DD','FIGCAPTION','SUMMARY','LEGEND',
  ]);

  function isOwnUI(el) {
    if (!el) return false;
    if (el.id === LAYER_ID) return true;
    if (typeof el.closest === 'function') return !!el.closest('#' + LAYER_ID);
    return false;
  }

  var SVG_NS = 'http://www.w3.org/2000/svg';

  function isSvgInternal(el) {
    // Anything inside an <svg> (path, g, rect, etc.) — but not the <svg> root itself
    return el && el.namespaceURI === SVG_NS && el.tagName && el.tagName.toLowerCase() !== 'svg';
  }

  function isSelectable(el) {
    if (!el || el.nodeType !== 1 || !el.tagName) return false;
    if (IGNORED.has(el.tagName.toUpperCase())) return false;
    if (isOwnUI(el)) return false;
    if (isSvgInternal(el)) return false; // treat whole <svg> as one selectable unit
    var rect = el.getBoundingClientRect();
    if (rect.width < 1 || rect.height < 1) return false;
    return true;
  }

  // First selectable descendant — the way to drill INTO an element after
  // click-selection promoted up to the outer block (e.g. reach the text span
  // inside a button). Prefers a direct child, then recurses.
  function firstSelectableChild(el) {
    if (!el) return null;
    var kids = el.children;
    for (var i = 0; i < kids.length; i++) {
      if (isSelectable(kids[i])) return kids[i];
    }
    for (var j = 0; j < kids.length; j++) {
      var deep = firstSelectableChild(kids[j]);
      if (deep) return deep;
    }
    return null;
  }

  function safeClassName(el) {
    // SVG className is SVGAnimatedString, not a plain string
    var cn = el.className;
    if (typeof cn === 'string') return cn;
    if (cn && typeof cn.baseVal === 'string') return cn.baseVal;
    return '';
  }

  // -------------------------------------------------------------------------
  // Element ID system — stable data attribute so the parent can address
  // elements without escaping Tailwind selectors like bg-[#fff]
  // -------------------------------------------------------------------------
  var nextId = 1;
  var idMap = new WeakMap();

  function getElementId(el) {
    if (idMap.has(el)) return idMap.get(el);
    var id = '__swarmz_' + (nextId++);
    el.setAttribute('data-swarmz-id', id);
    idMap.set(el, id);
    return id;
  }

  function findById(id) {
    return document.querySelector('[data-swarmz-id="' + id + '"]');
  }

  function getDisplaySelector(el) {
    var tag = el.tagName.toLowerCase();
    if (el.id) return tag + '#' + el.id;
    var cls = Array.from(el.classList)
      .filter(function(c) { return c.indexOf('[') === -1 && c.indexOf('__swarmz') === -1; })
      .slice(0, 2);
    return cls.length ? tag + '.' + cls.join('.') : tag;
  }

  // Human-readable, reload-stable CSS path (e.g. "#top > div:nth-of-type(2) > h1")
  // — used where a selector is PERSISTED or shown to a person (element comments).
  // getElementId's __swarmz_N ids are per-page-load counters, so they'd be
  // meaningless in a stored comment or a chat card.
  function cssPath(el) {
    var parts = [];
    var node = el;
    while (node && node.nodeType === 1 && node !== document.documentElement) {
      var tag = node.tagName.toLowerCase();
      if (node.id) { parts.unshift('#' + CSS.escape(node.id)); break; }
      var idx = 1;
      var sib = node.previousElementSibling;
      while (sib) { if (sib.tagName === node.tagName) idx++; sib = sib.previousElementSibling; }
      var ambiguous = idx > 1;
      if (!ambiguous) {
        var after = node.nextElementSibling;
        while (after) { if (after.tagName === node.tagName) { ambiguous = true; break; } after = after.nextElementSibling; }
      }
      parts.unshift(ambiguous ? tag + ':nth-of-type(' + idx + ')' : tag);
      if (tag === 'body') break;
      node = node.parentElement;
    }
    return parts.join(' > ');
  }

  // -------------------------------------------------------------------------
  // React source detection — used by source-mapper to write changes back
  // to JSX files. Walks the FIBER chain only (component composition), never
  // the DOM chain.
  // -------------------------------------------------------------------------
  var SOURCE_SKIP = /(\/node_modules\/|\/\.vite\/|\/react-dom\.|\/react\.development\.|\/react\.production\.|__swarmz_visual)/;
  function parseStackForUserFrame(stack) {
    if (!stack || typeof stack !== 'string') return null;
    var lines = stack.split('\n');
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/(https?:\/\/[^):\s]+):(\d+):(\d+)/);
      if (!m) continue;
      if (SOURCE_SKIP.test(m[1])) continue;
      try {
        var path = new URL(m[1]).pathname;
        if (!/\.(tsx?|jsx?)$/i.test(path)) continue;
        return { fileName: path, lineNumber: parseInt(m[2], 10) || 1, columnNumber: parseInt(m[3], 10) || 1 };
      } catch (_) {}
    }
    return null;
  }
  function getFiber(el) {
    if (!el) return null;
    var keys = Object.getOwnPropertyNames(el);
    for (var i = 0; i < keys.length; i++) {
      if (keys[i].indexOf('__reactFiber$') === 0 || keys[i].indexOf('__reactInternalInstance$') === 0) {
        return el[keys[i]];
      }
    }
    return null;
  }
  function getReactSource(el) {
    try {
      var fiber = getFiber(el);
      while (fiber) {
        if (fiber._debugSource && fiber._debugSource.fileName) {
          return {
            fileName: fiber._debugSource.fileName,
            lineNumber: fiber._debugSource.lineNumber || 1,
            columnNumber: fiber._debugSource.columnNumber || 1,
          };
        }
        if (fiber._debugStack && fiber._debugStack.stack) {
          var fromStack = parseStackForUserFrame(fiber._debugStack.stack);
          if (fromStack) return fromStack;
        }
        fiber = fiber.return;
      }
    } catch (_) {}
    return null;
  }

  // Source file for THIS element's OWN fiber (no walking up the fiber chain).
  // Used to detect component boundaries — when adjacent DOM elements come
  // from different source files, they belong to different React components.
  var __ownSrcCache = new WeakMap();
  function getOwnSourceFile(el) {
    if (!el || el.nodeType !== 1) return null;
    if (__ownSrcCache.has(el)) return __ownSrcCache.get(el);
    var out = null;
    try {
      var fiber = getFiber(el);
      if (fiber) {
        if (fiber._debugSource && fiber._debugSource.fileName) {
          out = fiber._debugSource.fileName;
        } else if (fiber._debugStack && fiber._debugStack.stack) {
          var s = parseStackForUserFrame(fiber._debugStack.stack);
          if (s) out = s.fileName;
        }
      }
    } catch (_) {}
    __ownSrcCache.set(el, out);
    return out;
  }

  // The "page file" is whichever user-code source file has the MOST DOM
  // elements in the rendered tree — i.e., the file the user is currently
  // editing. Library wrappers like RevealLines only contribute a handful
  // of elements so they never win. Computed once per script lifetime.
  var __pageFile;
  function getPageFile() {
    if (__pageFile !== undefined) return __pageFile;
    var counts = Object.create(null);
    var winner = null;
    var winnerCount = 0;
    var scanned = 0;
    function visit(node) {
      if (!node || node.nodeType !== 1 || scanned > 1500) return;
      if (!isOwnUI(node) && node.tagName && !IGNORED.has(node.tagName.toUpperCase())) {
        scanned++;
        var src = getOwnSourceFile(node);
        if (src && !SOURCE_SKIP.test(src)) {
          counts[src] = (counts[src] || 0) + 1;
          if (counts[src] > winnerCount) { winner = src; winnerCount = counts[src]; }
        }
      }
      var kids = node.children;
      for (var i = 0; i < kids.length; i++) visit(kids[i]);
    }
    if (document.body) visit(document.body);
    __pageFile = winner;
    console.log('[swarmz-visual] page file:', winner, 'count:', winnerCount);
    return winner;
  }

  // -------------------------------------------------------------------------
  // Computed style snapshot for the properties panel
  // -------------------------------------------------------------------------
  function getComputedProps(el) {
    var s = window.getComputedStyle(el);
    return {
      width: s.width, height: s.height,
      minWidth: s.minWidth, maxWidth: s.maxWidth, minHeight: s.minHeight, maxHeight: s.maxHeight,
      padding: s.padding, paddingTop: s.paddingTop, paddingRight: s.paddingRight, paddingBottom: s.paddingBottom, paddingLeft: s.paddingLeft,
      margin: s.margin, marginTop: s.marginTop, marginRight: s.marginRight, marginBottom: s.marginBottom, marginLeft: s.marginLeft,
      display: s.display, flexDirection: s.flexDirection, justifyContent: s.justifyContent, alignItems: s.alignItems, gap: s.gap,
      position: s.position, top: s.top, right: s.right, bottom: s.bottom, left: s.left,
      backgroundColor: s.backgroundColor, opacity: s.opacity, overflow: s.overflow,
      flexWrap: s.flexWrap, columnGap: s.columnGap, rowGap: s.rowGap,
      borderWidth: s.borderWidth, borderTopWidth: s.borderTopWidth, borderColor: s.borderColor, borderTopColor: s.borderTopColor,
      borderStyle: s.borderStyle, borderTopStyle: s.borderTopStyle, borderRadius: s.borderRadius,
      fontFamily: s.fontFamily, fontSize: s.fontSize, fontWeight: s.fontWeight, fontStyle: s.fontStyle,
      lineHeight: s.lineHeight, letterSpacing: s.letterSpacing, textAlign: s.textAlign, textDecoration: s.textDecoration,
      color: s.color, transform: s.transform,
      backgroundImage: (s.backgroundImage || '').slice(0, 300), objectFit: s.objectFit,
    };
  }

  // -------------------------------------------------------------------------
  // Hover state
  // -------------------------------------------------------------------------
  var hovered = null;

  function paintHover(el) {
    if (!el) {
      hoverBox.style.display = 'none';
      hoverLabel.style.display = 'none';
      return;
    }
    var r = el.getBoundingClientRect();
    hoverBox.style.display = 'block';
    hoverBox.style.left = r.left + 'px';
    hoverBox.style.top = r.top + 'px';
    hoverBox.style.width = r.width + 'px';
    hoverBox.style.height = r.height + 'px';
    // Text tool: a dashed outline reads as "click to type here".
    hoverBox.style.borderStyle = textOnly() ? 'dashed' : 'solid';

    // Comment mode and the text tool: outline only — the tag-name label is a
    // visual-edit affordance.
    if ((COMMENT_ON && !VISUAL_ON) || textOnly()) {
      hoverLabel.style.display = 'none';
      return;
    }
    hoverLabel.style.display = 'block';
    hoverLabel.textContent = el.tagName.toLowerCase();
    // Prefer label above the box; flip below if no headroom
    var labelHeight = 16;
    var aboveTop = r.top - labelHeight;
    var useAbove = aboveTop >= 2;
    hoverLabel.style.left = Math.max(2, r.left) + 'px';
    hoverLabel.style.top = (useAbove ? aboveTop : r.top + 2) + 'px';
    hoverLabel.style.borderRadius = useAbove ? '3px 3px 3px 0' : '0 3px 3px 3px';
  }

  function setHover(el) {
    if (el === hovered) return;
    hovered = el;
    paintHover(el);
  }

  // -------------------------------------------------------------------------
  // Selection state
  // -------------------------------------------------------------------------
  var selected = new Set();

  function paintSelection(el) {
    el.style.outline = '2px solid ' + ACCENT;
    el.style.outlineOffset = '-1px';
  }

  function unpaintSelection(el) {
    el.style.outline = '';
    el.style.outlineOffset = '';
  }

  // -------------------------------------------------------------------------
  // Structure facts: what the selected element IS on the page (a picture in a
  // box, a band of the page, a card), so the editor never offers a section
  // rebuild for an image box inside a section. Classification lives in the
  // editor (element-kind.ts); the script only measures.
  // -------------------------------------------------------------------------
  var MEDIA_SEL = 'img,picture,svg,video,canvas';

  function lowerTag(el) { return el && el.tagName ? String(el.tagName).toLowerCase() : ''; }

  function textLength(el) {
    return String(el.textContent || '').replace(/\s+/g, ' ').trim().length;
  }

  // Visible pictures inside el: an svg or picture counts once, not its parts.
  function mediaFacts(el) {
    var list = el.querySelectorAll ? el.querySelectorAll(MEDIA_SEL) : [];
    var count = 0, first = null;
    for (var i = 0; i < list.length && count < 50; i++) {
      var m = list[i];
      var host = m.parentElement && m.parentElement.closest ? m.parentElement.closest('svg,picture') : null;
      if (host && el.contains(host)) continue;
      var r = m.getBoundingClientRect();
      if (r.width < 8 || r.height < 8) continue;
      count++;
      if (!first) first = m;
    }
    return { count: count, first: first };
  }

  function ancestorTags(el) {
    var out = [];
    var cur = el.parentElement;
    while (cur && out.length < 12) {
      out.push(lowerTag(cur));
      if (cur === document.body) break;
      cur = cur.parentElement;
    }
    return out;
  }

  // The picture's URL, for the panel's thumbnail (huge inline data URLs are skipped).
  function pictureSource(el, mf) {
    var img = lowerTag(el) === 'img' ? el : null;
    if (!img && mf.count === 1 && mf.first) {
      var tag = lowerTag(mf.first);
      img = tag === 'img' ? mf.first : tag === 'picture' ? mf.first.querySelector('img') : null;
    }
    var src = img ? String(img.currentSrc || img.src || '') : '';
    return src.length <= 8000 ? src : '';
  }

  function elementStructure(el) {
    var mf = mediaFacts(el);
    var parent = el.parentElement;
    var area = 0;
    if (mf.count === 1 && mf.first) {
      var a = mf.first.getBoundingClientRect();
      var b = el.getBoundingClientRect();
      area = b.width * b.height > 0 ? Math.round(100 * (a.width * a.height) / (b.width * b.height)) : 0;
    }
    return {
      ancestors: ancestorTags(el),
      parentId: parent && parent.id ? String(parent.id) : '',
      siblings: parent ? parent.children.length : 0,
      children: el.children ? el.children.length : 0,
      textLength: textLength(el),
      mediaCount: mf.count,
      mediaTag: mf.count === 1 && mf.first ? lowerTag(mf.first) : '',
      mediaArea: Math.min(100, area),
      mediaSrc: pictureSource(el, mf),
      viewportWidth: document.documentElement.clientWidth || window.innerWidth || 0,
    };
  }

  // "main > section:nth-of-type(3) > div:nth-of-type(2)": where the element
  // sits, for the AI to find the exact node (stops at the first id).
  function domPath(el) {
    var parts = [];
    var cur = el;
    while (cur && cur.nodeType === 1 && cur !== document.body && cur !== document.documentElement && parts.length < 10) {
      var tag = lowerTag(cur);
      if (cur.id && String(cur.id).indexOf('__swarmz') !== 0) { parts.unshift(tag + '#' + cur.id); break; }
      var part = tag;
      var parent = cur.parentElement;
      if (parent) {
        var same = 0, index = 0;
        for (var i = 0; i < parent.children.length; i++) {
          var sib = parent.children[i];
          if (sib.tagName === cur.tagName) { same++; if (sib === cur) index = same; }
        }
        if (same > 1) part += ':nth-of-type(' + index + ')';
      }
      parts.unshift(part);
      cur = parent;
    }
    return parts.join(' > ');
  }

  // A copy of el without the editor's own marks (ids, the selection outline).
  function cleanClone(el, deep) {
    var clone = el.cloneNode(deep);
    var nodes = [clone];
    if (deep && clone.querySelectorAll) {
      var inner = clone.querySelectorAll('*');
      for (var i = 0; i < inner.length; i++) nodes.push(inner[i]);
    }
    for (var j = 0; j < nodes.length; j++) {
      var n = nodes[j];
      if (!n.removeAttribute) continue;
      n.removeAttribute('data-swarmz-id');
      n.removeAttribute('contenteditable');
      if (n.style) {
        n.style.removeProperty('outline');
        n.style.removeProperty('outline-offset');
        if (!n.getAttribute('style')) n.removeAttribute('style');
      }
    }
    if (deep && clone.querySelectorAll) {
      var junk = clone.querySelectorAll('script,noscript,style,template,#' + LAYER_ID);
      for (var k = 0; k < junk.length; k++) junk[k].remove();
    }
    return clone;
  }

  function htmlExcerpt(el, max) {
    try {
      var big = el.querySelectorAll && el.querySelectorAll('*').length > 300;
      var html = cleanClone(el, !big).outerHTML.replace(/\s+/g, ' ');
      return html.length > max ? html.slice(0, max - 1) + '…' : html;
    } catch (_) { return ''; }
  }

  function absoluteUrl(u) {
    try { return new URL(u, document.baseURI).href; } catch (_) { return u; }
  }

  function styleSummary(node) {
    if (!node) return null;
    var s = window.getComputedStyle(node);
    return {
      font: String(s.fontFamily || '').split(',')[0].replace(/["']/g, '').trim(),
      size: s.fontSize, weight: s.fontWeight, color: s.color,
      background: s.backgroundColor, radius: s.borderRadius,
      padding: s.padding, transform: s.textTransform, letterSpacing: s.letterSpacing,
    };
  }

  // Tailwind's built-in scales are not the site's brand; only its own tokens are.
  var TOKEN_SKIP = /^--(tw-|swarmz|spacing|breakpoint-|container-|text-|font-weight-|tracking-|leading-|shadow-|inset-shadow-|drop-shadow-|blur-|perspective-|aspect-|ease-|animate-|default-|color-(red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose|slate|gray|zinc|neutral|stone|black|white)(-|$))/;

  function rootTokens() {
    var out = {};
    var n = 0;
    function walk(rules) {
      for (var j = 0; j < rules.length && n < 80; j++) {
        var r = rules[j];
        if (!r.selectorText && r.cssRules) { walk(r.cssRules); continue; }
        if (!r.selectorText || !r.style) continue;
        if (!/(^|,)\s*(:root|html)\s*(,|$)/.test(r.selectorText)) continue;
        for (var k = 0; k < r.style.length && n < 80; k++) {
          var name = r.style[k];
          if (name.indexOf('--') !== 0 || out[name] !== undefined || TOKEN_SKIP.test(name)) continue;
          var value = r.style.getPropertyValue(name).trim();
          if (!value || value.length > 160) continue;
          out[name] = value;
          n++;
        }
      }
    }
    var sheets = document.styleSheets;
    for (var i = 0; i < sheets.length && n < 80; i++) {
      var rules;
      try { rules = sheets[i].cssRules; } catch (_) { continue; }
      if (rules) walk(rules);
    }
    return out;
  }

  // Everything New looks needs about one section: its HTML with absolute
  // picture URLs, the look of its parts, the site's theme tokens, small
  // copies of its own pictures (the variant previews cannot reach the
  // page's files) and large artwork kept aside so the HTML stays short.
  function sectionSnapshot(el) {
    var clone = cleanClone(el, true);
    var images = {};
    var budget = 6;
    var originals = el.querySelectorAll('img');
    var copies = clone.querySelectorAll('img');
    for (var i = 0; i < originals.length && i < copies.length; i++) {
      var img = originals[i];
      var src = img.currentSrc || img.src || '';
      if (!src) continue;
      copies[i].setAttribute('src', src);
      copies[i].removeAttribute('srcset');
      copies[i].removeAttribute('sizes');
      copies[i].removeAttribute('loading');
      if (budget <= 0 || src.indexOf('data:') === 0 || images[src]) continue;
      try {
        if (new URL(src).origin !== window.location.origin || !img.complete || !img.naturalWidth) continue;
        var w = Math.min(640, img.naturalWidth);
        var h = Math.max(1, Math.round(img.naturalHeight * w / img.naturalWidth));
        var canvas = document.createElement('canvas');
        canvas.width = w;
        canvas.height = h;
        canvas.getContext('2d').drawImage(img, 0, 0, w, h);
        images[src] = canvas.toDataURL('image/jpeg', 0.72);
        budget--;
      } catch (_) {}
    }
    var linked = clone.querySelectorAll('[poster],source[src],video[src]');
    for (var v = 0; v < linked.length; v++) {
      if (linked[v].getAttribute('poster')) linked[v].setAttribute('poster', absoluteUrl(linked[v].getAttribute('poster')));
      if (linked[v].getAttribute('src')) linked[v].setAttribute('src', absoluteUrl(linked[v].getAttribute('src')));
    }
    var art = {};
    var artSize = 0;
    var artIndex = 0;
    var svgs = clone.querySelectorAll('svg');
    for (var a = 0; a < svgs.length; a++) {
      var svg = svgs[a];
      if (svg.parentElement && svg.parentElement.closest && svg.parentElement.closest('svg')) continue;
      var markup = svg.outerHTML;
      if (markup.length < 1500 || artSize + markup.length > 400000) continue;
      artIndex++;
      var key = String(artIndex);
      art[key] = markup;
      artSize += markup.length;
      var stub = document.createElementNS(SVG_NS, 'svg');
      ['class', 'viewBox', 'width', 'height', 'aria-hidden', 'role'].forEach(function(attr) {
        if (svg.getAttribute(attr) !== null) stub.setAttribute(attr, svg.getAttribute(attr));
      });
      stub.setAttribute('data-swz-art', key);
      svg.parentNode.replaceChild(stub, svg);
    }
    var html = clone.outerHTML.replace(/\s{2,}/g, ' ');
    var truncated = html.length > 40000;
    var pick = function(sel) { return el.matches && el.matches(sel) ? el : el.querySelector(sel); };
    var sectionStyle = styleSummary(el);
    if (sectionStyle) sectionStyle.backgroundImage = (window.getComputedStyle(el).backgroundImage || '').slice(0, 300);
    var box = el.getBoundingClientRect();
    return {
      html: truncated ? html.slice(0, 40000) : html,
      truncated: truncated,
      styles: {
        section: sectionStyle,
        heading: styleSummary(pick('h1,h2,h3')),
        text: styleSummary(pick('p')),
        button: styleSummary(pick('button,a[class*="btn"],a[class*="button"],a[class*="rounded"]')),
        page: styleSummary(document.body),
      },
      tokens: rootTokens(),
      images: images,
      art: art,
      width: Math.round(box.width),
      height: Math.round(box.height),
    };
  }

  function buildElementData(el) {
    var rect = el.getBoundingClientRect();
    var fullText = el.textContent || '';
    var truncated = fullText.trim().slice(0, 80);
    var isTextTag = TEXT_TAGS.has(el.tagName.toUpperCase());
    var noElementChildren = el.children && el.children.length === 0;
    var textOnly = isTextTag && noElementChildren;
    return {
      selector: getElementId(el),
      displaySelector: getDisplaySelector(el),
      tagName: el.tagName,
      classList: Array.from(el.classList),
      id: el.id || '',
      computedStyles: getComputedProps(el),
      rect: { top: rect.top, right: rect.right, bottom: rect.bottom, left: rect.left, width: rect.width, height: rect.height },
      textContent: textOnly ? fullText : truncated,
      className: safeClassName(el),
      hasOnlyTextChildren: textOnly,
      source: getReactSource(el),
      structure: elementStructure(el),
      domPath: domPath(el),
      html: htmlExcerpt(el, 700),
    };
  }

  function selectElement(el) {
    if (!isSelectable(el)) return;
    selected.add(el);
    paintSelection(el);
    var data = buildElementData(el);
    data.type = 'swarmz:element_selected';
    window.parent.postMessage(data, '*');
  }

  function deselectElement(el) {
    if (!selected.has(el)) return;
    selected.delete(el);
    unpaintSelection(el);
    window.parent.postMessage({ type: 'swarmz:element_deselected', selector: getElementId(el) }, '*');
  }

  function clearSelection() {
    selected.forEach(function(el) { unpaintSelection(el); });
    selected.clear();
    window.parent.postMessage({ type: 'swarmz:selection_cleared' }, '*');
  }

  // -------------------------------------------------------------------------
  // Inline text editing — double-click a text-bearing element to edit its text
  // in place. Commit on Enter or click-away, cancel on Escape. The committed
  // text rides the same changeset/Apply path as the Typography "Content" field
  // (parent receives swarmz:text_edited). Only leaf text tags are editable, so
  // we never make a layout container contentEditable.
  // -------------------------------------------------------------------------
  var editing = false;
  var editingEl = null;
  var editOriginal = '';

  function isTextEditable(el) {
    if (!isSelectable(el)) return false;
    if (!TEXT_TAGS.has(el.tagName.toUpperCase())) return false;
    return !!el.children && el.children.length === 0;
  }

  function onEditBlur() { commitTextEdit(); }

  function enterTextEdit(el) {
    if (editing) commitTextEdit();
    if (!isTextEditable(el)) return;
    if (!selected.has(el)) { clearSelection(); selectElement(el); }
    editing = true;
    editingEl = el;
    editOriginal = el.textContent || '';
    // Record the original so swarmz:revert_changes (Discard) can restore it.
    var key = getElementId(el) + '::text-content';
    if (!window.__swarmzOriginalStyles[key]) {
      window.__swarmzOriginalStyles[key] = { el: el, property: 'text-content', original: editOriginal };
    }
    setHover(null);
    try { el.contentEditable = 'plaintext-only'; } catch (_) {}
    if (el.getAttribute('contenteditable') !== 'plaintext-only') el.setAttribute('contenteditable', 'true');
    el.style.cursor = 'text';
    el.style.outline = '2px solid ' + ACCENT;
    el.style.outlineOffset = '-1px';
    el.addEventListener('blur', onEditBlur, true);
    el.focus();
    try {
      var range = document.createRange();
      range.selectNodeContents(el);
      var sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(range);
    } catch (_) {}
  }

  function finishTextEdit(el) {
    el.removeEventListener('blur', onEditBlur, true);
    el.removeAttribute('contenteditable');
    el.style.cursor = '';
    var sel = window.getSelection();
    if (sel) sel.removeAllRanges();
    if (selected.has(el)) paintSelection(el);
  }

  function commitTextEdit() {
    if (!editing || !editingEl) return;
    var el = editingEl;
    var newText = el.textContent || '';
    editing = false;
    editingEl = null;
    finishTextEdit(el);
    if (newText === editOriginal) return; // nothing changed this session
    // Reconcile against the TRUE source original (recorded on first edit) rather
    // than this session's starting text, so editing back to the original removes
    // the pending change instead of leaving a phantom dirty state. Include the
    // React source so classless text (a bare <p>) can still be located on Apply.
    var key = getElementId(el) + '::text-content';
    var rec = window.__swarmzOriginalStyles[key];
    var trueOriginal = rec && typeof rec.original === 'string' ? rec.original : editOriginal;
    window.parent.postMessage({
      type: 'swarmz:text_edited',
      selector: getElementId(el),
      tagName: el.tagName,
      className: safeClassName(el),
      id: el.id || '',
      source: getReactSource(el),
      oldValue: trueOriginal,
      newValue: newText,
    }, '*');
  }

  function cancelTextEdit() {
    if (!editing || !editingEl) return;
    var el = editingEl;
    editing = false;
    editingEl = null;
    el.textContent = editOriginal;
    finishTextEdit(el);
  }

  // -------------------------------------------------------------------------
  // Text tool (the editor's "Edit text", swarmz:text_mode). ONE click on any
  // text edits it in place with the caret where the click landed; clicking
  // other text moves straight on to it. While a session is open the editor
  // shows a formatting bar over the text and sends whole-element style
  // commands (swarmz:text_format). Every change is reported as it happens
  // (swarmz:text_changed / swarmz:text_styled) so the editor can count it and
  // later send one prompt that codes all of them in. Originals are recorded
  // once per element: swarmz:text_revert puts them back (the editor's Clear),
  // swarmz:text_forget drops them after a send. Kept apart from the Select
  // tool's __swarmzOriginalStyles so neither tool's Clear touches the other.
  // -------------------------------------------------------------------------
  var TEXT_STYLE_PROPS = ['font-size', 'font-family', 'font-weight', 'font-style', 'color', 'text-align'];
  // Phrasing children a text block may hold and still be edited as one piece
  // (an icon inside a link or button counts).
  var INLINE_TAGS = new Set([
    'SPAN','A','B','STRONG','I','EM','U','S','SMALL','MARK','SUB','SUP','CODE','KBD','ABBR','TIME',
    'Q','CITE','DEL','INS','BR','WBR','LABEL','VAR','SAMP','DFN','BDI','BDO','SVG','IMG',
  ]);
  var NON_TEXT_TAGS = new Set([
    'INPUT','TEXTAREA','SELECT','OPTION','IMG','VIDEO','AUDIO','CANVAS','SVG','IFRAME','OBJECT','EMBED',
    'PICTURE','HR','BR',
  ]);
  var textSession = null;   // { el, id, rec, source, outline, outlineOffset }
  var textRecords = {};     // id -> { el, text, snap, styles: { prop: { value, priority, computed } } }
  var textDownInSession = false;
  var textInputRaf = 0;
  var textCursorEl = null;
  var textCursorPrev = '';
  var textPalette = null;

  function textOnly() { return TEXT_ON && !VISUAL_ON && !COMMENT_ON; }

  function hasOwnText(el) {
    for (var n = el.firstChild; n; n = n.nextSibling) {
      if (n.nodeType === 3 && n.nodeValue && n.nodeValue.trim()) return true;
    }
    return false;
  }

  function inlineOnly(el) {
    var kids = el.children;
    for (var i = 0; i < kids.length; i++) {
      if (!INLINE_TAGS.has(kids[i].tagName.toUpperCase())) return false;
    }
    return true;
  }

  function isTextTarget(el) {
    if (!el || el.nodeType !== 1 || !el.tagName) return false;
    var tag = el.tagName.toUpperCase();
    if (IGNORED.has(tag) || NON_TEXT_TAGS.has(tag)) return false;
    if (el.namespaceURI === SVG_NS || isOwnUI(el)) return false;
    // The app's own editors (a rich-text field) stay the app's.
    if (el.isContentEditable && !(textSession && textSession.el === el)) return false;
    if (!inlineOnly(el)) return false;
    if (!hasOwnText(el) && !(el.children.length > 0 && (el.textContent || '').trim())) return false;
    return isSelectable(el);
  }

  // The text block under the pointer: the nearest element that holds text,
  // widened through inline wrappers so a <strong> inside a paragraph edits
  // the paragraph and a label inside a button edits the button.
  function textTargetAt(x, y) {
    var el = document.elementFromPoint(x, y);
    for (var hops = 0; el && hops < 6 && !isTextTarget(el); hops++) el = el.parentElement;
    if (!el || !isTextTarget(el)) return null;
    while (el.parentElement && INLINE_TAGS.has(el.tagName.toUpperCase()) && isTextTarget(el.parentElement)) {
      el = el.parentElement;
    }
    return el;
  }

  // Leave no empty style="" behind on an element that had none.
  function dropEmptyStyle(el) {
    if (el.getAttribute('style') === '') el.removeAttribute('style');
  }

  function setTextHover(el) {
    if (textCursorEl && textCursorEl !== el) {
      textCursorEl.style.cursor = textCursorPrev;
      dropEmptyStyle(textCursorEl);
      textCursorEl = null;
    }
    if (el && textCursorEl !== el) {
      textCursorPrev = el.style.cursor;
      el.style.cursor = 'text';
      textCursorEl = el;
    }
    setHover(el);
  }

  // The element's original children and text, as the very node objects the
  // app's renderer holds, so a revert puts back exactly what it can update.
  function snapshotText(el) {
    var lists = [];
    (function walk(node) {
      lists.push([node, Array.prototype.slice.call(node.childNodes)]);
      for (var c = node.firstChild; c; c = c.nextSibling) if (c.nodeType === 1) walk(c);
    })(el);
    var texts = [];
    var tw = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
    for (var t = tw.nextNode(); t; t = tw.nextNode()) texts.push([t, t.nodeValue]);
    return { lists: lists, texts: texts };
  }

  function restoreText(snap) {
    for (var i = 0; i < snap.lists.length; i++) {
      var parent = snap.lists[i][0];
      var kids = snap.lists[i][1];
      while (parent.firstChild) parent.removeChild(parent.firstChild);
      for (var k = 0; k < kids.length; k++) parent.appendChild(kids[k]);
    }
    for (var j = 0; j < snap.texts.length; j++) snap.texts[j][0].nodeValue = snap.texts[j][1];
  }

  function textRecordFor(el, id) {
    var rec = textRecords[id];
    if (!rec || rec.el !== el) {
      rec = { el: el, text: el.textContent || '', snap: snapshotText(el), styles: {} };
      textRecords[id] = rec;
    }
    return rec;
  }

  function textTargetInfo(s) {
    return {
      selector: s.id,
      tagName: s.el.tagName,
      id: s.el.id || '',
      className: safeClassName(s.el),
      classList: Array.from(s.el.classList),
      textContent: s.rec.text,
      source: s.source,
    };
  }

  function firstFamily(stack) {
    return String(stack || '').split(',')[0].trim().replace(/^["']+|["']+$/g, '');
  }

  // Fonts and text colours the page already uses, offered by the formatting
  // bar. Measured once per text-tool activation.
  function pagePalette() {
    if (textPalette) return textPalette;
    var fonts = [];
    var seenFonts = Object.create(null);
    var colorCount = Object.create(null);
    function addFont(stack) {
      var name = firstFamily(stack);
      var key = name.toLowerCase();
      if (!name || seenFonts[key]) return;
      seenFonts[key] = 1;
      fonts.push({ label: name, value: stack });
    }
    var bodyStack = document.body ? window.getComputedStyle(document.body).fontFamily : '';
    addFont(bodyStack);
    var els = document.body
      ? document.body.querySelectorAll('h1,h2,h3,h4,h5,h6,p,a,li,button,label,span,blockquote,small,strong')
      : [];
    for (var i = 0; i < els.length && i < 400; i++) {
      if (isOwnUI(els[i])) continue;
      var cs = window.getComputedStyle(els[i]);
      addFont(cs.fontFamily);
      if (hasOwnText(els[i])) colorCount[cs.color] = (colorCount[cs.color] || 0) + 1;
    }
    try {
      var generic = (bodyStack.split(',').pop() || '').trim();
      if (!/^(serif|sans-serif|monospace|cursive|fantasy|system-ui|ui-[a-z-]+)$/.test(generic)) generic = 'sans-serif';
      document.fonts.forEach(function(f) {
        if (f.status === 'loaded' && f.family) addFont('"' + firstFamily(f.family) + '", ' + generic);
      });
    } catch (_) {}
    var colors = Object.keys(colorCount)
      .filter(function(c) { return c !== 'transparent' && !/,\s*0\)$/.test(c); })
      .sort(function(a, b) { return colorCount[b] - colorCount[a]; })
      .slice(0, 8);
    textPalette = { fonts: fonts.slice(0, 10), colors: colors };
    return textPalette;
  }

  function postTextSession(state) {
    var msg = { type: 'swarmz:text_session', state: state };
    var s = textSession;
    if (s && state !== 'end') {
      var r = s.el.getBoundingClientRect();
      var cs = window.getComputedStyle(s.el);
      msg.selector = s.id;
      msg.tagName = s.el.tagName;
      msg.rect = { top: r.top, right: r.right, bottom: r.bottom, left: r.left, width: r.width, height: r.height };
      msg.display = cs.display;
      msg.styles = {};
      for (var i = 0; i < TEXT_STYLE_PROPS.length; i++) {
        msg.styles[TEXT_STYLE_PROPS[i]] = cs.getPropertyValue(TEXT_STYLE_PROPS[i]);
      }
      if (state === 'start') {
        var pal = pagePalette();
        msg.fonts = pal.fonts;
        msg.colors = pal.colors;
      }
    }
    try { window.parent.postMessage(msg, '*'); } catch (_) {}
  }

  function reportTextChange() {
    var s = textSession;
    if (!s) return;
    try {
      window.parent.postMessage({
        type: 'swarmz:text_changed',
        target: textTargetInfo(s),
        oldValue: s.rec.text,
        newValue: s.el.textContent || '',
      }, '*');
    } catch (_) {}
  }

  function onTextInput() {
    if (textInputRaf) return;
    textInputRaf = requestAnimationFrame(function() {
      textInputRaf = 0;
      reportTextChange();
      postTextSession('update');
    });
  }

  // Pasted content lands as plain text, never the clipboard's markup.
  function onTextPaste(e) {
    var text = '';
    try { text = (e.clipboardData || window.clipboardData).getData('text/plain'); } catch (_) {}
    e.preventDefault();
    if (!text) return;
    try { document.execCommand('insertText', false, text); } catch (_) {}
  }

  function placeCaret(el, x, y) {
    var range = null;
    try {
      if (document.caretPositionFromPoint) {
        var pos = document.caretPositionFromPoint(x, y);
        if (pos && el.contains(pos.offsetNode)) {
          range = document.createRange();
          range.setStart(pos.offsetNode, pos.offset);
        }
      } else if (document.caretRangeFromPoint) {
        var hit = document.caretRangeFromPoint(x, y);
        if (hit && el.contains(hit.startContainer)) range = hit;
      }
    } catch (_) {}
    try {
      if (!range) {
        // No caret under the pointer (padding, an icon): end of the text.
        range = document.createRange();
        range.selectNodeContents(el);
        range.collapse(false);
      }
      var sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(range);
    } catch (_) {}
  }

  function startTextSession(el, x, y) {
    var id = getElementId(el);
    var rec = textRecordFor(el, id);
    setTextHover(null);
    textSession = {
      el: el, id: id, rec: rec, source: getReactSource(el),
      outline: el.style.outline, outlineOffset: el.style.outlineOffset,
      spellcheck: el.getAttribute('spellcheck'),
    };
    try { el.contentEditable = 'plaintext-only'; } catch (_) {}
    if (el.getAttribute('contenteditable') !== 'plaintext-only') el.setAttribute('contenteditable', 'true');
    // No red squiggles over the person's own site while they type.
    el.setAttribute('spellcheck', 'false');
    el.style.outline = '2px solid ' + ACCENT;
    el.style.outlineOffset = '2px';
    el.addEventListener('input', onTextInput);
    el.addEventListener('paste', onTextPaste);
    try { el.focus({ preventScroll: true }); } catch (_) { try { el.focus(); } catch (_2) {} }
    placeCaret(el, x, y);
    postTextSession('start');
  }

  // report=false when the editor is about to clear or forget the edits: a
  // late text_changed would otherwise put a cleared change back.
  function endTextSession(report) {
    var s = textSession;
    if (!s) return;
    if (textInputRaf) { cancelAnimationFrame(textInputRaf); textInputRaf = 0; }
    if (report) reportTextChange();
    textSession = null;
    textDownInSession = false;
    s.el.removeEventListener('input', onTextInput);
    s.el.removeEventListener('paste', onTextPaste);
    s.el.removeAttribute('contenteditable');
    if (s.spellcheck === null) s.el.removeAttribute('spellcheck');
    else s.el.setAttribute('spellcheck', s.spellcheck);
    s.el.style.outline = s.outline;
    s.el.style.outlineOffset = s.outlineOffset;
    dropEmptyStyle(s.el);
    try { var sel = window.getSelection(); if (sel) sel.removeAllRanges(); } catch (_) {}
    try { if (document.activeElement === s.el) s.el.blur(); } catch (_) {}
    postTextSession('end');
  }

  function applyTextFormat(prop, value) {
    var s = textSession;
    if (!s || TEXT_STYLE_PROPS.indexOf(prop) === -1 || typeof value !== 'string') return;
    var el = s.el;
    var styles = s.rec.styles;
    if (!styles[prop]) {
      styles[prop] = {
        value: el.style.getPropertyValue(prop),
        priority: el.style.getPropertyPriority(prop),
        computed: window.getComputedStyle(el).getPropertyValue(prop),
      };
    }
    el.style.setProperty(prop, value, 'important');
    try {
      window.parent.postMessage({
        type: 'swarmz:text_styled',
        target: textTargetInfo(s),
        property: prop,
        oldValue: styles[prop].computed,
        newValue: window.getComputedStyle(el).getPropertyValue(prop),
        text: el.textContent || '',
      }, '*');
    } catch (_) {}
    postTextSession('update');
  }

  function revertTextEdits() {
    endTextSession(false);
    Object.keys(textRecords).forEach(function(id) {
      var rec = textRecords[id];
      if (!rec || !rec.el || !rec.el.isConnected) return;
      if ((rec.el.textContent || '') !== rec.text) {
        try { restoreText(rec.snap); } catch (_) { rec.el.textContent = rec.text; }
      }
      Object.keys(rec.styles).forEach(function(p) {
        var o = rec.styles[p];
        if (o.value) rec.el.style.setProperty(p, o.value, o.priority);
        else rec.el.style.removeProperty(p);
      });
      dropEmptyStyle(rec.el);
    });
    textRecords = {};
  }

  function onTextPointerDown(e) {
    if (!textOnly()) return;
    textDownInSession = !!(textSession && textSession.el.contains(e.target));
    // The app never sees presses while the tool is on (no menus opening, no
    // drags starting). Inside the open session the default still places the
    // caret; anywhere else it is cancelled so focus stays put until click.
    e.stopPropagation();
    if (!textDownInSession && e.type === 'mousedown') e.preventDefault();
  }

  function onTextClick(e) {
    e.preventDefault();
    e.stopPropagation();
    if (textDownInSession) { textDownInSession = false; return; } // caret or a selection drag inside the session
    // A click synthesized by a key (Space or Enter on a button being edited)
    // has no pointer behind it: never end the session for one.
    if (e.detail === 0 && textSession) return;
    var t = textTargetAt(e.clientX, e.clientY);
    if (textSession && t === textSession.el) return;
    endTextSession(true);
    if (t) startTextSession(t, e.clientX, e.clientY);
  }

  function onTextKeyDown(e) {
    e.stopPropagation(); // typing never reaches the app's shortcuts
    if ((e.key === 'Enter' && !e.shiftKey) || e.key === 'Escape' || e.key === 'Tab') {
      e.preventDefault();
      endTextSession(true);
      return;
    }
    // Inside a button, Space presses the button instead of typing a space.
    if (e.key === ' ' && textSession.el.closest && textSession.el.closest('button')) {
      e.preventDefault();
      try { document.execCommand('insertText', false, ' '); } catch (_) {}
    }
  }

  function swallowTextEvent(e) {
    if (!textOnly()) return;
    if (e.type.indexOf('key') === 0 && !textSession) return;
    e.stopPropagation();
  }

  // -------------------------------------------------------------------------
  // Resolve the selectable element at a cursor position, then promote to the
  // outer visual block so hovering anywhere on a button selects the BUTTON,
  // not the inner <span>. Promotion rules:
  //   - SVG internals always promote to the root <svg>
  //   - Walk up while parent has the same bounding box as the child (tight
  //     wrapper — span exactly filling its h1, etc.)
  //   - Walk up if parent has a single element child whose bounding box
  //     equals parent's CONTENT area (parent has padding but no siblings —
  //     button with px-4 wrapping a span)
  // -------------------------------------------------------------------------
  function rectsEqual(a, b, tol) {
    return Math.abs(a.width - b.width) <= tol && Math.abs(a.height - b.height) <= tol;
  }

  function contentArea(parent, parentRect) {
    var s = window.getComputedStyle(parent);
    var l = parseFloat(s.paddingLeft) || 0;
    var r = parseFloat(s.paddingRight) || 0;
    var t = parseFloat(s.paddingTop) || 0;
    var b = parseFloat(s.paddingBottom) || 0;
    return { width: parentRect.width - l - r, height: parentRect.height - t - b };
  }

  function promoteToOuterTag(el) {
    if (!el) return null;
    // SVG internals → root <svg>
    if (isSvgInternal(el)) {
      var svg = el.ownerSVGElement;
      if (svg && isSelectable(svg)) return svg;
    }
    if (!isSelectable(el)) return null;

    // Media elements are atomic selection units. An <img>/<video> is almost
    // always sized to fill a same-bbox wrapper (w-full h-full inside an
    // aspect-ratio div), which would otherwise promote the selection up to the
    // wrapper — the user wants the media element itself, not its container.
    var tag = el.tagName ? el.tagName.toUpperCase() : '';
    if (tag === 'IMG' || tag === 'VIDEO' || tag === 'CANVAS' || tag === 'PICTURE') return el;

    var origSrc = getOwnSourceFile(el);

    var current = el;
    for (var safety = 0; safety < 12; safety++) {
      var parent = current.parentElement;
      if (!parent || !isSelectable(parent)) break;

      // Don't cross a component boundary during bbox promotion. If the
      // parent comes from a different source file it's part of a different
      // React component — keep promotion local to the current component.
      var parentSrc = getOwnSourceFile(parent);
      if (origSrc && parentSrc && parentSrc !== origSrc) break;

      var pr = parent.getBoundingClientRect();
      var cr = current.getBoundingClientRect();

      // Tight wrapper: parent has same bounds as child
      if (rectsEqual(pr, cr, 1)) { current = parent; continue; }

      // Padded single-child wrapper: child fills parent's content area
      var onlyChild = parent.children.length === 1 && parent.children[0] === current;
      if (onlyChild) {
        var ca = contentArea(parent, pr);
        if (Math.abs(ca.width - cr.width) <= 2 && Math.abs(ca.height - cr.height) <= 2) {
          current = parent; continue;
        }
      }
      break;
    }
    return current;
  }

  // Walk up the DOM until we find an ancestor whose own source file matches
  // the page file. If the hovered element is inside a library wrapper
  // (RevealLines, etc.), this jumps to the wrapping page-level element so
  // "Go to Code" lands in the file the user is actually editing.
  //
  // Subtlety: the null-source fallback that stops the walk only fires when
  // the ORIGINAL element also had no source. Without that guard, a click
  // inside a real section component (Footer.tsx, Header.tsx) walks past
  // the entire component and lands on the page's null-source root wrapper
  // — which is the whole page. With the guard, the walk falls through to
  // return the original element, and promoteToOuterTag handles the rest.
  function walkToPageFile(el) {
    var pageFile = getPageFile();
    if (!pageFile) return el;
    var origSrc = getOwnSourceFile(el);
    var current = el;
    for (var hops = 0; current && hops < 30; hops++, current = current.parentElement) {
      if (!isSelectable(current)) continue;
      var src = getOwnSourceFile(current);
      if (src === pageFile) return current;
      if (!src && !origSrc) return current;
    }
    return el;
  }

  function resolveAt(x, y) {
    var raw = document.elementFromPoint(x, y);
    if (!raw) return null;
    // If the topmost node is junk (head-injected, svg internal, etc.) walk up
    while (raw && !isSelectable(raw) && !isSvgInternal(raw)) {
      raw = raw.parentElement;
    }
    if (!raw) return null;
    if (isSvgInternal(raw)) {
      raw = raw.ownerSVGElement;
      if (!raw || !isSelectable(raw)) return null;
    }
    // Skip library-component internals: jump up to the nearest ancestor in
    // the page file the user is editing. VISUAL EDIT ONLY — it's a
    // "Go to Code" ergonomic. In comment mode it made everything inside a
    // section component (Header.tsx etc.) resolve to the whole <Header/>,
    // so individual components could never be picked; comments pin the
    // element the user is actually pointing at (still bbox-promoted below,
    // so a button's inner span picks the BUTTON).
    if (!(COMMENT_ON && !VISUAL_ON)) {
      raw = walkToPageFile(raw);
      if (!raw) return null;
    }
    return promoteToOuterTag(raw);
  }

  // -------------------------------------------------------------------------
  // Pointer + keyboard handlers
  // -------------------------------------------------------------------------
  function onPointerMove(e) {
    if (editing) return;
    if (textOnly()) {
      var t = textTargetAt(e.clientX, e.clientY);
      setTextHover(textSession && t === textSession.el ? null : t);
      return;
    }
    setHover(resolveAt(e.clientX, e.clientY));
  }

  function onPointerLeave() {
    setTextHover(null);
  }

  function onClick(e) {
    if (textOnly()) { onTextClick(e); return; }
    if (editing) {
      // Click inside the editing element places the caret; click away commits.
      if (editingEl && editingEl.contains(e.target)) return;
      e.preventDefault();
      e.stopPropagation();
      commitTextEdit();
      return;
    }
    e.preventDefault();
    e.stopPropagation();
    var el = resolveAt(e.clientX, e.clientY);
    if (!el) return;
    if (COMMENT_ON) {
      // Comment mode: report the picked element to the parent and stop — no
      // visual-edit selection outline / element_selected side-effects.
      // scroll + viewport let the editor turn the viewport-relative rect into
      // PAGE coordinates for the server-side snapshot's focused-area crop.
      var cr = el.getBoundingClientRect();
      window.parent.postMessage({
        type: 'swarmz:comment_element_selected',
        // selector = internal per-load id; cssPath is what gets persisted and
        // shown to people.
        selector: getElementId(el),
        cssPath: cssPath(el),
        rect: { top: cr.top, right: cr.right, bottom: cr.bottom, left: cr.left, width: cr.width, height: cr.height },
        scrollX: window.scrollX || 0,
        scrollY: window.scrollY || 0,
        viewport: { width: window.innerWidth, height: window.innerHeight },
        tagName: el.tagName,
      }, '*');
      return;
    }
    var multi = e.metaKey || e.ctrlKey;
    if (multi) {
      if (selected.has(el)) deselectElement(el); else selectElement(el);
    } else {
      clearSelection();
      selectElement(el);
    }
  }

  function onDblClick(e) {
    // Text tool: the native double-click (select a word) inside the session.
    if (textOnly()) { e.stopPropagation(); return; }
    var el = resolveAt(e.clientX, e.clientY);
    if (!el || !isTextEditable(el)) return;
    e.preventDefault();
    e.stopPropagation();
    enterTextEdit(el);
  }

  function onKeyDown(e) {
    if (editing) {
      if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); e.stopPropagation(); commitTextEdit(); }
      else if (e.key === 'Escape') { e.preventDefault(); e.stopPropagation(); cancelTextEdit(); }
      return;
    }
    if (textSession && textOnly()) { onTextKeyDown(e); return; }
    if (e.key === 'Escape') {
      clearSelection();
      setHover(null);
    }
  }

  function swallowHover(e) { e.stopPropagation(); }

  // Pointer/keyboard listeners are attached by enable() (see below), not at
  // boot — the script stays idle until the parent sends swarmz:visual_mode
  // { enabled: true }. swallowHover suppresses hover-driven side effects
  // (link prefetch, dropdown menus) while editing.

  // -------------------------------------------------------------------------
  // Scroll / resize — keep selected element rects + hover overlay in sync
  // -------------------------------------------------------------------------
  var rafPending = false;
  function reposition() {
    rafPending = false;
    selected.forEach(function(el) {
      if (!el.isConnected) return;
      var r = el.getBoundingClientRect();
      window.parent.postMessage({
        type: 'swarmz:element_position',
        selector: getElementId(el),
        rect: { top: r.top, right: r.right, bottom: r.bottom, left: r.left, width: r.width, height: r.height },
      }, '*');
    });
    if (hovered && hovered.isConnected) paintHover(hovered);
    if (textSession) postTextSession('update');
  }
  function scheduleReposition() {
    if (rafPending) return;
    rafPending = true;
    requestAnimationFrame(reposition);
  }
  // scroll/resize listeners are attached by enable() (see below).

  // -------------------------------------------------------------------------
  // enable / disable — idempotent. Selection listeners exist ONLY while
  // active, so a resident-but-disabled script never highlights anything.
  // active itself is DERIVED from the VISUAL_ON / COMMENT_ON intents via
  // syncActive() (called from both mode-message handlers), so it doesn't
  // matter which of the two messages the parent sends last.
  // -------------------------------------------------------------------------
  function syncActive() {
    var want = VISUAL_ON || COMMENT_ON || TEXT_ON;
    if (want && !active) enable();
    else if (!want && active) disable();
  }

  function enable() {
    if (active) return;
    active = true;
    if (!layer.parentElement) document.documentElement.appendChild(layer);
    document.addEventListener('pointermove', onPointerMove, true);
    document.addEventListener('pointerleave', onPointerLeave, true);
    document.addEventListener('mouseleave', onPointerLeave, true);
    document.addEventListener('click', onClick, true);
    document.addEventListener('dblclick', onDblClick, true);
    document.addEventListener('keydown', onKeyDown, true);
    document.addEventListener('mouseover', swallowHover, true);
    document.addEventListener('mouseenter', swallowHover, true);
    document.addEventListener('pointerdown', onTextPointerDown, true);
    document.addEventListener('mousedown', onTextPointerDown, true);
    document.addEventListener('pointerup', swallowTextEvent, true);
    document.addEventListener('mouseup', swallowTextEvent, true);
    document.addEventListener('keyup', swallowTextEvent, true);
    document.addEventListener('keypress', swallowTextEvent, true);
    document.addEventListener('scroll', scheduleReposition, true);
    window.addEventListener('resize', scheduleReposition);
    console.log('[swarmz-visual] enabled');
  }

  function disable() {
    if (!active) return;
    active = false;
    if (editing) cancelTextEdit();
    endTextSession(true);
    setTextHover(null);
    document.removeEventListener('pointerdown', onTextPointerDown, true);
    document.removeEventListener('mousedown', onTextPointerDown, true);
    document.removeEventListener('pointerup', swallowTextEvent, true);
    document.removeEventListener('mouseup', swallowTextEvent, true);
    document.removeEventListener('keyup', swallowTextEvent, true);
    document.removeEventListener('keypress', swallowTextEvent, true);
    document.removeEventListener('pointermove', onPointerMove, true);
    document.removeEventListener('pointerleave', onPointerLeave, true);
    document.removeEventListener('mouseleave', onPointerLeave, true);
    document.removeEventListener('click', onClick, true);
    document.removeEventListener('dblclick', onDblClick, true);
    document.removeEventListener('keydown', onKeyDown, true);
    document.removeEventListener('mouseover', swallowHover, true);
    document.removeEventListener('mouseenter', swallowHover, true);
    document.removeEventListener('scroll', scheduleReposition, true);
    window.removeEventListener('resize', scheduleReposition);
    clearSelection();
    setHover(null);
    if (layer.parentElement) layer.parentElement.removeChild(layer);
    console.log('[swarmz-visual] disabled');
  }

  // -------------------------------------------------------------------------
  // Page tree serialization — a clean "Layers" outline for the editor sidebar:
  // only selectable elements, with the selectable descendants of a
  // non-selectable wrapper hoisted up to the nearest selectable ancestor (so
  // every node is directly selectable and the tree stays clean). Each node
  // carries just its id, tag and children — the panel renders an icon + the
  // element type from the tag alone. Both the emitted-node count and the total
  // elements scanned are capped so a huge or wrapper-heavy document can't
  // freeze the walk. Assigning data-swarmz-id is layout-neutral, so the
  // getBoundingClientRect reads in isSelectable() stay cheap across the walk.
  // -------------------------------------------------------------------------
  var TREE_CAP = 2000;
  var TREE_SCAN_CAP = 20000;

  function makeTreeNode(el, children) {
    return {
      selector: getElementId(el),
      tagName: el.tagName ? el.tagName.toLowerCase() : '',
      childCount: children.length,
      children: children,
    };
  }

  function buildTreeChildren(parent, st) {
    var out = [];
    var kids = parent.children;
    if (!kids) return out;
    for (var i = 0; i < kids.length; i++) {
      if (st.truncated) break;
      var child = kids[i];
      if (child.nodeType !== 1 || !child.tagName) continue;
      if (isOwnUI(child)) continue;
      if (IGNORED.has(child.tagName.toUpperCase())) continue;
      if (isSvgInternal(child)) continue; // whole <svg> is one selectable unit

      // Bound total traversal — only selectable nodes are counted, so without
      // this a wrapper-heavy subtree could be walked in full.
      st.scanned++;
      if (st.scanned > TREE_SCAN_CAP) { st.truncated = true; break; }

      if (isSelectable(child)) {
        if (st.count >= TREE_CAP) { st.truncated = true; break; }
        st.count++;
        out.push(makeTreeNode(child, buildTreeChildren(child, st)));
      } else {
        // Non-selectable wrapper — hoist its selectable descendants up so the
        // tree stays clean but nothing addressable is hidden.
        var hoisted = buildTreeChildren(child, st);
        for (var h = 0; h < hoisted.length; h++) out.push(hoisted[h]);
      }
    }
    return out;
  }

  function buildPageTree() {
    var st = { count: 0, scanned: 0, truncated: false };
    var roots = document.body ? buildTreeChildren(document.body, st) : [];
    return { roots: roots, nodeCount: st.count, truncated: st.truncated };
  }

  // -------------------------------------------------------------------------
  // Parent → iframe commands
  // -------------------------------------------------------------------------
  window.__swarmzOriginalStyles = window.__swarmzOriginalStyles || {};

  function onMessage(e) {
    var data = e.data;
    if (!data || typeof data !== 'object') return;

    switch (data.type) {
      case 'swarmz:visual_mode': {
        setAccent(data.accent);
        VISUAL_ON = !!data.enabled;
        syncActive();
        break;
      }

      case 'swarmz:clear_selection': {
        clearSelection();
        break;
      }

      case 'swarmz:text_mode': {
        // Owned solely by this message, like visual_mode / comment_mode. The
        // reply tells the editor this copy of the script has the text tool.
        TEXT_ON = !!data.enabled;
        if (TEXT_ON) textPalette = null;
        else { endTextSession(true); setTextHover(null); }
        syncActive();
        try { window.parent.postMessage({ type: 'swarmz:text_mode_state', enabled: TEXT_ON }, '*'); } catch (_) {}
        break;
      }

      case 'swarmz:text_format': {
        applyTextFormat(data.property, data.value);
        break;
      }

      case 'swarmz:text_end': {
        endTextSession(true);
        break;
      }

      case 'swarmz:text_revert': {
        revertTextEdits();
        break;
      }

      case 'swarmz:text_forget': {
        endTextSession(false);
        textRecords = {};
        break;
      }

      case 'swarmz:comment_mode': {
        // Owned solely by this message — visual_mode never touches COMMENT_ON.
        // Reuses the visual-mode selection listeners; the click handler
        // branches on COMMENT_ON to emit swarmz:comment_element_selected
        // instead of running the visual-edit selection side-effects.
        COMMENT_ON = !!data.enabled;
        syncActive();
        break;
      }

      case 'swarmz:snapshot_element': {
        // Instant in-iframe capture: rasterize the element's context container
        // with snapdom, then crop the focused area around the element. Replies
        // with swarmz:element_snapshot { requestId, dataUrl | error }.
        var snapSel = data.selector;
        var snapReq = data.requestId;
        var snapEl = snapSel ? findById(snapSel) : null;
        // Per-load ids die on reload; the stable cssPath lets a request made
        // just before a reload (script auto-heal) still find its element.
        if (!snapEl && data.cssPath) {
          try { snapEl = document.querySelector(data.cssPath); } catch (_) {}
        }
        var snapReply = function(payload) {
          var msg = { type: 'swarmz:element_snapshot', selector: snapSel, requestId: snapReq };
          for (var k in payload) msg[k] = payload[k];
          try { window.parent.postMessage(msg, '*'); } catch (_) {}
        };
        if (!snapEl) { snapReply({ error: 'not_found' }); break; }
        loadSnapdom().then(function(sd) {
          var target = pickContextContainer(snapEl);
          // Never bake our own editor overlay into the shot.
          var hidLayer = target === document.body || target.contains(layer);
          if (hidLayer) layer.style.display = 'none';
          // Measure BOTH rects now, in the same frame the clone is taken —
          // measuring the element after the (async) rasterize let entrance
          // animations shift the page in between, skewing the crop offset.
          var tr = target.getBoundingClientRect();
          var er = snapEl.getBoundingClientRect();
          // 2x for retina thumbnails, dropping to 1x for big regions so the
          // raster stays fast and under canvas limits.
          var sdScale = (tr.width * tr.height > 3000000) ? 1 : 2;
          return sd.toCanvas(target, { scale: sdScale, fast: true }).then(function(canvas) {
            if (hidLayer) layer.style.display = '';
            if (target === snapEl) {
              // Element-only capture — the canvas IS the focused area.
              snapReply({ dataUrl: canvas.toDataURL('image/png') });
              return;
            }
            // The canvas maps 1:1 onto the container's border box; derive the
            // axis scales from the actual canvas size so rounding inside the
            // rasterizer can't skew the crop.
            var sx = canvas.width / tr.width;
            var sy = canvas.height / tr.height;
            var padX = Math.min(80, Math.max(24, er.width * 0.3));
            var padY = Math.min(64, Math.max(20, er.height * 0.3));
            var cw = Math.min(tr.width, Math.max(200, er.width + padX * 2));
            var ch = Math.min(tr.height, Math.max(120, er.height + padY * 2));
            var cx = (er.left + er.width / 2) - tr.left;
            var cy = (er.top + er.height / 2) - tr.top;
            var x = Math.max(0, Math.min(cx - cw / 2, tr.width - cw));
            var y = Math.max(0, Math.min(cy - ch / 2, tr.height - ch));
            var out = document.createElement('canvas');
            out.width = Math.max(1, Math.round(cw * sx));
            out.height = Math.max(1, Math.round(ch * sy));
            out.getContext('2d').drawImage(
              canvas,
              Math.round(x * sx), Math.round(y * sy), out.width, out.height,
              0, 0, out.width, out.height
            );
            snapReply({ dataUrl: out.toDataURL('image/png') });
          }, function(err) {
            if (hidLayer) layer.style.display = '';
            throw err;
          });
        }).catch(function(err) {
          snapReply({ error: String(err && err.message || err) });
        });
        break;
      }

      case 'swarmz:preview_change': {
        var id = data.selector, prop = data.property, val = data.value;
        if (!id || !prop) break;
        var el = findById(id);
        if (!el) break;
        // A new picture or its fit, set on a box that holds one picture,
        // lands on that picture (the box is what the person clicked).
        if ((prop === 'content' || prop === 'object-fit' || prop === 'object-position') && !/^(IMG|VIDEO)$/.test(el.tagName)) {
          var innerMedia = mediaFacts(el);
          if (innerMedia.count === 1 && innerMedia.first && /^(img|video|picture)$/.test(lowerTag(innerMedia.first))) {
            el = lowerTag(innerMedia.first) === 'picture' ? (innerMedia.first.querySelector('img') || innerMedia.first) : innerMedia.first;
            id = getElementId(el);
          }
        }
        var key = id + '::' + prop;
        if (prop === 'text-content') {
          if (!window.__swarmzOriginalStyles[key]) {
            window.__swarmzOriginalStyles[key] = { el: el, property: prop, original: el.textContent || '' };
          }
          el.textContent = val;
        } else {
          if (!window.__swarmzOriginalStyles[key]) {
            window.__swarmzOriginalStyles[key] = { el: el, property: prop, original: el.style.getPropertyValue(prop) };
          }
          el.style.setProperty(prop, val, 'important');
        }
        break;
      }

      case 'swarmz:get_section_snapshot': {
        var snapEl = data.selector ? findById(data.selector) : null;
        var snapReplyMsg = { type: 'swarmz:section_snapshot', requestId: data.requestId };
        if (!snapEl) {
          snapReplyMsg.ok = false;
          snapReplyMsg.error = 'not_found';
        } else {
          try {
            var snapData = sectionSnapshot(snapEl);
            for (var snapKey in snapData) snapReplyMsg[snapKey] = snapData[snapKey];
            snapReplyMsg.ok = true;
          } catch (snapErr) {
            snapReplyMsg.ok = false;
            snapReplyMsg.error = String(snapErr && snapErr.message || snapErr);
          }
        }
        window.parent.postMessage(snapReplyMsg, '*');
        break;
      }

      case 'swarmz:revert_changes': {
        Object.values(window.__swarmzOriginalStyles).forEach(function(entry) {
          if (!entry || !entry.el) return;
          if (entry.property === 'text-content') entry.el.textContent = entry.original;
          else entry.el.style.setProperty(entry.property, entry.original);
        });
        window.__swarmzOriginalStyles = {};
        break;
      }

      case 'swarmz:highlight_element': {
        var hId = data.selector;
        if (!hId) break;
        var hEl = findById(hId);
        if (!hEl) break;
        hEl.scrollIntoView({ behavior: 'smooth', block: 'center' });
        // Flash the hover overlay on this element
        paintHover(hEl);
        var prevBorder = hoverBox.style.border;
        hoverBox.style.border = '2px solid ' + ACCENT;
        setTimeout(function() {
          hoverBox.style.border = prevBorder;
          if (hovered !== hEl) paintHover(hovered);
        }, 1200);
        break;
      }

      case 'swarmz:select_parent': {
        var pId = data.selector;
        if (!pId) break;
        var pEl = findById(pId);
        if (!pEl) break;
        var parent = pEl.parentElement;
        while (parent && !isSelectable(parent)) parent = parent.parentElement;
        if (!parent) break;
        clearSelection();
        selectElement(parent);
        break;
      }

      case 'swarmz:select_child': {
        var scId = data.selector;
        if (!scId) break;
        var scEl = findById(scId);
        if (!scEl) break;
        var child = firstSelectableChild(scEl);
        if (!child) break;
        clearSelection();
        selectElement(child);
        break;
      }

      case 'swarmz:click_element': {
        var cId = data.selector;
        if (!cId) break;
        var cEl = findById(cId);
        if (!cEl || !isSelectable(cEl)) break;
        clearSelection();
        selectElement(cEl);
        break;
      }

      case 'swarmz:get_tree': {
        var built = buildPageTree();
        window.parent.postMessage({
          type: 'swarmz:tree_data',
          requestId: data.requestId,
          roots: built.roots,
          nodeCount: built.nodeCount,
          truncated: built.truncated,
        }, '*');
        break;
      }

      // Lightweight hover paint for tree-row hover — outlines the element
      // WITHOUT scrolling (unlike swarmz:highlight_element). Routes through
      // setHover so the hovered element is tracked (kept in sync by the
      // scroll/resize reposition) and a null selector clears it cleanly.
      case 'swarmz:hover_element': {
        setHover(data.selector ? findById(data.selector) : null);
        break;
      }

      case 'swarmz:annotation_hittest': {
        var pts = (data && data.points) || [];
        var hits = [];
        for (var ai = 0; ai < pts.length; ai++) {
          var p = pts[ai];
          var hel = (p && typeof p.x === 'number' && typeof p.y === 'number')
            ? resolveAt(p.x, p.y)
            : null;
          hits.push(hel ? buildElementData(hel) : null);
        }
        window.parent.postMessage({
          type: 'swarmz:annotation_hit',
          requestId: data.requestId,
          hits: hits,
        }, '*');
        break;
      }

      case 'swarmz:annotation_scroll': {
        // Draw-mode overlay captures wheel events; forward the delta so the
        // user can still scroll the preview while annotating. Report how far
        // the page ACTUALLY moved — the parent only wipes strokes on real
        // movement, so a swipe on a non-scrollable page (or past the scroll
        // limit) doesn't nuke the drawing. behavior:'instant' defeats CSS
        // scroll-behavior:smooth, which would make the readback see 0.
        var sx = window.scrollX, sy = window.scrollY;
        try { window.scrollBy({ left: data.dx || 0, top: data.dy || 0, behavior: 'instant' }); }
        catch (_) { try { window.scrollBy(data.dx || 0, data.dy || 0); } catch (_2) {} }
        var mdx = window.scrollX - sx, mdy = window.scrollY - sy;
        if (mdx || mdy) {
          try { window.parent.postMessage({ type: 'swarmz:annotation_scrolled', dx: mdx, dy: mdy }, '*'); } catch (_) {}
        }
        break;
      }
    }
  }
  window.addEventListener('message', onMessage);
  // Tell the parent the resident script is live. The parent replies with the
  // current mode (enable/disable) — this is also the reconcile signal after
  // any iframe reload (AI edit, key bump, page refresh).
  try { window.parent.postMessage({ type: 'swarmz:visual_ready', version: VERSION, features: ['text_mode', 'section_snapshot'] }, '*'); } catch (_) {}
})();