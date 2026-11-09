#!/usr/bin/env node
// Records the animated preview of components in the booted simulator:
//   node scripts/record-preview.mjs                     every component
//   node scripts/record-preview.mjs Buttons/FooBar ...  only these
// The Showcase must be built first, which `make record` does.
import { execFileSync, spawn, spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { setTimeout as wait } from 'node:timers/promises';
import { fileURLToPath } from 'node:url';
import { loadCatalog, newestSimulator, previewPlan, simulatorSupports } from './catalog-lib.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const bundleID = 'com.magnoscg.AwesomeSwiftUI.Showcase';
const startupMilliseconds = 2000;
const settleMilliseconds = 700;

function run(command, args) {
  return execFileSync(command, args, { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
}

function bootedSimulator() {
  const { devices } = JSON.parse(run('xcrun', ['simctl', 'list', 'devices', 'booted', '-j']));
  const simulator = newestSimulator(devices);
  if (!simulator) throw new Error('Boot a simulator first, ideally an iPhone 18 Pro on the newest iOS.');
  return simulator;
}

function builtApp() {
  const settings = run('xcodebuild', [
    '-project', 'Showcase/Showcase.xcodeproj', '-scheme', 'Showcase',
    '-destination', 'generic/platform=iOS Simulator', '-showBuildSettings',
  ]);
  return `${settings.match(/ BUILT_PRODUCTS_DIR = (.+)/)[1]}/Showcase.app`;
}

async function record(component, { udid, version }) {
  const plan = previewPlan(component);
  const label = `${component.category}/${component.name}`;
  if (!plan.record) {
    console.log(`Skipped ${label}: its preview is recorded by hand.`);
    return true;
  }

  if (!simulatorSupports(version, component.minIOS)) {
    console.error(`Failed ${label}: it needs iOS ${component.minIOS} and the simulator runs iOS ${version.join('.')}.`);
    return false;
  }

  const directory = mkdtempSync(join(tmpdir(), 'awesome-swiftui-preview-'));
  const movie = join(directory, `${component.name}.mov`);
  run('xcrun', ['simctl', 'launch', '--terminate-running-process', udid, bundleID, '-showcaseComponent', component.id]);
  await wait(startupMilliseconds);

  const recorder = spawn('xcrun', ['simctl', 'io', udid, 'recordVideo', '--codec=h264', '--force', movie], { stdio: 'ignore' });
  const finished = new Promise((resolve) => recorder.once('exit', resolve));
  await wait(settleMilliseconds);
  const steps = plan.steps.flatMap((step) => ['--step', step]);
  const interaction = spawnSync('axe', ['batch', '--udid', udid, '--ax-cache', 'perStep', ...steps], { cwd: root, encoding: 'utf8' });
  await wait(settleMilliseconds);
  recorder.kill('SIGINT');
  const recorderStatus = await finished;

  try {
    if (recorderStatus !== 0) {
      console.error(`Failed ${label}: the recording ended with status ${recorderStatus}.`);
      return false;
    }
    if (interaction.status !== 0) {
      console.error(`Failed ${label}: ${(interaction.stderr || interaction.stdout).trim().split('\n').at(-1)}`);
      return false;
    }
    run('sh', ['scripts/make-preview.sh', movie, join(root, component.preview)]);
    console.log(`Recorded ${label}.`);
    return true;
  } finally {
    rmSync(directory, { recursive: true, force: true });
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
if (wanted.length > 0 && selected.length !== wanted.length) {
  console.error('Some components were not found in the catalog.');
  process.exit(2);
}

const simulator = bootedSimulator();
const { udid } = simulator;
run('xcrun', ['simctl', 'install', udid, builtApp()]);
run('xcrun', ['simctl', 'status_bar', udid, 'override', '--time', '9:41', '--batteryState', 'charged', '--batteryLevel', '100', '--wifiBars', '3', '--cellularBars', '4']);

let failures = 0;
for (const component of selected) {
  if (!(await record(component, simulator))) failures += 1;
}
console.log(`${selected.length - failures} of ${selected.length} done.`);
process.exit(failures === 0 ? 0 : 1);
