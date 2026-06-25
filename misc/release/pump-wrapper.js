import { pump, PumpInvalidError, PumpUsageError } from './pump.js';

const [type] = process.argv.slice(2);

try {
  const nextVersion = pump(type);
  console.log(nextVersion);
} catch (error) {
  if (error instanceof PumpUsageError) {
    console.log(
      'Usage: ./pump-wrapper.js <minor|patch|premajor|preminor|prepatch|prerelease|release>',
    );
    process.exit(1);
  }

  if (error instanceof PumpInvalidError) {
    console.log(
      `Invalid pump: ${type}. Pumping from ${error.version} to ${error.newVersion} is not allowed.`,
    );
    process.exit(1);
  }

  throw error;
}
