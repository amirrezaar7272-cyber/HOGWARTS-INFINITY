# Hogwarts Infinity

An independent Persian-first fan-made wizarding-world portal.

## Current prototype
- Responsive RTL landing page and wizarding encyclopedia sections
- Academy course catalogue and browser-only demo enrollment
- Four house overview, searchable spell index, and interactive sorting quiz
- Live-class lobby in `classroom.html`: create a room, share its code, and join a Jitsi meeting
- GitHub Pages deployment workflow triggered by pushes to `main`

## Run locally
Open `index.html` in a modern browser. Open `classroom.html` for the classroom lobby. No build step is required.

## Classroom limitations
The classroom lobby uses Jitsi Meet rooms. Room creation and the class list are stored only in the current browser. This prototype does not provide authenticated teacher/student accounts, private room authorization, a central database, verified attendance, or a learning-management system. A room code is not a security boundary; do not use this prototype for confidential classes or share personal information. Production deployment requires a backend, authentication, database, and an appropriately configured video service.

## Important
This is an unofficial fan project and is not affiliated with or endorsed by Warner Bros., J.K. Rowling, or other rights holders. Names and references to the Wizarding World belong to their respective owners.

## Deployment
In repository Settings → Pages, select **GitHub Actions** as the build and deployment source. The workflow deploys the contents of the repository when changes are pushed to `main`.
