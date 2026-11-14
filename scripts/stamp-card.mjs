#!/usr/bin/env node
// Writes into a social card the SHA-256 of the preview it was made from, so
// `make check` can tell when the preview changed and the card did not.
import { readFileSync, writeFileSync } from 'node:fs';
import { stampCard } from './catalog-lib.mjs';

const [preview, card] = process.argv.slice(2);
if (!preview || !card) {
  console.error('Usage: node scripts/stamp-card.mjs <preview.webp> <card.jpg>');
  process.exit(2);
}
writeFileSync(card, stampCard(readFileSync(card), readFileSync(preview)));
