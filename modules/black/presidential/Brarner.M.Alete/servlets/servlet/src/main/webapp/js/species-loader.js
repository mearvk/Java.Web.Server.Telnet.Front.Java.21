/* species-loader.js — Dynamic expandable div loader from /api/species */

(function() {
    'use strict';

    /* Resolve API path relative to current page location */
    var basePath = window.location.pathname.substring(0, window.location.pathname.lastIndexOf('/') + 1);
    var API = basePath + 'api/species';

    function fetchJSON(params) {
        var url = API + '?' + Object.keys(params).map(function(k) {
            return encodeURIComponent(k) + '=' + encodeURIComponent(params[k]);
        }).join('&');
        console.log('[species-loader] GET ' + url);
        return fetch(url).then(function(r) {
            if (!r.ok) throw new Error('HTTP ' + r.status);
            return r.json();
        }).then(function(data) {
            if (!Array.isArray(data)) throw new Error('Not an array');
            if (data.length > 0 && data[0].error) throw new Error(data[0].error);
            return data;
        }).catch(function(err) {
            console.error('[species-loader] fetch failed:', url, err);
            return null;
        });
    }

    function esc(s) {
        if (s == null) return '';
        var d = document.createElement('span');
        d.textContent = String(s);
        return d.innerHTML;
    }

    function makeDiv(label, meta, depth, loadFn) {
        var wrap = document.createElement('div');
        var radius = Math.max(4, 8 - depth);
        var mb = Math.max(0.3, 0.5 - depth * 0.05);
        wrap.style.cssText = 'border:1px solid #27272a;border-radius:' + radius + 'px;margin-bottom:' + mb + 'rem;overflow:hidden;cursor:pointer;transition:border-color 0.2s ease;';

        var pad = Math.max(0.5, 0.85 - depth * 0.1);
        var fs = Math.max(0.74, 0.9 - depth * 0.04);
        var iconFs = Math.max(0.5, 0.65 - depth * 0.05);

        var header = document.createElement('div');
        header.style.cssText = 'padding:' + pad + 'rem ' + (pad + 0.15) + 'rem;font-size:' + fs + 'rem;font-weight:600;display:flex;align-items:center;gap:0.5rem;user-select:none;';

        var icon = document.createElement('span');
        icon.style.cssText = 'display:inline-block;font-size:' + iconFs + 'rem;transition:transform 0.2s ease;color:#60a5fa;';
        icon.innerHTML = '&#9654;';
        header.appendChild(icon);

        var txt = document.createElement('span');
        txt.textContent = label || '(unnamed)';
        header.appendChild(txt);

        if (meta) {
            var metaSpan = document.createElement('span');
            metaSpan.style.cssText = 'margin-left:auto;font-size:' + Math.max(0.6, fs - 0.15) + 'rem;font-weight:400;color:#71717a;';
            metaSpan.textContent = meta;
            header.appendChild(metaSpan);
        }

        var body = document.createElement('div');
        body.style.cssText = 'max-height:0;overflow:hidden;transition:max-height 0.3s ease,padding 0.3s ease;padding:0 ' + (pad + 0.15) + 'rem;font-size:' + Math.max(0.72, fs - 0.05) + 'rem;color:#a1a1aa;cursor:default;';
        body.onclick = function(e) { e.stopPropagation(); };

        var loaded = false;
        wrap.onclick = function(e) {
            e.stopPropagation();
            var open = body.style.maxHeight !== '0px' && body.style.maxHeight !== '';
            if (open) {
                body.style.maxHeight = '0px';
                body.style.paddingBottom = '0';
                icon.style.transform = 'rotate(0deg)';
                wrap.style.borderColor = '#27272a';
            } else {
                if (!loaded && loadFn) {
                    loaded = true;
                    loadFn(body);
                }
                setTimeout(function() {
                    body.style.maxHeight = body.scrollHeight + 'px';
                    body.style.paddingBottom = '1rem';
                }, 10);
                icon.style.transform = 'rotate(90deg)';
                wrap.style.borderColor = '#3b82f6';
                setTimeout(function() { body.style.maxHeight = body.scrollHeight + 'px'; }, 150);
            }
            setTimeout(function() { expandParents(body); }, 60);
        };

        wrap.onmouseenter = function() {
            if (wrap.style.borderColor !== 'rgb(59, 130, 246)') wrap.style.borderColor = '#3b82f6';
        };
        wrap.onmouseleave = function() {
            if (body.style.maxHeight === '0px' || body.style.maxHeight === '') wrap.style.borderColor = '#27272a';
        };

        wrap.appendChild(header);
        wrap.appendChild(body);
        return wrap;
    }

    function makeLeaf(name, commonName, description) {
        var wrap = document.createElement('div');
        wrap.style.cssText = 'border:1px solid #27272a;border-radius:4px;margin-bottom:0.3rem;overflow:hidden;cursor:pointer;transition:border-color 0.2s ease;';

        var header = document.createElement('div');
        header.style.cssText = 'padding:0.4rem 0.65rem;font-size:0.74rem;font-weight:500;display:flex;align-items:center;gap:0.4rem;user-select:none;';

        var icon = document.createElement('span');
        icon.style.cssText = 'display:inline-block;font-size:0.5rem;transition:transform 0.2s ease;color:#60a5fa;';
        icon.innerHTML = '&#9654;';
        header.appendChild(icon);

        var em = document.createElement('em');
        em.textContent = name || '(unknown)';
        header.appendChild(em);

        if (commonName) {
            var lbl = document.createElement('span');
            lbl.style.cssText = 'margin-left:auto;font-size:0.65rem;font-weight:400;color:#71717a;';
            lbl.textContent = commonName;
            header.appendChild(lbl);
        }

        var body = document.createElement('div');
        body.style.cssText = 'max-height:0;overflow:hidden;transition:max-height 0.3s ease,padding 0.3s ease;padding:0 0.65rem;font-size:0.72rem;color:#a1a1aa;cursor:default;';
        body.onclick = function(e) { e.stopPropagation(); };

        var p = document.createElement('p');
        p.textContent = description || 'No description available.';
        if (!description) p.style.color = '#525252';
        body.appendChild(p);

        wrap.onclick = function(e) {
            e.stopPropagation();
            var open = body.style.maxHeight !== '0px' && body.style.maxHeight !== '';
            if (open) {
                body.style.maxHeight = '0px';
                body.style.paddingBottom = '0';
                icon.style.transform = 'rotate(0deg)';
                wrap.style.borderColor = '#27272a';
            } else {
                body.style.maxHeight = body.scrollHeight + 'px';
                body.style.paddingBottom = '0.5rem';
                icon.style.transform = 'rotate(90deg)';
                wrap.style.borderColor = '#3b82f6';
            }
            setTimeout(function() { expandParents(body); }, 50);
        };

        wrap.appendChild(header);
        wrap.appendChild(body);
        return wrap;
    }

    function expandParents(el) {
        var p = el.parentElement;
        while (p) {
            if (p.style && p.style.maxHeight && p.style.maxHeight !== '0px' && p.style.maxHeight !== '') {
                p.style.maxHeight = p.scrollHeight + 'px';
            }
            p = p.parentElement;
        }
    }

    function showMsg(container, text, color) {
        var p = document.createElement('p');
        p.textContent = text;
        p.style.color = color || '#525252';
        container.appendChild(p);
    }

    function loadClasses(container, kingdom) {
        showMsg(container, 'Loading…', '#60a5fa');
        fetchJSON({ level: 'class', kingdom: kingdom }).then(function(data) {
            container.innerHTML = '';
            if (!data || data.length === 0) {
                showMsg(container, 'No data found for ' + kingdom + '.', '#525252');
                return;
            }
            for (var i = 0; i < data.length; i++) {
                var item = data[i];
                var name = item.name || '(unnamed)';
                var parts = [];
                if (item.orders && item.orders > 0) parts.push(item.orders + ' orders');
                if (item.families && item.families > 0) parts.push(item.families + ' families');
                var meta = parts.join(' \u00B7 ');
                container.appendChild(makeDiv(name, meta, 1, (function(cls) {
                    return function(body) { loadOrders(body, cls); };
                })(name)));
            }
            expandParents(container);
        });
    }

    function loadOrders(container, className) {
        showMsg(container, 'Loading…', '#60a5fa');
        fetchJSON({ level: 'order', 'class': className }).then(function(data) {
            container.innerHTML = '';
            if (!data || data.length === 0) {
                showMsg(container, 'No orders found.', '#525252');
                expandParents(container);
                return;
            }
            for (var i = 0; i < data.length; i++) {
                var item = data[i];
                var name = item.name || '(unnamed)';
                var meta = (item.families && item.families > 0) ? item.families + ' families' : '';
                container.appendChild(makeDiv(name, meta, 2, (function(ord) {
                    return function(body) { loadFamilies(body, ord); };
                })(name)));
            }
            expandParents(container);
        });
    }

    function loadFamilies(container, orderName) {
        showMsg(container, 'Loading…', '#60a5fa');
        fetchJSON({ level: 'family', order: orderName }).then(function(data) {
            container.innerHTML = '';
            if (!data || data.length === 0) {
                showMsg(container, 'No families found.', '#525252');
                expandParents(container);
                return;
            }
            for (var i = 0; i < data.length; i++) {
                var item = data[i];
                var name = item.name || '(unnamed)';
                container.appendChild(makeDiv(name, '', 3, (function(fam) {
                    return function(body) { loadSpecies(body, fam); };
                })(name)));
            }
            expandParents(container);
        });
    }

    function loadSpecies(container, familyName) {
        showMsg(container, 'Loading…', '#60a5fa');
        fetchJSON({ level: 'species', family: familyName }).then(function(data) {
            container.innerHTML = '';
            if (!data || data.length === 0) {
                showMsg(container, 'No species records yet.', '#525252');
                expandParents(container);
                return;
            }
            for (var i = 0; i < data.length; i++) {
                var item = data[i];
                container.appendChild(makeLeaf(
                    item.name || '(unknown)',
                    item.label || null,
                    item.description || null
                ));
            }
            expandParents(container);
        });
    }

    /* Initialize on DOMContentLoaded */
    function init() {
        console.log('[species-loader] Initializing. API base: ' + API);

        /* Load the active tab immediately (animalia) */
        var activeTab = document.getElementById('tab-animalia');
        if (activeTab) {
            var tree = activeTab.querySelector('.species-tree');
            if (tree) {
                activeTab.setAttribute('data-loaded', '1');
                loadClasses(tree, 'Animalia');
            }
        }

        /* Lazy-load other tabs on click */
        var tabButtons = document.querySelectorAll('.tab[data-tab]');
        for (var i = 0; i < tabButtons.length; i++) {
            tabButtons[i].addEventListener('click', function() {
                var kingdom = this.getAttribute('data-tab');
                var tabPanel = document.getElementById('tab-' + kingdom);
                if (tabPanel && tabPanel.getAttribute('data-loaded') !== '1') {
                    tabPanel.setAttribute('data-loaded', '1');
                    var tree = tabPanel.querySelector('.species-tree');
                    if (tree) {
                        var kingdomName = kingdom.charAt(0).toUpperCase() + kingdom.slice(1);
                        loadClasses(tree, kingdomName);
                    }
                }
            });
        }
    }

    /* Ensure we run after the DOM is ready */
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
