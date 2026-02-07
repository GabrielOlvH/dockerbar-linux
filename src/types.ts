export interface Container {
  id: string
  name: string
  image: string
  state: string
  status: string
  health: string
  ports: string
  project: string
  service: string
  uptime: string
}

export interface Project {
  name: string
  containers: Container[]
  running: number
  total: number
  allHealthy: boolean
}

export interface HostStatus {
  name: string
  host: string
  containers: Container[]
  projects: Project[]
  running: number
  total: number
  error?: string
}

export interface DockerBarOutput {
  hosts: HostStatus[]
  timestamp: string
}
