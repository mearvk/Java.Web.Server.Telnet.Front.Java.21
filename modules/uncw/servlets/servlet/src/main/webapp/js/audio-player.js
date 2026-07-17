/**
 * Audio Player — UNCW™
 * Detects audio file links and creates HTML5 audio players.
 */
(function() {
    var AUDIO_EXT = ['mp3','wav','ogg','flac','aac','m4a','opus','aiff','wma'];
    document.addEventListener('DOMContentLoaded', function() {
        var links = document.querySelectorAll('a[href]');
        links.forEach(function(link) {
            var href = link.href.toLowerCase();
            var ext = href.split('.').pop().split('?')[0];
            if (AUDIO_EXT.indexOf(ext) !== -1) {
                var container = document.createElement('div');
                container.className = 'audio-player';
                var nameSpan = document.createElement('span');
                nameSpan.className = 'audio-name';
                nameSpan.textContent = link.textContent || href.split('/').pop();
                var badge = document.createElement('span');
                badge.className = 'audio-badge';
                badge.textContent = ext.toUpperCase();
                var audio = document.createElement('audio');
                audio.controls = true;
                audio.preload = 'none';
                audio.src = link.href;
                container.appendChild(nameSpan);
                container.appendChild(audio);
                container.appendChild(badge);
                link.parentNode.insertBefore(container, link.nextSibling);
            }
        });
    });
})();

function playAudio(url) {
    var existing = document.getElementById('uncw-audio-player');
    if (existing) existing.remove();
    var audio = document.createElement('audio');
    audio.id = 'uncw-audio-player';
    audio.controls = true;
    audio.autoplay = true;
    audio.src = url;
    audio.style.position = 'fixed';
    audio.style.bottom = '1rem';
    audio.style.right = '1rem';
    audio.style.zIndex = '1000';
    document.body.appendChild(audio);
}
