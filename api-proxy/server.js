import pkg from "pg"
import express from "express"

const { Pool } = pkg

const PORT = 5000
const API_KEY = process.env.API_KEY

if (!process.env.DATABASE_URL) {
  console.error("DATABASE_URL is required")
  process.exit(1)
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL.replace(
    "sslmode=require",
    "sslmode=no-verify",
  ),
  connectionTimeoutMillis: 10000,
  max: 5,
})

const app = express()
app.use(express.json({ limit: "1mb" }))

function auth(req, res, next) {
  if (!API_KEY || API_KEY === "null" || API_KEY === "") return next()
  const key = req.headers["x-api-key"]
  if (key !== API_KEY) return res.status(401).json({ error: "unauthorized" })
  next()
}

app.get("/health", async (_req, res) => {
  try {
    await pool.query("SELECT 1")
    res.json({ ok: true, status: "connected" })
  } catch (err) {
    res.status(500).json({ ok: false, status: "database unreachable", error: String(err).slice(0, 200) })
  }
})

app.post("/query", auth, async (req, res) => {
  const { text, params } = req.body
  if (typeof text !== "string") return res.status(400).json({ error: "text is required" })

  try {
    const { rows } = await pool.query(text, params ?? [])
    res.json({ rows })
  } catch (err) {
    res.status(500).json({ error: String(err).slice(0, 500) })
  }
})

process.on("SIGTERM", async () => {
  await pool.end()
  process.exit(0)
})

app.listen(PORT, "0.0.0.0", () => {
  console.log(`API proxy listening on 0.0.0.0:${PORT}`)
})
