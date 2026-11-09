#!/usr/bin/env node
// Records the animated preview of components in the booted simulator:
//   node scripts/record-preview.mjs                     every component
//   node scripts/record-preview.mjs Buttons/FooBar ...  only these
// The Showcase must be built first, which `make record` does.
import { execFileSync, spawn, spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { setTimeout as wait } from 'node:timers/promises';
import { fileURLToPath } from 'node:url';
import { loadCatalog, previewPlan } from './catalog-lib.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const bundleID = 'com.magnoscg.AwesomeSwiftUI.Showcase';
const startupMilliseconds = 2000;
const settleMilliseconds = 700;

function run(command, args) {
  return execFileSync(command, args, { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
}

function bootedSimulator() {
  const { devices } = JSON.parse(run('xcrun', ['simctl', 'list', 'devices', 'booted', '-j']));
  const device = Object.values(devices).flat()[0];
  if (!device) throw new Error('Boot a simulator first, ideally an iPhone 18 Pro on the newest iOS.');
  return device.udid;
}

function builtApp() {
  const settings = run('xcodebuild', [
    '-project', 'Showcase/Showcase.xcodeproj', '-scheme', 'Showcase',
    '-destination', 'generic/platform=iOS Simulator', '-showBuildSettings',
  ]);
  return `${settings.match(/ BUILT_PRODUCTS_DIR = (.+)/)[1]}/Showcase.app`;
}

async function record(component, udid) {
  const plan = previewPlan(component);
  const label = `${component.category}/${component.name}`;
  if (!plan.record) {
    console.log(`Skipped ${label}: its preview is recorded by hand.`);
    return true;
  }

  const movie = join(root, `.preview-${component.name}.mov`);
  run('xcrun', ['simctl', 'launch', '--terminate-running-process', udid, bundleID, '-showcaseComponent', component.id]);
  await wait(startupMilliseconds);

  const recorder = spawn('xcrun', ['simctl', 'io', udid, 'recordVideo', '--codec=h264', '--force', movie], { stdio: 'ignore' });
  const finished = new Promise((resolve) => recorder.once('exit', resolve));
  await wait(settleMilliseconds);
  const steps = plan.steps.flatMap((step) => ['--step', step]);
  const interaction = spawnSync('axe', ['batch', '--udid', udid, ...steps], { cwd: root, encoding: 'utf8' });
  await wait(settleMilliseconds);
  recorder.kill('SIGINT');
  await finished;

  try {
    if (interaction.status !== 0) {
      console.error(`Failed ${label}: ${(interaction.stderr || interaction.stdout).trim().split('\n').at(-1)}`);
      return false;
    }
    run('sh', ['scripts/make-preview.sh', movie, join(root, component.preview)]);
    console.log(`Recorded ${label}.`);
    return true;
  } finally {
    spawnSync('rm', ['-f', movie]);
  }
}

const { components, errors } = loadCatalog(root, { requirePreview: false });
if (errors.length > 0) {
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

const wanted = process.argv.slice(2);
const selected = wanted.length === 0
  ? components
  : components.filter((component) => wanted.includes(`${component.category}/${component.name}`));
if (selected.length !== Math.max(wanted.length, selected.length) || (wanted.length > 0 && selected.length !== wanted.length)) {
  console.error('Some components were not found in the catalog.');
  process.exit(2);
}

const udid = bootedSimulator();
run('xcrun', ['simctl', 'install', udid, builtApp()]);
run('xcrun', ['simctl', 'status_bar', udid, 'override', '--time', '9:41', '--batteryState', 'charged', '--batteryLevel', '100', '--wifiBars', '3', '--cellularBars', '4']);

let failures = 0;
for (const component of selected) {
  if (!(await record(component, udid))) failures += 1;
}
console.log(`${selected.length - failures} of ${selected.length} done.`);
process.exit(failures === 0 ? 0 : 1);
