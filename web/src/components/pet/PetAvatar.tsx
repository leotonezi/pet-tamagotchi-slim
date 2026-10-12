import { Bird, Cat, Dog, Fish, PawPrint, Rabbit, Rat, Squirrel, Turtle } from 'lucide-react'
import type { LucideIcon } from 'lucide-react'

// Species is free text, so match by keyword and fall back to a paw print.
const SPECIES_ICONS: [RegExp, LucideIcon][] = [
  [/dog|puppy|wolf|fox/i,            Dog],
  [/cat|kitten|lion|tiger/i,         Cat],
  [/rabbit|bunny|hare/i,             Rabbit],
  [/bird|parrot|owl|duck|chick/i,    Bird],
  [/fish|shark|whale|dolphin/i,      Fish],
  [/turtle|tortoise/i,               Turtle],
  [/squirrel|chipmunk/i,             Squirrel],
  [/rat|mouse|hamster/i,             Rat],
]

export function speciesIcon(species: string): LucideIcon {
  return SPECIES_ICONS.find(([re]) => re.test(species))?.[1] ?? PawPrint
}

export default function PetAvatar({ species, className = 'w-6 h-6' }: {
  species: string; className?: string
}) {
  const Icon = speciesIcon(species)
  return <Icon className={className} aria-label={species} />
}
