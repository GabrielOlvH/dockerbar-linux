import { fetchLocal, fetchRemote } from "./hosts"
import type { DockerBarOutput } from "./types"

function parseArgs() {
  const args = process.argv.slice(2)
  return {
    local: args.includes("--local"),
    remote: args.includes("--remote"),
    all: args.includes("--all"),
    remoteHost: args.find((_, i, a) => a[i - 1] === "--host") || "root@51.81.202.134",
    sshKey: args.find((_, i, a) => a[i - 1] === "--key") || `${process.env.HOME}/.ssh/kaia_ovh`,
  }
}

async function main() {
  const { local, remote, all, remoteHost, sshKey } = parseArgs()

  const fetchLocal_ = all || local || (!local && !remote)
  const fetchRemote_ = all || remote || (!local && !remote)

  const promises: Promise<any>[] = []
  if (fetchLocal_) promises.push(fetchLocal())
  if (fetchRemote_) promises.push(fetchRemote(remoteHost, sshKey))

  const results = await Promise.allSettled(promises)

  const output: DockerBarOutput = {
    hosts: results.map((r) =>
      r.status === "fulfilled"
        ? r.value
        : { name: "Unknown", host: "", containers: [], running: 0, total: 0, error: String(r.reason) },
    ),
    timestamp: new Date().toISOString(),
  }

  console.log(JSON.stringify(output))
}

main()
