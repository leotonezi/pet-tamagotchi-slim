import { Bath, Drumstick, Footprints, Gamepad2, Moon } from 'lucide-react'
import type { LucideIcon } from 'lucide-react'

export const ACTION_ICONS: Record<string, LucideIcon> = {
  feeding:  Drumstick,
  walking:  Footprints,
  bathing:  Bath,
  sleeping: Moon,
  playing:  Gamepad2,
}

export const ACTION_LABELS: Record<string, string> = {
  feeding:  'Feeding',
  walking:  'Walking',
  bathing:  'Bathing',
  sleeping: 'Sleeping',
  playing:  'Playing',
}
