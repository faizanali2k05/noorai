# NoorAI Portfolio Site

Static landing page for the NoorAI hackathon project.

## Local preview

Open `index.html` directly in a browser, or run any static server:

```bash
npx serve .
```

## Deploy to Vercel

**Option A — same repo, subfolder:**

1. Push the repo to GitHub.
2. On vercel.com → "Add New Project" → Import the repo.
3. In project settings, set **Root Directory** to `portfolio`.
4. Framework preset: **Other** (or leave auto-detect). No build command needed.
5. Deploy.

**Option B — CLI, no GitHub:**

```bash
npm i -g vercel
cd portfolio
vercel
```

Follow the prompts. Subsequent deploys: `vercel --prod`.
