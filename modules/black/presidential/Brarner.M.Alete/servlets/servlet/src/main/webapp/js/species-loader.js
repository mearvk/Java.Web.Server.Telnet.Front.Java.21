/* species-loader.js — Dynamic expandable div loader from /api/species */

(function() {
    var API = 'api/species';

    function fetchJSON(params) {
        var url = API + '?' + Object.keys(params).map(function(k) {
            return encodeURIComponent(k) + '=' + encodeURIComponent(params[k]);
        }).join('&');
        return fetch(url).then(function(r) { return r.json(); });
    }

    function makeDiv(label, meta, depth, loadFn) {
        var wrap = document.createElement('div');
        wrap.style.cssText = 'border:1px solid #27272a;border-radius:' + Math.max(4, 8 - depth) + 'px;margin-bottom:' + (0.5 - depth * 0.05) + 'rem;overflow:hidden;cursor:pointer;transition:border-color 0.2s ease;';
        var pad = (0.85 - depth * 0.1);
        var fs = (0.9 - depth * 0.04);

        var header = document.createElement('div');
        header.style.cssText = 'padding:' + pad + 'rem ' + (pad + 0.15) + 'rem;font-size:' + fs + 'rem;font-weight:600;display:flex;align-items:center;gap:0.5rem;user-select:none;';
        header.innerHTML = '<span style="display:inline-block;font-size:' + (0.65 - depth * 0.05) + 'rem;transition:transform 0.2s ease;color:#60a5fa;">&#9654;</span>' +
            label + (meta ? '<span style="margin-left:auto;font-size:' + (fs - 0.15) + 'rem;font-weight:400;color:#71717a;">' + meta + '</span>' : '');

        var body = document.createElement('div');
        body.style.cssText = 'max-height:0;overflow:hidden;transition:max-height 0.3s ease,padding 0.3s ease;padding:0 ' + (pad + 0.15) + 'rem;font-size:' + (fs - 0.05) + 'rem;color:#a1a1aa;cursor:default;';
        body.onclick = function(e) { e.stopPropagation(); };

        var loaded = false;
        wrap.onclick = function(e) {
            e.stopPropagation();
            var icon = header.children[0];
            var open = body.style.maxHeight !== '0px' && body.style.maxHeight !== '';
            if (open) {
                body.style.maxHeight = '0px'; body.style.paddingBottom = '0';
                icon.style.transform = 'rotate(0deg)'; wrap.style.borderColor = '#27272a';
            } else {
                if (!loaded && loadFn) { loaded = true; loadFn(body); }
                body.style.maxHeight = body.scrollHeight + 'px'; body.style.paddingBottom = '1rem';
                icon.style.transform = 'rotate(90deg)'; wrap.style.borderColor = '#3b82f6';
                setTimeout(function() { body.style.maxHeight = body.scrollHeight + 'px'; }, 100);
            }
            setTimeout(function() { expandParents(body); }, 50);
        };
        wrap.onmouseenter = function() { if (wrap.style.borderColor !== 'rgb(59, 130, 246)') wrap.style.borderColor = '#3b82f6'; };
        wrap.onmouseleave = function() { if (body.style.maxHeight === '0px' || body.style.maxHeight === '') wrap.style.borderColor = '#27272a'; };

        wrap.appendChild(header);
        wrap.appendChild(body);
        return wrap;
    }

    function makeLeaf(label, sublabel, description, depth) {
        var wrap = document.createElement('div');
        wrap.style.cssText = 'border:1px solid #27272a;border-radius:4px;margin-bottom:0.3rem;overflow:hidden;cursor:pointer;transition:border-color 0.2s ease;';
        var header = document.createElement('div');
        header.style.cssText = 'padding:0.4rem 0.65rem;font-size:0.74rem;font-weight:500;display:flex;align-items:center;gap:0.4rem;user-select:none;';
        header.innerHTML = '<span style="display:inline-block;font-size:0.5rem;transition:transform 0.2s ease;color:#60a5fa;">&#9654;</span><em>' + label + '</em>' +
            (sublabel ? '<span style="margin-left:auto;font-size:0.65rem;font-weight:400;color:#71717a;">' + sublabel + '</span>' : '');
        var body = document.createElement('div');
        body.style.cssText = 'max-height:0;overflow:hidden;transition:max-height 0.3s ease,padding 0.3s ease;padding:0 0.65rem;font-size:0.72rem;color:#a1a1aa;cursor:default;';
        body.onclick = function(e) { e.stopPropagation(); };
        if (description) body.innerHTML = '<p>' + description + '</p>';
        else body.innerHTML = '<p style="color:#525252;">No description available.</p>';

        wrap.onclick = function(e) {
            e.stopPropagation();
            var icon = header.children[0];
            var open = body.style.maxHeight !== '0px' && body.style.maxHeight !== '';
            if (open) { body.style.maxHeight = '0px'; body.style.paddingBottom = '0'; icon.style.transform = 'rotate(0deg)'; wrap.style.borderColor = '#27272a'; }
            else { body.style.maxHeight = body.scrollHeight + 'px'; body.style.paddingBottom = '0.5rem'; icon.style.transform = 'rotate(90deg)'; wrap.style.borderColor = '#3b82f6'; }
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

    function loadingEl() {
        var d = document.createElement('p');
        d.textContent = 'Loading…';
        d.style.color = '#60a5fa';
        return d;
    }

    function loadClasses(container, kingdom) {
        var ldr = loadingEl(); container.appendChild(ldr);
        fetchJSON({ level: 'class', kingdom: kingdom }).then(function(data) {
            container.removeChild(ldr);
            if (!data.length) { container.innerHTML = '<p style="color:#525252;">No data found.</p>'; expandParents(container); return; }
            data.forEach(function(item) {
                var meta = (item.orders ? item.orders + ' orders · ' : '') + (item.families ? item.families + ' families' : '');
                container.appendChild(makeDiv(item.name, meta, 1, function(body) {
                    loadOrders(body, item.name);
                }));
            });
            expandParents(container);
        });
    }

    function loadOrders(container, className) {
        var ldr = loadingEl(); container.appendChild(ldr);
        fetchJSON({ level: 'order', 'class': className }).then(function(data) {
            container.removeChild(ldr);
            if (!data.length) { container.innerHTML = '<p style="color:#525252;">No orders found.</p>'; expandParents(container); return; }
            data.forEach(function(item) {
                var meta = item.families ? item.families + ' families' : '';
                container.appendChild(makeDiv(item.name, meta, 2, function(body) {
                    loadFamilies(body, item.name);
                }));
            });
            expandParents(container);
        });
    }

    function loadFamilies(container, orderName) {
        var ldr = loadingEl(); container.appendChild(ldr);
        fetchJSON({ level: 'family', order: orderName }).then(function(data) {
            container.removeChild(ldr);
            if (!data.length) { container.innerHTML = '<p style="color:#525252;">No families found.</p>'; expandParents(container); return; }
            data.forEach(function(item) {
                container.appendChild(makeDiv(item.name, '', 3, function(body) {
                    loadSpecies(body, item.name);
                }));
            });
            expandParents(container);
        });
    }

    function loadSpecies(container, familyName) {
        var ldr = loadingEl(); container.appendChild(ldr);
        fetchJSON({ level: 'species', family: familyName }).then(function(data) {
            container.removeChild(ldr);
            if (!data.length) { container.innerHTML = '<p style="color:#525252;">No species records yet.</p>'; expandParents(container); return; }
            data.forEach(function(item) {
                container.appendChild(makeLeaf(item.name, item.label, item.description, 4));
            });
            expandParents(container);
        });
    }

    /* Initialize — bind to each kingdom tab container */
    document.addEventListener('DOMContentLoaded', function() {
        var kingdoms = ['Animalia', 'Plantae', 'Fungi', 'Protista'];
        kingdoms.forEach(function(k) {
            var tab = document.getElementById('tab-' + k.toLowerCase());
            if (tab && !tab.dataset.loaded) {
                tab.dataset.loaded = '1';
                var target = tab.querySelector('.species-tree');
                if (target) loadClasses(target, k);
            }
        });

        /* Also load when tabs switch (lazy) */
        document.querySelectorAll('.tab[data-tab]').forEach(function(btn) {
            btn.addEventListener('click', function() {
                var k = btn.dataset.tab;
                var tab = document.getElementById('tab-' + k);
                if (tab && !tab.dataset.loaded) {
                    tab.dataset.loaded = '1';
                    var target = tab.querySelector('.species-tree');
                    if (target) loadClasses(target, k.charAt(0).toUpperCase() + k.slice(1));
                }
            });
        });
    });
})();
