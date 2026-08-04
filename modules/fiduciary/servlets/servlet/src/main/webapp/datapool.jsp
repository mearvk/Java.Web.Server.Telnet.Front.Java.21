<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Datapool — FiduciaryServices™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">FiduciaryServices™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="architectures.jsp">Architectures</a></li>
        <li><a href="yield.jsp">Yield & Turn</a></li>
        <li><a href="records.jsp">Records</a></li>
        <li><a href="datapool.jsp" class="active">Datapool</a></li>
        <li><a href="documents.jsp">Documents</a></li>
        <li><a href="bright.jsp">Legal Bright</a></li>
        <li><a href="findings.jsp">AI Findings</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner">
    <span class="hero-tag">Public Domain Intelligence Sources</span>
    <h1>Fiduciary Datapool</h1>
    <p>Publicly available fiduciary data from government, regulatory, academic, and institutional sources accessible on standard HTTP/HTTPS ports.</p>
</div></section>

<section class="section"><div class="section-inner">
    <h2>Data Sources</h2>
    <div class="table-wrap"><table>
        <thead><tr><th>Source</th><th>URL</th><th>Data Available</th><th>License</th></tr></thead>
        <tbody>
        <tr><td><strong>SEC EDGAR</strong></td><td><code>sec.gov/cgi-bin/browse-edgar</code></td><td>Fund filings, 13F holdings, ADV forms, prospectuses</td><td>Public Domain</td></tr>
        <tr><td><strong>OECD Data</strong></td><td><code>data.oecd.org</code></td><td>Cross-border tax, pension statistics, financial indicators</td><td>Public Domain</td></tr>
        <tr><td><strong>World Bank Open Data</strong></td><td><code>data.worldbank.org</code></td><td>GDP, sovereign indicators, development metrics</td><td>CC-BY-4.0</td></tr>
        <tr><td><strong>Companies House UK</strong></td><td><code>find-and-update.company-information.service.gov.uk</code></td><td>Director records, fiduciary appointments, company filings</td><td>Open Government Licence</td></tr>
        <tr><td><strong>Court Databases</strong></td><td><code>PACER, BAILII, Caselaw Access Project</code></td><td>Breach of fiduciary duty case law, court opinions</td><td>Public Domain / Open Access</td></tr>
        <tr><td><strong>Federal Reserve FRED</strong></td><td><code>fred.stlouisfed.org</code></td><td>Yield curves, monetary policy, economic indicators</td><td>Public Domain</td></tr>
        <tr><td><strong>Bank of England</strong></td><td><code>bankofengland.co.uk/statistics</code></td><td>UK financial stability, prudential data, rates</td><td>Open Government Licence</td></tr>
        <tr><td><strong>ECB Statistical Warehouse</strong></td><td><code>sdw.ecb.europa.eu</code></td><td>Eurozone monetary policy, banking supervision data</td><td>Open Access</td></tr>
        <tr><td><strong>IMF Data</strong></td><td><code>data.imf.org</code></td><td>Sovereign fund governance, balance of payments, fiscal data</td><td>Public Domain</td></tr>
        <tr><td><strong>SSRN / NBER</strong></td><td><code>papers.ssrn.com / nber.org</code></td><td>Fiduciary law research, economic working papers</td><td>Open Access / Academic</td></tr>
        </tbody>
    </table></div>

    <h2 style="margin-top:2rem;">Access Protocol</h2>
    <div class="card">
        <p>All sources accessible via HTTPS (port 443). No authentication required for public data. Rate limits apply per source. The FiduciaryServices AI queries these sources for knowledge base updates and yield model calibration.</p>
        <p class="meta">Protocol: TCP/443 (TLS 1.3) • Method: HTTP GET • Format: JSON, CSV, XML, HTML • Dave Integration: dave_web.c headless Chrome for JS-rendered content</p>
    </div>
</div></section>

<footer class="footer"><div><span>© 2026 MEARVK LLC. FiduciaryServices™ — Light Blue Edition.</span></div></footer>
</body></html>
