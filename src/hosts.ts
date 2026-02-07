import type { Container, HostStatus, Project } from "./types"

function parsePort(raw: string): string {
  if (!raw) return ""
  // "0.0.0.0:5435->5432/tcp, [::]:5435->5432/tcp" → "5435:5432"
  const match = raw.match(/:(\d+)->(\d+)/)
  if (match) return `${match[1]}:${match[2]}`
  return ""
}

function parseDockerJson(stdout: string): Container[] {
  const containers: Container[] = []
  for (const line of stdout.trim().split("\n")) {
    if (!line.trim()) continue
    try {
      const raw = JSON.parse(line)
      const labels = raw.Labels || ""
      const projectMatch = typeof labels === "string" ? labels.match(/com\.docker\.compose\.project=([^,]+)/) : null
      const serviceMatch = typeof labels === "string" ? labels.match(/com\.docker\.compose\.service=([^,]+)/) : null

      containers.push({
        id: raw.ID || "",
        name: raw.Names || "",
        image: raw.Image || "",
        state: raw.State || "",
        status: raw.Status || "",
        health: raw.State === "running"
          ? (raw.Status?.includes("(healthy)") ? "healthy" : raw.Status?.includes("(unhealthy)") ? "unhealthy" : "none")
          : "stopped",
        ports: parsePort(raw.Ports || ""),
        project: projectMatch?.[1] || "",
        service: serviceMatch?.[1] || raw.Names || "",
        uptime: raw.RunningFor || "",
      })
    } catch {}
  }
  return containers
}

function groupByProject(containers: Container[]): Project[] {
  const groups = new Map<string, Container[]>()
  for (const c of containers) {
    const key = c.project || c.name
    if (!groups.has(key)) groups.set(key, [])
    groups.get(key)!.push(c)
  }
  return [...groups.entries()].map(([name, ctrs]) => {
    const running = ctrs.filter((c) => c.state === "running").length
    return {
      name,
      containers: ctrs,
      running,
      total: ctrs.length,
      allHealthy: ctrs.every((c) => c.health === "healthy" || c.health === "none"),
    }
  })
}

async function runCommand(args: string[], timeoutMs = 10000): Promise<string> {
  const proc = Bun.spawn(args, { stdout: "pipe", stderr: "pipe" })
  const timer = setTimeout(() => proc.kill(), timeoutMs)
  const stdout = await new Response(proc.stdout).text()
  const code = await proc.exited
  clearTimeout(timer)
  if (code !== 0) throw new Error(`Command failed with code ${code}`)
  return stdout
}

function buildHostStatus(name: string, host: string, containers: Container[]): HostStatus {
  const running = containers.filter((c) => c.state === "running").length
  return { name, host, containers, projects: groupByProject(containers), running, total: containers.length }
}

export async function fetchLocal(): Promise<HostStatus> {
  try {
    const stdout = await runCommand(["docker", "ps", "-a", "--format", "json"])
    return buildHostStatus("Local", "localhost", parseDockerJson(stdout))
  } catch (e) {
    return { name: "Local", host: "localhost", containers: [], projects: [], running: 0, total: 0, error: String(e) }
  }
}

export async function fetchRemote(host: string, sshKey: string): Promise<HostStatus> {
  const displayName = host.includes("51.81.202.134") ? "KAIA OVH" : host
  try {
    const stdout = await runCommand([
      "ssh", "-i", sshKey, "-o", "ConnectTimeout=5", "-o", "StrictHostKeyChecking=no",
      host, "docker", "ps", "-a", "--format", "json",
    ], 15000)
    return buildHostStatus(displayName, host, parseDockerJson(stdout))
  } catch (e) {
    return { name: displayName, host, containers: [], projects: [], running: 0, total: 0, error: String(e) }
  }
}
