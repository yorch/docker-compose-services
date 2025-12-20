// Update the README file with the list of services in this repository.
// A service is a folder that contains a docker-compose.yml file.
// The README file is updated with a table of services and their descriptions.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const services = fs.readdirSync(__dirname);

const readme = fs.readFileSync(path.join(__dirname, 'README.md'), 'utf8');
const start = readme.indexOf('<!-- START SERVICES -->');
const end = readme.indexOf('<!-- END SERVICES -->');

const buildDockerComposeFilePath = (service: string): string =>
  path.join(__dirname, service, 'docker-compose.yml');

const buildReadmeFilePath = (service: string): string =>
  path.join(__dirname, service, 'README.md');

interface ServiceEntry {
  name: string;
  folder: string;
  description: string;
}

/**
 * Extract description from a service's README.md
 * The description is the first non-empty line after the title (# heading)
 */
const getServiceDescription = (service: string): string => {
  const readmePath = buildReadmeFilePath(service);
  if (!fs.existsSync(readmePath)) {
    return '';
  }

  try {
    const content = fs.readFileSync(readmePath, 'utf8');
    const lines = content.split('\n');

    // Find the first non-empty line after the title
    let foundTitle = false;
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        foundTitle = true;
        continue;
      }
      if (foundTitle && trimmed && !trimmed.startsWith('#')) {
        // Remove any markdown formatting and return
        return trimmed.replace(/\[([^\]]+)\]\([^)]+\)/g, '$1');
      }
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.warn(`Warning: Could not read README for ${service}: ${message}`);
  }

  return '';
};

const serviceEntries: ServiceEntry[] = services
  .filter((service: string) =>
    fs.existsSync(buildDockerComposeFilePath(service)),
  )
  .map((service: string) => {
    // Convert to title case
    const title = service
      .replace(/-/g, ' ')
      .replace(/\b\w/g, (char: string) => char.toUpperCase());

    const description = getServiceDescription(service);

    return { name: title, folder: service, description };
  });

// Build table
const tableHeader = '| Service | Description |\n| --- | --- |';
const tableRows = serviceEntries
  .map(
    ({ name, folder, description }) =>
      `| [${name}](./${folder}) | ${description} |`,
  )
  .join('\n');

const servicesTable = `\n${tableHeader}\n${tableRows}\n`;

const newReadme =
  readme.substring(0, start + 23) + servicesTable + readme.substring(end);

fs.writeFileSync(path.join(__dirname, 'README.md'), newReadme);

console.log(`README updated with ${serviceEntries.length} services`);
