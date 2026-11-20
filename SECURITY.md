# Security policy — GrabCam v2.0

GrabCam v2.0 is a consent-based camera demonstration.

## Data handling
- Camera access starts only after the visitor reads the notice, checks both consent boxes, presses the start button, and grants the browser permission.
- The page visibly displays the active camera preview.
- Periodic capture and upload are described before consent and can be stopped at any time.
- No passwords, account credentials, gallery contents, or background location data are collected.
- Legacy IP and location collection endpoints return HTTP 410.

## Deployment
- Use HTTPS for remote camera access.
- Do not expose the `Photo/` directory as a public static directory. Configure the web server to deny direct access or store uploads outside the document root.
- Add administrator authentication before creating any photo browsing interface.
- Apply upload rate limits, retention limits, backups, and access logging.
- Keep the server bound to localhost for local demonstrations unless a properly secured HTTPS deployment is configured.

## Reporting
Report security issues privately to the repository maintainer. Do not upload real people's images or personal data into public issues.
