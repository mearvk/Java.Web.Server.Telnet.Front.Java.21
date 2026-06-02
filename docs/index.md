/* Hide visible scrollbars on the sidebar but keep scrolling functional */
.sidebar {
/* keep overflow for scrolling but hide scrollbars visually */
overflow: auto;
-ms-overflow-style: none; /* IE and Edge */
scrollbar-width: none;    /* Firefox */
}

/* WebKit browsers (Chrome, Safari, Opera) */
.sidebar::-webkit-scrollbar {
display: none;
}

/* Remove the hard vertical divider and optionally add a soft shadow */
.sidebar {
border-right: none; /* remove the vertical line */
/* optional: subtle separation without a hard border */
box-shadow: 2px 0 6px rgba(11,37,69,0.04);
}

/* If you previously set height:100vh and want the sidebar to size with content on small screens,
keep sticky behavior but allow natural height to avoid double-scroll situations */
.sidebar {
position: sticky;
top: 0;
height: auto;
max-height: 100vh; /* prevents overflow beyond viewport while allowing internal scroll */
}

/* Optional: remove any visible vertical scrollbar on the main document while preserving scroll
(use with caution — this hides the browser scrollbar; users still scroll with wheel/keys) */
/*
html, body {
overflow-y: auto;
}
::-webkit-scrollbar {
width: 0px;
background: transparent;
}
*/
