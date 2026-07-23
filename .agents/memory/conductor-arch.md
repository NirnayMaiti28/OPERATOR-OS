---
name: CONDUCTOR architecture
description: Key decisions for the CONDUCTOR multi-agent orchestration system
---

## Core layout
- **Backend**: FastAPI (Python 3.11) at `artifacts/api-server/conductor/`
- **Frontend**: React+Vite at `artifacts/conductor-ui/` — terminal aesthetic, neon cyan on dark
- **DB**: SQLite at `artifacts/api-server/conductor.db` via aiosqlite
- **LLM**: Groq `llama-3.3-70b-versatile` for decomposition + ReasoningAgent

## API routes
All prefixed `/api/` — healthz, queries CRUD, agents, stats, stats/dashboard, benchmark CRUD.

## Agents (5)
retrieval (Wikipedia BM25), reasoning (Groq CoT), code (subprocess sandbox), data_analysis (pandas/numpy in-process exec), tool (6 external APIs)

## 6 Tool integrations
weather→OPENWEATHER_API_KEY, news→NEWSAPI_API_KEY, github→GITHUB_TOKEN, stock→ALPHA_VANTAGE_KEY, currency→EXCHANGERATE_API_KEY, wikipedia (free)

## OpenAPI codegen
Spec at `lib/api-spec/openapi.yaml`; generated hooks in `lib/api-client-react/src/generated/api.ts`

**Why:** User confirmed they want all 6 API integrations + web dashboard.
