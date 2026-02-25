import Bonjour from 'bonjour-service'

let bonjour: any = null
let service: any = null

export function startMdnsBroadcast(port: number): void {
  bonjour = new Bonjour()
  service = bonjour.publish({
    name: 'Notes Sync',
    type: 'notes-sync',
    port,
    txt: {
      version: '1.0.0',
    },
  })
  console.log(`[mDNS] Broadcasting on port ${port}`)
}

export function stopMdnsBroadcast(): void {
  if (service) {
    service.stop()
    service = null
  }
  if (bonjour) {
    bonjour.destroy()
    bonjour = null
  }
  console.log('[mDNS] Stopped broadcasting')
}
